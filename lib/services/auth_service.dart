import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import '../models/finca.dart';
import '../constants/app_constants.dart';
import 'database_service.dart';
import 'connectivity_service.dart';
import 'logging_service.dart';

class AuthService {
  static const Duration _httpTimeout = Duration(seconds: 10);

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

  // Clear stored credentials and offline data
  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    // Clear offline database
    await DatabaseService.clearAllData();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Login
  Future<LoginResponse> login(String email, String password) async {
    try {
      LoggingService.info('Attempting login for user: $email', 'AuthService');
      
      final response = await http.post(
        Uri.parse(AppConfig.loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
        
        LoggingService.info('Login successful for user: $email', 'AuthService');
        
        // Save token and user data to SharedPreferences
        await saveToken(loginResponse.token);
        await saveUser(loginResponse.user);
        
        // Also save user data to offline database
        await DatabaseService.saveUserOffline(loginResponse.user);
        
        return loginResponse;
      } else {
        LoggingService.error('Login failed with status: ${response.statusCode}', 'AuthService');
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      LoggingService.error('Login error for user: $email', 'AuthService', e);
      throw Exception('Network error: $e');
    }
  }

  // Logout
  Future<bool> logout() async {
    try {
      LoggingService.info('Attempting logout', 'AuthService');
      
      final token = await getToken();
      if (token != null) {
        final response = await http.post(
          Uri.parse(AppConfig.logoutUrl),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(_httpTimeout);

        if (response.statusCode == 200) {
          LoggingService.info('Logout successful', 'AuthService');
          await clearCredentials();
          return true;
        }
      }
      
      // Clear credentials even if request fails
      LoggingService.info('Logout completed (clearing credentials)', 'AuthService');
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
        LoggingService.info('No connectivity - using cached profile data', 'AuthService');
        return await _getOfflineProfile();
      }

      LoggingService.debug('Connectivity available - fetching profile from server', 'AuthService');

      final token = await getToken();
      if (token == null) {
        LoggingService.error('No token found for profile request', 'AuthService');
        throw Exception('No token found');
      }

      final response = await http.get(
        Uri.parse(AppConfig.profileUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['data']['user']);
        
        LoggingService.info('Profile fetched successfully from server', 'AuthService');
        
        // Save to offline storage
        await DatabaseService.saveUserOffline(user);
        
        return user;
      } else {
        LoggingService.error('Profile request failed with status: ${response.statusCode}', 'AuthService');
        throw Exception('Failed to get profile: ${response.body}');
      }
    } on TimeoutException catch (e) {
      LoggingService.warning('Profile request timeout - falling back to offline data', 'AuthService');
      return await _getOfflineProfile();
    } on SocketException catch (e) {
      LoggingService.warning('Profile request socket error - falling back to offline data', 'AuthService');
      return await _getOfflineProfile();
    } catch (e) {
      LoggingService.error('Profile request error', 'AuthService', e);
      
      // If any network-related error, try offline data
      if (_isNetworkError(e)) {
        LoggingService.info('Network error detected - trying offline profile data', 'AuthService');
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
        LoggingService.info('No connectivity - using cached fincas data', 'AuthService');
        return await _getOfflineFincas();
      }

      LoggingService.debug('Connectivity available - fetching fincas from server', 'AuthService');

      final token = await getToken();
      if (token == null) {
        LoggingService.error('No token found for fincas request', 'AuthService');
        throw Exception('No token found');
      }

      final response = await http.get(
        Uri.parse(AppConfig.fincasUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final fincasResponse = FincasResponse.fromJson(jsonDecode(response.body));
        
        LoggingService.info('Fincas fetched successfully from server (${fincasResponse.fincas.length} items)', 'AuthService');
        
        // Save to offline storage
        await DatabaseService.saveFincasOffline(fincasResponse.fincas);
        
        return fincasResponse;
      } else {
        LoggingService.error('Fincas request failed with status: ${response.statusCode}', 'AuthService');
        throw Exception('Failed to get fincas: ${response.body}');
      }
    } on TimeoutException catch (e) {
      LoggingService.warning('Fincas request timeout - falling back to offline data', 'AuthService');
      return await _getOfflineFincas();
    } on SocketException catch (e) {
      LoggingService.warning('Fincas request socket error - falling back to offline data', 'AuthService');
      return await _getOfflineFincas();
    } catch (e) {
      LoggingService.error('Fincas request error', 'AuthService', e);
      
      // If any network-related error, try offline data
      if (_isNetworkError(e)) {
        LoggingService.info('Network error detected - trying offline fincas data', 'AuthService');
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
      LoggingService.info('Using cached user data from database', 'AuthService');
      return cachedUser;
    }
    
    // Fallback to SharedPreferences
    final localUser = await getUser();
    if (localUser != null) {
      LoggingService.info('Using user data from SharedPreferences', 'AuthService');
      return localUser;
    }
    
    LoggingService.error('No offline user data available', 'AuthService');
    throw Exception('No hay datos de usuario disponibles sin conexión');
  }

  /// Get offline fincas data
  Future<FincasResponse> _getOfflineFincas() async {
    try {
      final cachedFincas = await DatabaseService.getFincasOffline();
      LoggingService.info('Using cached fincas data (${cachedFincas.length} items)', 'AuthService');
      
      return FincasResponse(
        success: true,
        message: 'Datos cargados desde caché local (sin conexión)',
        fincas: cachedFincas,
      );
    } catch (e) {
      LoggingService.error('Error getting offline fincas data', 'AuthService', e);
      return FincasResponse(
        success: false,
        message: 'Error al cargar datos offline',
        fincas: [],
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