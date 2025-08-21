import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/auth_service.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:ganaderasoft_app_v1/models/user.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Clear shared preferences before each test
    SharedPreferences.setMockInitialValues({});
    // Clear database
    await DatabaseService.clearAllData();
  });

  group('AuthService Password Hash Authentication Tests', () {
    test('should authenticate offline with correct password', () async {
      final authService = AuthService();

      // Create test user
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        typeUser: 'Propietario',
        image: 'test.png',
      );

      const password = 'mySecurePassword123';

      // Simulate a successful online login by saving user data with password hash
      // This mimics what happens in the login method when online authentication succeeds
      await authService.saveUser(user);
      await authService.saveToken('test_token');
      
      // Manually save with password hash (simulating what login method does)
      // We need to calculate the hash the same way the service does
      await DatabaseService.saveUserOffline(user, passwordHash: _calculatePasswordHash(password));

      // Now test offline authentication
      final result = await authService.authenticateOffline(user.email, password);

      // Verify successful authentication
      expect(result.success, isTrue);
      expect(result.user.email, equals(user.email));
      expect(result.message, equals('Autenticación offline exitosa'));
      expect(result.token, startsWith('offline_'));
    });

    test('should fail offline authentication with incorrect password', () async {
      final authService = AuthService();

      // Create test user
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        typeUser: 'Propietario',
        image: 'test.png',
      );

      const correctPassword = 'mySecurePassword123';
      const wrongPassword = 'wrongPassword456';

      // Save user with correct password hash
      await authService.saveUser(user);
      await DatabaseService.saveUserOffline(user, passwordHash: _calculatePasswordHash(correctPassword));

      // Test offline authentication with wrong password
      expect(
        () async => await authService.authenticateOffline(user.email, wrongPassword),
        throwsA(predicate((e) => e.toString().contains('Credenciales incorrectas'))),
      );
    });

    test('should fail offline authentication when no password hash stored', () async {
      final authService = AuthService();

      // Create test user
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        typeUser: 'Propietario',
        image: 'test.png',
      );

      // Save user WITHOUT password hash (simulating legacy data)
      await authService.saveUser(user);
      await DatabaseService.saveUserOffline(user); // No passwordHash parameter

      // Test offline authentication should fail
      expect(
        () async => await authService.authenticateOffline(user.email, 'anyPassword'),
        throwsA(predicate((e) => e.toString().contains('No hay credenciales almacenadas para autenticación offline'))),
      );
    });

    test('should fail offline authentication with email mismatch', () async {
      final authService = AuthService();

      // Create test user
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        typeUser: 'Propietario',
        image: 'test.png',
      );

      const password = 'mySecurePassword123';

      // Save user data
      await authService.saveUser(user);
      await DatabaseService.saveUserOffline(user, passwordHash: _calculatePasswordHash(password));

      // Try to authenticate with different email
      expect(
        () async => await authService.authenticateOffline('different@example.com', password),
        throwsA(predicate((e) => e.toString().contains('Los datos almacenados no coinciden con el usuario solicitado'))),
      );
    });

    test('should handle case-insensitive email in offline authentication', () async {
      final authService = AuthService();

      // Create test user with mixed case email
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'Test@Example.COM',
        typeUser: 'Propietario',
        image: 'test.png',
      );

      const password = 'mySecurePassword123';

      // Save user data
      await authService.saveUser(user);
      await DatabaseService.saveUserOffline(user, passwordHash: _calculatePasswordHash(password));

      // Test authentication with different case email
      final result = await authService.authenticateOffline('test@example.com', password);

      expect(result.success, isTrue);
      expect(result.user.email, equals(user.email));
    });

    test('should check offline auth availability correctly', () async {
      final authService = AuthService();

      // Initially no offline auth should be available
      expect(await authService.isOfflineAuthAvailable(), isFalse);

      // Create and save test user
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        typeUser: 'Propietario',
        image: 'test.png',
      );

      await DatabaseService.saveUserOffline(user);

      // Now offline auth should be available
      expect(await authService.isOfflineAuthAvailable(), isTrue);
    });

    test('should update password hash on subsequent saves', () async {
      final authService = AuthService();

      final user = User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        typeUser: 'Propietario',
        image: 'test.png',
      );

      const oldPassword = 'oldPassword123';
      const newPassword = 'newPassword456';

      // Save with old password
      await DatabaseService.saveUserOffline(user, passwordHash: _calculatePasswordHash(oldPassword));

      // Test authentication with old password works
      final result1 = await authService.authenticateOffline(user.email, oldPassword);
      expect(result1.success, isTrue);

      // Update with new password hash
      await DatabaseService.saveUserOffline(user, passwordHash: _calculatePasswordHash(newPassword));

      // Old password should now fail
      expect(
        () async => await authService.authenticateOffline(user.email, oldPassword),
        throwsA(predicate((e) => e.toString().contains('Credenciales incorrectas'))),
      );

      // New password should work
      final result2 = await authService.authenticateOffline(user.email, newPassword);
      expect(result2.success, isTrue);
    });
  });
}

// Helper function to calculate password hash the same way AuthService does
String _calculatePasswordHash(String password) {
  // This mimics the private _hashPassword method in AuthService
  // We use the same crypto library and method
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}