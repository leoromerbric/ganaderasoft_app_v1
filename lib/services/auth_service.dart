import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import '../models/finca.dart';
import '../models/animal.dart';
import '../constants/app_constants.dart';
import 'database_service.dart';
import 'connectivity_service.dart';
import 'logging_service.dart';

class AuthService {
  static const Duration _httpTimeout = Duration(seconds: 10);

  // Hash password for secure storage
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  // Save token to storage
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  // Save original JWT token during offline mode
  Future<void> _saveOriginalToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.originalTokenKey, token);
  }

  // Get original JWT token
  Future<String?> _getOriginalToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.originalTokenKey);
  }

  // Clear original token
  Future<void> _clearOriginalToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.originalTokenKey);
  }

  // Check if current token is a temporary offline token
  bool _isOfflineToken(String? token) {
    return token != null && token.startsWith('offline_');
  }

  // Restore original JWT token when connectivity is restored
  Future<void> _restoreOriginalTokenIfNeeded() async {
    final currentToken = await getToken();
    
    // Only restore if current token is a temporary offline token
    if (_isOfflineToken(currentToken)) {
      final originalToken = await _getOriginalToken();
      if (originalToken != null) {
        LoggingService.info(
          'Restoring original JWT token after connectivity restoration',
          'AuthService',
        );
        await saveToken(originalToken);
        await _clearOriginalToken();
      }
    }
  }

  // Save user data to storage
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));
  }

  // Get stored user data
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(AppConstants.userKey);
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  // Clear stored credentials but preserve offline data for subsequent authentication
  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    await prefs.remove(AppConstants.originalTokenKey); // Also clear preserved original token
    // Note: Offline database data is preserved to allow offline authentication
    LoggingService.info(
      'Credentials cleared, offline data preserved for future authentication',
      'AuthService',
    );
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Check if offline authentication is available (user exists in cache)
  Future<bool> isOfflineAuthAvailable() async {
    try {
      // Check if user data exists in offline database
      final cachedUser = await DatabaseService.getUserOffline();
      if (cachedUser != null) {
        LoggingService.info(
          'Offline authentication available for user: ${cachedUser.email}',
          'AuthService',
        );
        return true;
      }

      // Fallback to SharedPreferences
      final localUser = await getUser();
      if (localUser != null) {
        LoggingService.info(
          'Offline authentication available via SharedPreferences for: ${localUser.email}',
          'AuthService',
        );
        return true;
      }

      LoggingService.debug(
        'No offline authentication data available',
        'AuthService',
      );
      return false;
    } catch (e) {
      LoggingService.error(
        'Error checking offline authentication availability',
        'AuthService',
        e,
      );
      return false;
    }
  }

  // Perform offline authentication using cached credentials
  Future<LoginResponse> authenticateOffline(
    String email,
    String password,
  ) async {
    try {
      LoggingService.info(
        'Attempting offline authentication for user: $email',
        'AuthService',
      );

      // Get cached user data
      User? cachedUser = await DatabaseService.getUserOffline();
      cachedUser ??= await getUser();

      if (cachedUser == null) {
        LoggingService.error(
          'No cached user data found for offline authentication',
          'AuthService',
        );
        throw Exception(
          'No hay datos de usuario disponibles para autenticación offline',
        );
      }

      // Verify email matches cached user
      if (cachedUser.email.toLowerCase() != email.toLowerCase()) {
        LoggingService.warning(
          'Email mismatch in offline authentication attempt',
          'AuthService',
        );
        throw Exception(
          'Los datos almacenados no coinciden con el usuario solicitado',
        );
      }

      // Verify password hash for offline authentication
      final storedPasswordHash = await DatabaseService.getUserPasswordHash(email);
      if (storedPasswordHash == null) {
        LoggingService.error(
          'No password hash found for offline authentication',
          'AuthService',
        );
        throw Exception(
          'No hay credenciales almacenadas para autenticación offline',
        );
      }

      final providedPasswordHash = _hashPassword(password);
      if (storedPasswordHash != providedPasswordHash) {
        LoggingService.warning(
          'Password verification failed in offline authentication',
          'AuthService',
        );
        throw Exception(
          'Credenciales incorrectas',
        );
      }

      LoggingService.info(
        'Password verified successfully for offline authentication: $email',
        'AuthService',
      );

      // For offline authentication, we'll restore the session with cached data
      // Preserve the original JWT token before switching to temporary offline token
      final currentToken = await getToken();
      if (currentToken != null && !_isOfflineToken(currentToken)) {
        LoggingService.info(
          'Preserving original JWT token during offline authentication',
          'AuthService',
        );
        await _saveOriginalToken(currentToken);
      }
      
      // Generate a temporary token to maintain session consistency
      final tempToken = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      await saveToken(tempToken);
      await saveUser(cachedUser);

      LoggingService.info(
        'Offline authentication successful for user: $email',
        'AuthService',
      );

      return LoginResponse(
        success: true,
        message: 'Autenticación offline exitosa',
        token: tempToken,
        user: cachedUser,
        tokenType: '',
      );
    } catch (e) {
      LoggingService.error(
        'Offline authentication failed for user: $email',
        'AuthService',
        e,
      );
      rethrow;
    }
  }

  // Login (with offline fallback)
  Future<LoginResponse> login(String email, String password) async {
    try {
      LoggingService.info('Attempting login for user: $email', 'AuthService');

      // First, check if we have connectivity
      final isConnected = await ConnectivityService.isConnected();

      if (!isConnected) {
        LoggingService.info(
          'No connectivity detected - attempting offline authentication',
          'AuthService',
        );
        return await authenticateOffline(email, password);
      }

      final response = await http
          .post(
            Uri.parse(AppConfig.loginUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));

        LoggingService.info('Login successful for user: $email', 'AuthService');

        // Hash the password for offline authentication
        final passwordHash = _hashPassword(password);

        // Save token and user data to SharedPreferences
        await saveToken(loginResponse.token);
        await saveUser(loginResponse.user);

        // Also save user data with password hash to offline database
        await DatabaseService.saveUserOffline(loginResponse.user, passwordHash: passwordHash);

        LoggingService.info(
          'User credentials saved for offline authentication: $email',
          'AuthService',
        );

        return loginResponse;
      } else {
        LoggingService.error(
          'Login failed with status: ${response.statusCode}',
          'AuthService',
        );
        throw Exception('Failed to login: ${response.body}');
      }
    } on TimeoutException catch (e) {
      LoggingService.warning(
        'Login timeout - attempting offline authentication',
        'AuthService',
      );
      return await authenticateOffline(email, password);
    } on SocketException catch (e) {
      LoggingService.warning(
        'Login socket error - attempting offline authentication',
        'AuthService',
      );
      return await authenticateOffline(email, password);
    } catch (e) {
      LoggingService.error('Login error for user: $email', 'AuthService', e);

      // If any network-related error, try offline authentication
      if (_isNetworkError(e)) {
        LoggingService.info(
          'Network error detected - attempting offline authentication',
          'AuthService',
        );
        try {
          return await authenticateOffline(email, password);
        } catch (offlineError) {
          LoggingService.error(
            'Both online and offline authentication failed',
            'AuthService',
            offlineError,
          );
          throw Exception(
            'No se pudo autenticar: sin conexión y sin datos offline válidos',
          );
        }
      }

      throw Exception('Network error: $e');
    }
  }

  // Logout
  Future<bool> logout() async {
    try {
      LoggingService.info('Attempting logout', 'AuthService');

      final token = await getToken();
      if (token != null) {
        final response = await http
            .post(
              Uri.parse(AppConfig.logoutUrl),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(_httpTimeout);

        if (response.statusCode == 200) {
          LoggingService.info('Logout successful', 'AuthService');
          await clearCredentials();
          return true;
        }
      }

      // Clear credentials even if request fails
      LoggingService.info(
        'Logout completed (clearing credentials)',
        'AuthService',
      );
      await clearCredentials();
      return true;
    } catch (e) {
      LoggingService.error('Logout error', 'AuthService', e);
      // Clear credentials even if request fails
      await clearCredentials();
      return true;
    }
  }

  // Get user profile (with offline support)
  Future<User> getProfile() async {
    LoggingService.debug('Getting user profile...', 'AuthService');

    try {
      // Check connectivity first
      final isConnected = await ConnectivityService.isConnected();

      if (!isConnected) {
        LoggingService.info(
          'No connectivity - using cached profile data',
          'AuthService',
        );
        return await _getOfflineProfile();
      }

      // Restore original token if we have connectivity and are using offline token
      await _restoreOriginalTokenIfNeeded();

      LoggingService.debug(
        'Connectivity available - fetching profile from server',
        'AuthService',
      );

      final token = await getToken();
      if (token == null) {
        LoggingService.error(
          'No token found for profile request',
          'AuthService',
        );
        throw Exception('No token found');
      }

      final response = await http
          .get(
            Uri.parse(AppConfig.profileUrl),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['data']['user']);

        LoggingService.info(
          'Profile fetched successfully from server',
          'AuthService',
        );

        // Save to offline storage
        await DatabaseService.saveUserOffline(user);

        return user;
      } else {
        LoggingService.error(
          'Profile request failed with status: ${response.statusCode}',
          'AuthService',
        );
        throw Exception('Failed to get profile: ${response.body}');
      }
    } on TimeoutException catch (e) {
      LoggingService.warning(
        'Profile request timeout - falling back to offline data',
        'AuthService',
      );
      return await _getOfflineProfile();
    } on SocketException catch (e) {
      LoggingService.warning(
        'Profile request socket error - falling back to offline data',
        'AuthService',
      );
      return await _getOfflineProfile();
    } catch (e) {
      LoggingService.error('Profile request error', 'AuthService', e);

      // If any network-related error, try offline data
      if (_isNetworkError(e)) {
        LoggingService.info(
          'Network error detected - trying offline profile data',
          'AuthService',
        );
        return await _getOfflineProfile();
      }

      throw Exception('Error getting profile: $e');
    }
  }

  // Get fincas list (with offline support)
  Future<FincasResponse> getFincas() async {
    LoggingService.debug('Getting fincas list...', 'AuthService');

    try {
      // Check connectivity first
      final isConnected = await ConnectivityService.isConnected();

      if (!isConnected) {
        LoggingService.info(
          'No connectivity - using cached fincas data',
          'AuthService',
        );
        return await _getOfflineFincas();
      }

      // Restore original token if we have connectivity and are using offline token
      await _restoreOriginalTokenIfNeeded();

      LoggingService.debug(
        'Connectivity available - fetching fincas from server',
        'AuthService',
      );

      final token = await getToken();
      if (token == null) {
        LoggingService.error(
          'No token found for fincas request',
          'AuthService',
        );
        throw Exception('No token found');
      }

      final response = await http
          .get(
            Uri.parse(AppConfig.fincasUrl),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final fincasResponse = FincasResponse.fromJson(
          jsonDecode(response.body),
        );

        LoggingService.info(
          'Fincas fetched successfully from server (${fincasResponse.fincas.length} items)',
          'AuthService',
        );

        // Save to offline storage
        await DatabaseService.saveFincasOffline(fincasResponse.fincas);

        return fincasResponse;
      } else {
        LoggingService.error(
          'Fincas request failed with status: ${response.statusCode}',
          'AuthService',
        );
        throw Exception('Failed to get fincas: ${response.body}');
      }
    } on TimeoutException catch (e) {
      LoggingService.warning(
        'Fincas request timeout - falling back to offline data',
        'AuthService',
      );
      return await _getOfflineFincas();
    } on SocketException catch (e) {
      LoggingService.warning(
        'Fincas request socket error - falling back to offline data',
        'AuthService',
      );
      return await _getOfflineFincas();
    } catch (e) {
      LoggingService.error('Fincas request error', 'AuthService', e);

      // If any network-related error, try offline data
      if (_isNetworkError(e)) {
        LoggingService.info(
          'Network error detected - trying offline fincas data',
          'AuthService',
        );
        return await _getOfflineFincas();
      }

      throw Exception('Error getting fincas: $e');
    }
  }

  /// Get offline profile data with fallbacks
  Future<User> _getOfflineProfile() async {
    // Try to get cached user data from database
    final cachedUser = await DatabaseService.getUserOffline();
    if (cachedUser != null) {
      LoggingService.info(
        'Using cached user data from database',
        'AuthService',
      );
      return cachedUser;
    }

    // Fallback to SharedPreferences
    final localUser = await getUser();
    if (localUser != null) {
      LoggingService.info(
        'Using user data from SharedPreferences',
        'AuthService',
      );
      return localUser;
    }

    LoggingService.error('No offline user data available', 'AuthService');
    throw Exception('No hay datos de usuario disponibles sin conexión');
  }

  /// Get offline fincas data
  Future<FincasResponse> _getOfflineFincas() async {
    try {
      final cachedFincas = await DatabaseService.getFincasOffline();
      LoggingService.info(
        'Using cached fincas data (${cachedFincas.length} items)',
        'AuthService',
      );

      return FincasResponse(
        success: true,
        message: 'Datos cargados desde caché local (sin conexión)',
        fincas: cachedFincas,
      );
    } catch (e) {
      LoggingService.error(
        'Error getting offline fincas data',
        'AuthService',
        e,
      );
      return FincasResponse(
        success: false,
        message: 'Error al cargar datos offline',
        fincas: [],
      );
    }
  }

  // Get animales list (with offline support)
  Future<AnimalesResponse> getAnimales({int? idRebano, int? idFinca}) async {
    LoggingService.debug('Getting animales list...', 'AuthService');

    try {
      // Check connectivity first
      final isConnected = await ConnectivityService.isConnected();

      if (!isConnected) {
        LoggingService.info(
          'No connectivity - using cached animales data',
          'AuthService',
        );
        return await _getOfflineAnimales(idRebano: idRebano, idFinca: idFinca);
      }

      // Restore original token if we have connectivity and are using offline token
      await _restoreOriginalTokenIfNeeded();

      LoggingService.debug(
        'Connectivity available - fetching animales from server',
        'AuthService',
      );

      final token = await getToken();
      if (token == null) {
        LoggingService.error(
          'No token found for animales request',
          'AuthService',
        );
        throw Exception('No token found');
      }

      String url = AppConfig.animalesUrl;
      Map<String, String> queryParams = {};
      
      if (idRebano != null) {
        queryParams['id_rebano'] = idRebano.toString();
      }
      if (idFinca != null) {
        queryParams['id_finca'] = idFinca.toString();
      }
      
      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final animalesResponse = AnimalesResponse.fromJson(
          jsonDecode(response.body),
        );

        LoggingService.info(
          'Animales fetched successfully from server (${animalesResponse.animales.length} items)',
          'AuthService',
        );

        // Save to offline storage
        await DatabaseService.saveAnimalesOffline(animalesResponse.animales);

        return animalesResponse;
      } else {
        LoggingService.error(
          'Animales request failed with status: ${response.statusCode}',
          'AuthService',
        );
        throw Exception('Failed to get animales: ${response.body}');
      }
    } on TimeoutException catch (e) {
      LoggingService.warning(
        'Animales request timeout - falling back to offline data',
        'AuthService',
      );
      return await _getOfflineAnimales(idRebano: idRebano, idFinca: idFinca);
    } on SocketException catch (e) {
      LoggingService.warning(
        'Animales request socket error - falling back to offline data',
        'AuthService',
      );
      return await _getOfflineAnimales(idRebano: idRebano, idFinca: idFinca);
    } catch (e) {
      LoggingService.error('Animales request error', 'AuthService', e);

      // If any network-related error, try offline data
      if (_isNetworkError(e)) {
        LoggingService.info(
          'Network error detected - trying offline animales data',
          'AuthService',
        );
        return await _getOfflineAnimales(idRebano: idRebano, idFinca: idFinca);
      }

      throw Exception('Error getting animales: $e');
    }
  }

  // Get rebanos list (with offline support)
  Future<RebanosResponse> getRebanos({int? idFinca}) async {
    LoggingService.debug('Getting rebanos list...', 'AuthService');

    try {
      // Check connectivity first
      final isConnected = await ConnectivityService.isConnected();

      if (!isConnected) {
        LoggingService.info(
          'No connectivity - using cached rebanos data',
          'AuthService',
        );
        return await _getOfflineRebanos(idFinca: idFinca);
      }

      // Restore original token if we have connectivity and are using offline token
      await _restoreOriginalTokenIfNeeded();

      LoggingService.debug(
        'Connectivity available - fetching rebanos from server',
        'AuthService',
      );

      final token = await getToken();
      if (token == null) {
        LoggingService.error(
          'No token found for rebanos request',
          'AuthService',
        );
        throw Exception('No token found');
      }

      String url = AppConfig.rebanosUrl;
      if (idFinca != null) {
        url += '?id_finca=$idFinca';
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final rebanosResponse = RebanosResponse.fromJson(
          jsonDecode(response.body),
        );

        LoggingService.info(
          'Rebanos fetched successfully from server (${rebanosResponse.rebanos.length} items)',
          'AuthService',
        );

        // Save to offline storage
        await DatabaseService.saveRebanosOffline(rebanosResponse.rebanos);

        return rebanosResponse;
      } else {
        LoggingService.error(
          'Rebanos request failed with status: ${response.statusCode}',
          'AuthService',
        );
        throw Exception('Failed to get rebanos: ${response.body}');
      }
    } on TimeoutException catch (e) {
      LoggingService.warning(
        'Rebanos request timeout - falling back to offline data',
        'AuthService',
      );
      return await _getOfflineRebanos(idFinca: idFinca);
    } on SocketException catch (e) {
      LoggingService.warning(
        'Rebanos request socket error - falling back to offline data',
        'AuthService',
      );
      return await _getOfflineRebanos(idFinca: idFinca);
    } catch (e) {
      LoggingService.error('Rebanos request error', 'AuthService', e);

      // If any network-related error, try offline data
      if (_isNetworkError(e)) {
        LoggingService.info(
          'Network error detected - trying offline rebanos data',
          'AuthService',
        );
        return await _getOfflineRebanos(idFinca: idFinca);
      }

      throw Exception('Error getting rebanos: $e');
    }
  }

  /// Get offline animales data
  Future<AnimalesResponse> _getOfflineAnimales({int? idRebano, int? idFinca}) async {
    try {
      final cachedAnimales = await DatabaseService.getAnimalesOffline(
        idRebano: idRebano,
        idFinca: idFinca,
      );
      LoggingService.info(
        'Using cached animales data (${cachedAnimales.length} items)',
        'AuthService',
      );

      return AnimalesResponse(
        success: true,
        message: 'Datos cargados desde caché local (sin conexión)',
        animales: cachedAnimales,
      );
    } catch (e) {
      LoggingService.error(
        'Error getting offline animales data',
        'AuthService',
        e,
      );
      return AnimalesResponse(
        success: false,
        message: 'Error al cargar datos offline',
        animales: [],
      );
    }
  }

  // Create Animal
  Future<Animal> createAnimal({
    required int idRebano,
    required String nombre,
    required String codigoAnimal,
    required String sexo,
    required String fechaNacimiento,
    required String procedencia,
    required int fkComposicionRaza,
    required int estadoId,
    required int etapaId,
  }) async {
    LoggingService.debug('Creating animal: $nombre', 'AuthService');

    try {
      // Restore original token if we have connectivity and are using offline token
      final isConnected = await ConnectivityService.isConnected();
      if (isConnected) {
        await _restoreOriginalTokenIfNeeded();
      }
      
      final token = await getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final requestData = {
        'id_Rebano': idRebano,
        'Nombre': nombre,
        'codigo_animal': codigoAnimal,
        'Sexo': sexo,
        'fecha_nacimiento': fechaNacimiento,
        'Procedencia': procedencia,
        'fk_composicion_raza': fkComposicionRaza,
        'estado_inicial': {
          'estado_id': estadoId,
          'fecha_ini': fechaNacimiento,
        },
        'etapa_inicial': {
          'etapa_id': etapaId,
          'fecha_ini': fechaNacimiento,
        },
      };

      final response = await http
          .post(
            Uri.parse(AppConfig.animalesUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestData),
          )
          .timeout(_httpTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        
        if (jsonData['success'] == true) {
          final animal = Animal.fromJson(jsonData['data']);
          
          LoggingService.info(
            'Animal created successfully: ${animal.nombre}',
            'AuthService',
          );

          // Save to offline storage
          await DatabaseService.saveAnimalesOffline([animal]);

          return animal;
        } else {
          throw Exception('Server returned error: ${jsonData['message']}');
        }
      } else {
        LoggingService.error(
          'Animal creation failed with status: ${response.statusCode}',
          'AuthService',
        );
        throw Exception('Failed to create animal: ${response.body}');
      }
    } on TimeoutException {
      LoggingService.warning(
        'Animal creation timeout - saving locally for later sync',
        'AuthService',
      );
      throw Exception('Timeout al crear animal. Se guardará localmente para sincronizar más tarde.');
    } on SocketException {
      LoggingService.warning(
        'Animal creation socket error - saving locally for later sync',
        'AuthService',
      );
      throw Exception('Sin conexión. El animal se guardará localmente para sincronizar más tarde.');
    } catch (e) {
      LoggingService.error('Animal creation error', 'AuthService', e);
      throw Exception('Error al crear animal: $e');
    }
  }

  // Create Rebano
  Future<Rebano> createRebano({
    required int idFinca,
    required String nombre,
  }) async {
    LoggingService.debug('Creating rebano: $nombre', 'AuthService');

    try {
      // Restore original token if we have connectivity and are using offline token
      final isConnected = await ConnectivityService.isConnected();
      if (isConnected) {
        await _restoreOriginalTokenIfNeeded();
      }
      
      final token = await getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final requestData = {
        'id_Finca': idFinca,
        'Nombre': nombre,
      };

      final response = await http
          .post(
            Uri.parse(AppConfig.rebanosUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestData),
          )
          .timeout(_httpTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        
        if (jsonData['success'] == true) {
          final rebano = Rebano.fromJson(jsonData['data']);
          
          LoggingService.info(
            'Rebano created successfully: ${rebano.nombre}',
            'AuthService',
          );

          // Save to offline storage
          await DatabaseService.saveRebanosOffline([rebano]);

          return rebano;
        } else {
          throw Exception('Server returned error: ${jsonData['message']}');
        }
      } else {
        LoggingService.error(
          'Rebano creation failed with status: ${response.statusCode}',
          'AuthService',
        );
        throw Exception('Failed to create rebano: ${response.body}');
      }
    } on TimeoutException {
      LoggingService.warning(
        'Rebano creation timeout - saving locally for later sync',
        'AuthService',
      );
      throw Exception('Timeout al crear rebaño. Se guardará localmente para sincronizar más tarde.');
    } on SocketException {
      LoggingService.warning(
        'Rebano creation socket error - saving locally for later sync',
        'AuthService',
      );
      throw Exception('Sin conexión. El rebaño se guardará localmente para sincronizar más tarde.');
    } catch (e) {
      LoggingService.error('Rebano creation error', 'AuthService', e);
      throw Exception('Error al crear rebaño: $e');
    }
  }

  /// Get offline rebanos data
  Future<RebanosResponse> _getOfflineRebanos({int? idFinca}) async {
    try {
      final cachedRebanos = await DatabaseService.getRebanosOffline(
        idFinca: idFinca,
      );
      LoggingService.info(
        'Using cached rebanos data (${cachedRebanos.length} items)',
        'AuthService',
      );

      return RebanosResponse(
        success: true,
        message: 'Datos cargados desde caché local (sin conexión)',
        rebanos: cachedRebanos,
      );
    } catch (e) {
      LoggingService.error(
        'Error getting offline rebanos data',
        'AuthService',
        e,
      );
      return RebanosResponse(
        success: false,
        message: 'Error al cargar datos offline',
        rebanos: [],
      );
    }
  }

  /// Check if an error is network-related
  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection timed out') ||
        errorString.contains('timeout') ||
        errorString.contains('socket');
  }
}
