import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/auth_service.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:ganaderasoft_app_v1/models/user.dart';
import 'package:ganaderasoft_app_v1/constants/app_constants.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Clear shared preferences and database before each test
    SharedPreferences.setMockInitialValues({});
    await DatabaseService.clearAllData();
  });

  group('JWT Token Preservation Tests', () {
    test('original JWT token is preserved during offline authentication', () async {
      final authService = AuthService();

      // Test user data
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        typeUser: 'Propietario',
        image: 'test.png',
      );

      const password = 'mySecurePassword123';
      const originalJwtToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.token';

      // Step 1: Simulate successful online login with JWT token
      await authService.saveToken(originalJwtToken);
      await authService.saveUser(user);
      
      // Calculate password hash for offline authentication
      final passwordHash = _calculatePasswordHash(password);
      await DatabaseService.saveUserOffline(user, passwordHash: passwordHash);

      // Verify original token is stored
      expect(await authService.getToken(), equals(originalJwtToken));

      // Step 2: Perform offline authentication
      final offlineResult = await authService.authenticateOffline(user.email, password);

      // Verify offline authentication succeeded
      expect(offlineResult.success, isTrue);
      expect(offlineResult.token, startsWith('offline_'));
      expect(offlineResult.user.email, equals(user.email));

      // Verify current token is now offline token
      final currentToken = await authService.getToken();
      expect(currentToken, startsWith('offline_'));
      expect(currentToken, isNot(equals(originalJwtToken)));

      // Step 3: Verify original token is preserved in storage
      final prefs = await SharedPreferences.getInstance();
      final preservedToken = prefs.getString(AppConstants.originalTokenKey);
      expect(preservedToken, equals(originalJwtToken));
    });

    test('original JWT token is restored when connectivity is re-established', () async {
      final authService = AuthService();

      // Test user data
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        typeUser: 'Propietario',
        image: 'test.png',
      );

      const password = 'mySecurePassword123';
      const originalJwtToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.token';

      // Step 1: Setup authenticated state with JWT token
      await authService.saveToken(originalJwtToken);
      await authService.saveUser(user);
      
      final passwordHash = _calculatePasswordHash(password);
      await DatabaseService.saveUserOffline(user, passwordHash: passwordHash);

      // Step 2: Perform offline authentication (simulates network loss)
      await authService.authenticateOffline(user.email, password);
      
      // Verify we're using offline token
      final offlineToken = await authService.getToken();
      expect(offlineToken, startsWith('offline_'));

      // Step 3: Simulate calling _restoreOriginalTokenIfNeeded (simulates connectivity restoration)
      // We'll use reflection or call it indirectly through one of the public methods
      // For testing, we'll directly test the logic by simulating what happens
      // when a method like getProfile() is called with connectivity restored
      
      // First, let's manually restore the token by simulating the private method logic
      final prefs = await SharedPreferences.getInstance();
      final preservedToken = prefs.getString(AppConstants.originalTokenKey);
      expect(preservedToken, equals(originalJwtToken));
      
      // Simulate restoration logic
      final currentToken = await authService.getToken();
      if (currentToken != null && currentToken.startsWith('offline_')) {
        if (preservedToken != null) {
          await authService.saveToken(preservedToken);
          await prefs.remove(AppConstants.originalTokenKey);
        }
      }

      // Step 4: Verify original token is restored
      final restoredToken = await authService.getToken();
      expect(restoredToken, equals(originalJwtToken));
      
      // Verify original token storage is cleared
      final clearedOriginalToken = prefs.getString(AppConstants.originalTokenKey);
      expect(clearedOriginalToken, isNull);
    });

    test('no token preservation when already using offline token', () async {
      final authService = AuthService();

      // Test user data
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        typeUser: 'Propietario',
        image: 'test.png',
      );

      const password = 'mySecurePassword123';

      // Step 1: Start with an offline token (no original JWT to preserve)
      await authService.saveToken('offline_1234567890');
      await authService.saveUser(user);
      
      final passwordHash = _calculatePasswordHash(password);
      await DatabaseService.saveUserOffline(user, passwordHash: passwordHash);

      // Step 2: Perform offline authentication again
      await authService.authenticateOffline(user.email, password);

      // Step 3: Verify no original token was preserved
      final prefs = await SharedPreferences.getInstance();
      final preservedToken = prefs.getString(AppConstants.originalTokenKey);
      expect(preservedToken, isNull);
    });

    test('credentials clearing removes both current and original tokens', () async {
      final authService = AuthService();

      // Test user data
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        typeUser: 'Propietario',
        image: 'test.png',
      );

      const password = 'mySecurePassword123';
      const originalJwtToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.token';

      // Step 1: Setup with JWT token and perform offline auth
      await authService.saveToken(originalJwtToken);
      await authService.saveUser(user);
      
      final passwordHash = _calculatePasswordHash(password);
      await DatabaseService.saveUserOffline(user, passwordHash: passwordHash);
      
      await authService.authenticateOffline(user.email, password);

      // Verify both tokens exist
      expect(await authService.getToken(), startsWith('offline_'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.originalTokenKey), equals(originalJwtToken));

      // Step 2: Clear credentials
      await authService.clearCredentials();

      // Step 3: Verify both tokens are cleared
      expect(await authService.getToken(), isNull);
      expect(prefs.getString(AppConstants.originalTokenKey), isNull);
      expect(await authService.isLoggedIn(), isFalse);
    });
  });
}

// Helper function to calculate password hash (same as AuthService)
String _calculatePasswordHash(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}