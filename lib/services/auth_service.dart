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
import '../models/farm_management_models.dart';
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
    await prefs.remove(
      AppConstants.originalTokenKey,
    ); // Also clear preserved original token
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
      final storedPasswordHash = await DatabaseService.getUserPasswordHash(
        email,
      );
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
        throw Exception('Credenciales incorrectas');
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
        await DatabaseService.saveUserOffline(
          loginResponse.user,
          passwordHash: passwordHash,
        );

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
    } on TimeoutException {
      LoggingService.warning(
        'Login timeout - attempting offline authentication',
        'AuthService',
      );
      return await authenticateOffline(email, password);
    } on SocketException {
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
    } on TimeoutException {
      LoggingService.warning(
        'Profile request timeout - falling back to offline data',
        'AuthService',
      );
      return await _getOfflineProfile();
    } on SocketException {
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
    } on TimeoutException {
      LoggingService.warning(
        'Fincas request timeout - falling back to offline data',
        'AuthService',
      );
      return await _getOfflineFincas();
    } on SocketException {
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
        url +=
            '?' +
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
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
    } on TimeoutException {
      LoggingService.warning(
        'Animales request timeout - falling back to offline data',
        'AuthService',
      );
      return await _getOfflineAnimales(idRebano: idRebano, idFinca: idFinca);
    } on SocketException {
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

  // Get animal detail with stages (with offline support)
  Future<AnimalDetailResponse> getAnimalDetail(int animalId) async {
    LoggingService.debug(
      'Getting animal detail for ID: $animalId',
      'AuthService',
    );

    try {
      // Check connectivity first
      final isConnected = await ConnectivityService.isConnected();

      if (!isConnected) {
        LoggingService.info(
          'No connectivity - using cached animal detail data',
          'AuthService',
        );
        return await _getOfflineAnimalDetail(animalId);
      }

      // Restore original token if we have connectivity and are using offline token
      await _restoreOriginalTokenIfNeeded();

      LoggingService.debug(
        'Connectivity available - fetching animal detail from server',
        'AuthService',
      );

      final token = await getToken();
      if (token == null) {
        LoggingService.error(
          'No token found for animal detail request',
          'AuthService',
        );
        throw Exception('No token found');
      }

      final url = '${AppConfig.baseUrl}/api/animales/$animalId';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        try {
          final responseBody = jsonDecode(response.body);
          final animalDetailResponse = AnimalDetailResponse.fromJson(
            responseBody,
          );

          LoggingService.info(
            'Animal detail retrieved successfully',
            'AuthService',
          );

          // Cache the animal detail data for offline use
          await DatabaseService.saveAnimalDetailOffline(
            animalDetailResponse.data,
          );

          return animalDetailResponse;
        } catch (parseError) {
          LoggingService.error(
            'Error parsing animal detail response: $parseError',
            'AuthService',
          );
          LoggingService.debug(
            'Response body that failed to parse: ${response.body}',
            'AuthService',
          );
          throw Exception('Error parsing animal detail response: $parseError');
        }
      } else {
        LoggingService.error(
          'Animal detail request failed with status: ${response.statusCode}',
          'AuthService',
        );
        throw Exception('Failed to get animal detail: ${response.body}');
      }
    } on TimeoutException {
      LoggingService.warning(
        'Animal detail request timeout - falling back to offline data',
        'AuthService',
      );
      return await _getOfflineAnimalDetail(animalId);
    } on SocketException {
      LoggingService.warning(
        'Animal detail request socket error - falling back to offline data',
        'AuthService',
      );
      return await _getOfflineAnimalDetail(animalId);
    } catch (e) {
      LoggingService.error('Animal detail request error', 'AuthService', e);

      // If any network-related error, try offline data
      if (_isNetworkError(e)) {
        LoggingService.info(
          'Network error detected - trying offline animal detail data',
          'AuthService',
        );
        return await _getOfflineAnimalDetail(animalId);
      }

      throw Exception('Error getting animal detail: $e');
    }
  }

  // Get animal detail offline
  Future<AnimalDetailResponse> _getOfflineAnimalDetail(int animalId) async {
    try {
      final cachedAnimalDetail = await DatabaseService.getAnimalDetailOffline(
        animalId,
      );

      if (cachedAnimalDetail == null) {
        throw Exception('No cached animal detail found for ID: $animalId');
      }

      LoggingService.info(
        'Using cached animal detail data for ID: $animalId',
        'AuthService',
      );

      return AnimalDetailResponse(
        success: true,
        message: 'Detalle de animal (datos locales)',
        data: cachedAnimalDetail,
      );
    } catch (e) {
      LoggingService.error(
        'Error getting offline animal detail',
        'AuthService',
        e,
      );
      throw Exception('No hay datos locales disponibles para el animal');
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
    } on TimeoutException {
      LoggingService.warning(
        'Rebanos request timeout - falling back to offline data',
        'AuthService',
      );
      return await _getOfflineRebanos(idFinca: idFinca);
    } on SocketException {
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
  Future<AnimalesResponse> _getOfflineAnimales({
    int? idRebano,
    int? idFinca,
  }) async {
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
        'estado_inicial': {'estado_id': estadoId, 'fecha_ini': fechaNacimiento},
        'etapa_inicial': {'etapa_id': etapaId, 'fecha_ini': fechaNacimiento},
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
      throw Exception(
        'Timeout al crear animal. Se guardará localmente para sincronizar más tarde.',
      );
    } on SocketException {
      LoggingService.warning(
        'Animal creation socket error - saving locally for later sync',
        'AuthService',
      );
      throw Exception(
        'Sin conexión. El animal se guardará localmente para sincronizar más tarde.',
      );
    } catch (e) {
      LoggingService.error('Animal creation error', 'AuthService', e);
      throw Exception('Error al crear animal: $e');
    }
  }

  // Update Animal
  Future<Animal> updateAnimal({
    required int idAnimal,
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
    LoggingService.debug('Updating animal: $nombre', 'AuthService');

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

      // Use current date for estado and etapa changes
      final currentDate = DateTime.now().toIso8601String();

      final requestData = {
        'id_Rebano': idRebano,
        'Nombre': nombre,
        'codigo_animal': codigoAnimal,
        'Sexo': sexo,
        'fecha_nacimiento': fechaNacimiento,
        'Procedencia': procedencia,
        'archivado': false,
        'fk_composicion_raza': fkComposicionRaza,
        'estado_inicial': {'estado_id': estadoId, 'fecha_ini': currentDate},
        'etapa_inicial': {'etapa_id': etapaId, 'fecha_ini': currentDate},
      };

      final response = await http
          .put(
            Uri.parse('${AppConfig.animalesUrl}/$idAnimal'),
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
            'Animal updated successfully: ${animal.nombre}',
            'AuthService',
          );

          return animal;
        } else {
          throw Exception('Server returned error: ${jsonData['message']}');
        }
      } else {
        LoggingService.error(
          'Animal update failed with status: ${response.statusCode}',
          'AuthService',
        );
        throw Exception('Failed to update animal: ${response.body}');
      }
    } on TimeoutException {
      LoggingService.warning('Animal update timeout', 'AuthService');
      throw Exception('Timeout al actualizar animal');
    } on SocketException {
      LoggingService.warning('Animal update socket error', 'AuthService');
      throw Exception('Sin conexión para actualizar animal');
    } catch (e) {
      LoggingService.error('Animal update error', 'AuthService', e);
      throw Exception('Error al actualizar animal: $e');
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

      final requestData = {'id_Finca': idFinca, 'Nombre': nombre};

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
      throw Exception(
        'Timeout al crear rebaño. Se guardará localmente para sincronizar más tarde.',
      );
    } on SocketException {
      LoggingService.warning(
        'Rebano creation socket error - saving locally for later sync',
        'AuthService',
      );
      throw Exception(
        'Sin conexión. El rebaño se guardará localmente para sincronizar más tarde.',
      );
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

  // Cambios Animal API methods
  Future<CambiosAnimalResponse> getCambiosAnimal({
    int? animalId,
    int? etapaId,
    String? etapaCambio,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    LoggingService.debug('Getting cambios animal list...', 'AuthService');

    try {
      final isConnected = await ConnectivityService.isConnected();

      if (!isConnected) {
        LoggingService.info(
          'No connectivity - using cached cambios animal data',
          'AuthService',
        );
        final cachedData = await DatabaseService.getCambiosAnimalOffline(
          animalId: animalId,
          etapaId: etapaId,
          etapaCambio: etapaCambio,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
        );
        return CambiosAnimalResponse(
          success: true,
          message: 'Datos cargados desde caché local (sin conexión)',
          data: cachedData,
        );
      }

      await _restoreOriginalTokenIfNeeded();

      final token = await getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      String url = AppConfig.cambiosAnimalUrl;
      Map<String, String> queryParams = {};

      if (animalId != null) queryParams['animal_id'] = animalId.toString();
      if (etapaId != null) queryParams['etapa_id'] = etapaId.toString();
      if (etapaCambio != null) queryParams['etapa_cambio'] = etapaCambio;
      if (fechaInicio != null) queryParams['fecha_inicio'] = fechaInicio;
      if (fechaFin != null) queryParams['fecha_fin'] = fechaFin;

      if (queryParams.isNotEmpty) {
        url +=
            '?' +
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
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
        final cambiosResponse = CambiosAnimalResponse.fromJson(
          jsonDecode(response.body),
        );
        LoggingService.info(
          'Cambios animal fetched successfully (${cambiosResponse.data.length} items)',
          'AuthService',
        );

        // Save to offline storage for future offline access
        if (cambiosResponse.data.isNotEmpty) {
          try {
            await DatabaseService.saveCambiosAnimalOffline(
              cambiosResponse.data,
            );
            LoggingService.info(
              'Cambios animal saved to local database',
              'AuthService',
            );
          } catch (e) {
            LoggingService.error(
              'Failed to save cambios animal to local database',
              'AuthService',
              e,
            );
            // Don't throw - the online fetch was successful
          }
        }

        return cambiosResponse;
      } else {
        throw Exception('Failed to get cambios animal: ${response.body}');
      }
    } catch (e) {
      LoggingService.error('Error getting cambios animal', 'AuthService', e);
      if (_isNetworkError(e)) {
        final cachedData = await DatabaseService.getCambiosAnimalOffline(
          animalId: animalId,
          etapaId: etapaId,
          etapaCambio: etapaCambio,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
        );
        return CambiosAnimalResponse(
          success: true,
          message: 'Datos cargados desde caché local (error de conexión)',
          data: cachedData,
        );
      }
      rethrow;
    }
  }

  Future<CambiosAnimal> createCambiosAnimal(CambiosAnimal cambios) async {
    LoggingService.debug('Creating cambios animal...', 'AuthService');

    final token = await getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http
        .post(
          Uri.parse(AppConfig.cambiosAnimalUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(cambios.toJson()),
        )
        .timeout(_httpTimeout);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final createdCambio = CambiosAnimal.fromJson(responseData['data']);

      LoggingService.info('Cambios animal created successfully', 'AuthService');
      return createdCambio;
    } else {
      LoggingService.error(
        'Failed to create cambios animal: ${response.body}',
        'AuthService',
      );
      throw Exception('Failed to create cambios animal: ${response.body}');
    }
  }

  // Lactancia API methods
  Future<LactanciaResponse> getLactancia({
    int? animalId,
    int? activa,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    LoggingService.debug('Getting lactancia list...', 'AuthService');

    try {
      final isConnected = await ConnectivityService.isConnected();

      if (!isConnected) {
        LoggingService.info(
          'No connectivity - using cached lactancia data',
          'AuthService',
        );
        final cachedData = await DatabaseService.getLactanciaOffline(
          animalId: animalId,
          activa: activa,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
        );
        return LactanciaResponse(
          success: true,
          message: 'Datos cargados desde caché local (sin conexión)',
          data: cachedData,
        );
      }

      await _restoreOriginalTokenIfNeeded();

      final token = await getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      String url = AppConfig.lactanciaUrl;
      Map<String, String> queryParams = {};

      if (animalId != null) queryParams['animal_id'] = animalId.toString();
      if (activa != null) queryParams['activa'] = activa.toString();
      if (fechaInicio != null) queryParams['fecha_inicio'] = fechaInicio;
      if (fechaFin != null) queryParams['fecha_fin'] = fechaFin;

      if (queryParams.isNotEmpty) {
        url +=
            '?' +
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
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
        final lactanciaResponse = LactanciaResponse.fromJson(
          jsonDecode(response.body),
        );
        LoggingService.info(
          'Lactancia fetched successfully (${lactanciaResponse.data.length} items)',
          'AuthService',
        );

        // Save to offline storage for future offline access
        if (lactanciaResponse.data.isNotEmpty) {
          try {
            await DatabaseService.saveLactanciaOffline(lactanciaResponse.data);
            LoggingService.info(
              'Lactancia saved to local database',
              'AuthService',
            );
          } catch (e) {
            LoggingService.error(
              'Failed to save lactancia to local database',
              'AuthService',
              e,
            );
            // Don't throw - the online fetch was successful
          }
        }

        return lactanciaResponse;
      } else {
        throw Exception('Failed to get lactancia: ${response.body}');
      }
    } catch (e) {
      LoggingService.error('Error getting lactancia', 'AuthService', e);
      if (_isNetworkError(e)) {
        final cachedData = await DatabaseService.getLactanciaOffline(
          animalId: animalId,
          activa: activa,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
        );
        return LactanciaResponse(
          success: true,
          message: 'Datos cargados desde caché local (error de conexión)',
          data: cachedData,
        );
      }
      rethrow;
    }
  }

  Future<Lactancia> createLactancia(Lactancia lactancia) async {
    LoggingService.debug('Creating lactancia...', 'AuthService');

    final token = await getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http
        .post(
          Uri.parse(AppConfig.lactanciaUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(lactancia.toJson()),
        )
        .timeout(_httpTimeout);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final createdLactancia = Lactancia.fromJson(responseData['data']);

      LoggingService.info('Lactancia created successfully', 'AuthService');
      return createdLactancia;
    } else {
      LoggingService.error(
        'Failed to create lactancia: ${response.body}',
        'AuthService',
      );
      throw Exception('Failed to create lactancia: ${response.body}');
    }
  }

  // Registro Lechero API methods
  Future<RegistroLecheroResponse> getRegistroLechero({
    int? lactanciaId,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    LoggingService.debug('Getting registro lechero list...', 'AuthService');

    try {
      final isConnected = await ConnectivityService.isConnected();

      if (!isConnected) {
        LoggingService.info(
          'No connectivity - using cached registro lechero data',
          'AuthService',
        );
        return RegistroLecheroResponse(
          success: true,
          message: 'Datos offline',
          data: [],
        );
      }

      await _restoreOriginalTokenIfNeeded();

      final token = await getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      String url = AppConfig.registroLecheroUrl;
      Map<String, String> queryParams = {};

      if (lactanciaId != null)
        queryParams['lactancia_id'] = lactanciaId.toString();
      if (fechaInicio != null) queryParams['fecha_inicio'] = fechaInicio;
      if (fechaFin != null) queryParams['fecha_fin'] = fechaFin;

      if (queryParams.isNotEmpty) {
        url +=
            '?' +
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
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
        final lecheroResponse = RegistroLecheroResponse.fromJson(
          jsonDecode(response.body),
        );
        LoggingService.info(
          'Registro lechero fetched successfully (${lecheroResponse.data.length} items)',
          'AuthService',
        );
        return lecheroResponse;
      } else {
        throw Exception('Failed to get registro lechero: ${response.body}');
      }
    } catch (e) {
      LoggingService.error('Error getting registro lechero', 'AuthService', e);
      if (_isNetworkError(e)) {
        return RegistroLecheroResponse(
          success: true,
          message: 'Datos offline',
          data: [],
        );
      }
      rethrow;
    }
  }

  Future<RegistroLechero> createRegistroLechero(
    RegistroLechero registro,
  ) async {
    LoggingService.debug('Creating registro lechero...', 'AuthService');

    final token = await getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http
        .post(
          Uri.parse(AppConfig.registroLecheroUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(registro.toJson()),
        )
        .timeout(_httpTimeout);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      LoggingService.info(
        'Registro lechero created successfully',
        'AuthService',
      );
      return RegistroLechero.fromJson(responseData['data']);
    } else {
      LoggingService.error(
        'Failed to create registro lechero: ${response.body}',
        'AuthService',
      );
      throw Exception('Failed to create registro lechero: ${response.body}');
    }
  }

  // Peso Corporal API methods
  Future<PesoCorporalResponse> getPesoCorporal({
    int? animalId,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    LoggingService.debug('Getting peso corporal list...', 'AuthService');

    try {
      final isConnected = await ConnectivityService.isConnected();

      if (!isConnected) {
        LoggingService.info(
          'No connectivity - using cached peso corporal data',
          'AuthService',
        );
        final cachedData = await DatabaseService.getPesoCorporalOffline(
          animalId: animalId,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
        );
        return PesoCorporalResponse(
          success: true,
          message: 'Datos cargados desde caché local (sin conexión)',
          data: cachedData,
        );
      }

      await _restoreOriginalTokenIfNeeded();

      final token = await getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      String url = AppConfig.pesoCorporalUrl;
      Map<String, String> queryParams = {};

      if (animalId != null) queryParams['animal_id'] = animalId.toString();
      if (fechaInicio != null) queryParams['fecha_inicio'] = fechaInicio;
      if (fechaFin != null) queryParams['fecha_fin'] = fechaFin;

      if (queryParams.isNotEmpty) {
        url +=
            '?' +
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
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
        final pesoResponse = PesoCorporalResponse.fromJson(
          jsonDecode(response.body),
        );
        LoggingService.info(
          'Peso corporal fetched successfully (${pesoResponse.data.length} items)',
          'AuthService',
        );

        // Save to offline storage for future offline access
        if (pesoResponse.data.isNotEmpty) {
          try {
            await DatabaseService.savePesoCorporalOffline(pesoResponse.data);
            LoggingService.info(
              'Peso corporal saved to local database',
              'AuthService',
            );
          } catch (e) {
            LoggingService.error(
              'Failed to save peso corporal to local database',
              'AuthService',
              e,
            );
            // Don't throw - the online fetch was successful
          }
        }

        return pesoResponse;
      } else {
        throw Exception('Failed to get peso corporal: ${response.body}');
      }
    } catch (e) {
      LoggingService.error('Error getting peso corporal', 'AuthService', e);
      if (_isNetworkError(e)) {
        final cachedData = await DatabaseService.getPesoCorporalOffline(
          animalId: animalId,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
        );
        return PesoCorporalResponse(
          success: true,
          message: 'Datos cargados desde caché local (error de conexión)',
          data: cachedData,
        );
      }
      rethrow;
    }
  }

  Future<PesoCorporal> createPesoCorporal(PesoCorporal peso) async {
    LoggingService.debug('Creating peso corporal...', 'AuthService');

    final token = await getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http
        .post(
          Uri.parse(AppConfig.pesoCorporalUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(peso.toJson()),
        )
        .timeout(_httpTimeout);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final createdPeso = PesoCorporal.fromJson(responseData['data']);

      LoggingService.info('Peso corporal created successfully', 'AuthService');
      return createdPeso;
    } else {
      LoggingService.error(
        'Failed to create peso corporal: ${response.body}',
        'AuthService',
      );
      throw Exception('Failed to create peso corporal: ${response.body}');
    }
  }

  // Medidas Corporales API methods
  Future<MedidasCorporalesResponse> getMedidasCorporales({
    int? animalId,
    int? etapaId,
  }) async {
    LoggingService.debug('Getting medidas corporales list...', 'AuthService');

    try {
      final isConnected = await ConnectivityService.isConnected();

      if (!isConnected) {
        LoggingService.info(
          'No connectivity - using cached medidas corporales data',
          'AuthService',
        );
        return MedidasCorporalesResponse(
          success: true,
          message: 'Datos offline',
          data: [],
        );
      }

      await _restoreOriginalTokenIfNeeded();

      final token = await getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      String url = AppConfig.medidasCorporalesUrl;
      Map<String, String> queryParams = {};

      if (animalId != null) queryParams['animal_id'] = animalId.toString();
      if (etapaId != null) queryParams['etapa_id'] = etapaId.toString();

      if (queryParams.isNotEmpty) {
        url +=
            '?' +
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
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
        final medidasResponse = MedidasCorporalesResponse.fromJson(
          jsonDecode(response.body),
        );
        LoggingService.info(
          'Medidas corporales fetched successfully (${medidasResponse.data.length} items)',
          'AuthService',
        );
        return medidasResponse;
      } else {
        throw Exception('Failed to get medidas corporales: ${response.body}');
      }
    } catch (e) {
      LoggingService.error(
        'Error getting medidas corporales',
        'AuthService',
        e,
      );
      if (_isNetworkError(e)) {
        return MedidasCorporalesResponse(
          success: true,
          message: 'Datos offline',
          data: [],
        );
      }
      rethrow;
    }
  }

  Future<MedidasCorporales> createMedidasCorporales(
    MedidasCorporales medidas,
  ) async {
    LoggingService.debug('Creating medidas corporales...', 'AuthService');

    final token = await getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http
        .post(
          Uri.parse(AppConfig.medidasCorporalesUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(medidas.toJson()),
        )
        .timeout(_httpTimeout);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      LoggingService.info(
        'Medidas corporales created successfully',
        'AuthService',
      );
      return MedidasCorporales.fromJson(responseData['data']);
    } else {
      LoggingService.error(
        'Failed to create medidas corporales: ${response.body}',
        'AuthService',
      );
      throw Exception('Failed to create medidas corporales: ${response.body}');
    }
  }

  // Personal Finca API methods
  Future<PersonalFincaResponse> getPersonalFinca({int? idFinca}) async {
    LoggingService.debug('Getting personal finca list...', 'AuthService');

    try {
      final isConnected = await ConnectivityService.isConnected();

      if (!isConnected) {
        LoggingService.info(
          'No connectivity - using cached personal finca data',
          'AuthService',
        );
        final cachedData = await DatabaseService.getPersonalFincaOffline(
          idFinca: idFinca,
        );
        return PersonalFincaResponse(
          success: true,
          message: 'Datos cargados desde caché local (sin conexión)',
          data: cachedData,
        );
      }

      await _restoreOriginalTokenIfNeeded();

      final token = await getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      String url = AppConfig.personalFincaUrl;
      Map<String, String> queryParams = {};

      if (idFinca != null) queryParams['id_finca'] = idFinca.toString();

      if (queryParams.isNotEmpty) {
        url +=
            '?' +
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
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
        final personalResponse = PersonalFincaResponse.fromJson(
          jsonDecode(response.body),
        );
        LoggingService.info(
          'Personal finca fetched successfully (${personalResponse.data.length} items)',
          'AuthService',
        );

        // Save to offline storage for future offline access
        if (personalResponse.data.isNotEmpty) {
          try {
            await DatabaseService.savePersonalFincaOffline(
              personalResponse.data,
            );
            LoggingService.info(
              'Personal finca saved to local database',
              'AuthService',
            );
          } catch (e) {
            LoggingService.error(
              'Failed to save personal finca to local database',
              'AuthService',
              e,
            );
            // Don't throw - the online fetch was successful
          }
        }

        return personalResponse;
      } else {
        throw Exception('Failed to get personal finca: ${response.body}');
      }
    } catch (e) {
      LoggingService.error('Error getting personal finca', 'AuthService', e);
      if (_isNetworkError(e)) {
        final cachedData = await DatabaseService.getPersonalFincaOffline(
          idFinca: idFinca,
        );
        return PersonalFincaResponse(
          success: true,
          message: 'Datos cargados desde caché local (error de conexión)',
          data: cachedData,
        );
      }
      rethrow;
    }
  }

  Future<PersonalFinca> createPersonalFinca(PersonalFinca personal) async {
    LoggingService.debug('Creating personal finca...', 'AuthService');

    final token = await getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http
        .post(
          Uri.parse(AppConfig.personalFincaUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(personal.toJson()),
        )
        .timeout(_httpTimeout);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final createdPersonal = PersonalFinca.fromJson(responseData['data']);

      LoggingService.info('Personal finca created successfully', 'AuthService');
      return createdPersonal;
    } else {
      LoggingService.error(
        'Failed to create personal finca: ${response.body}',
        'AuthService',
      );
      throw Exception('Failed to create personal finca: ${response.body}');
    }
  }

  // Update Personal Finca
  Future<PersonalFinca> updatePersonalFinca(PersonalFinca personal) async {
    LoggingService.debug('Updating personal finca...', 'AuthService');

    final token = await getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http
        .put(
          Uri.parse('${AppConfig.personalFincaUrl}/${personal.idTecnico}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(personal.toJson()),
        )
        .timeout(_httpTimeout);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final updatedPersonal = PersonalFinca.fromJson(responseData['data']);

      // Update local database for offline access
      try {
        await DatabaseService.savePersonalFincaOffline([updatedPersonal]);
        LoggingService.info(
          'Personal finca updated in local database',
          'AuthService',
        );
      } catch (e) {
        LoggingService.error(
          'Failed to update personal finca in local database',
          'AuthService',
          e,
        );
        // Don't throw - the online update was successful
      }

      LoggingService.info('Personal finca updated successfully', 'AuthService');
      return updatedPersonal;
    } else {
      LoggingService.error(
        'Failed to update personal finca: ${response.body}',
        'AuthService',
      );
      throw Exception('Failed to update personal finca: ${response.body}');
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
