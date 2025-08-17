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
  });

  group('Logout and Offline Authentication Tests', () {
    test('should preserve offline data after logout', () async {
      final authService = AuthService();

      // Create test user
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        typeUser: 'Propietario',
        image: 'test.png',
      );

      // Save user data (simulating successful login)
      await authService.saveUser(user);
      await authService.saveToken('test_token');
      await DatabaseService.saveUserOffline(user);

      // Verify user is logged in and data exists
      expect(await authService.isLoggedIn(), isTrue);
      expect(await DatabaseService.getUserOffline(), isNotNull);

      // Perform logout
      await authService.logout();

      // Verify token is cleared but offline data persists
      expect(await authService.isLoggedIn(), isFalse);
      expect(await authService.getToken(), isNull);
      expect(await authService.getUser(), isNull);
      
      // Most importantly - offline data should still exist
      final cachedUser = await DatabaseService.getUserOffline();
      expect(cachedUser, isNotNull);
      expect(cachedUser!.email, equals(user.email));
      expect(cachedUser.name, equals(user.name));
    });

    test('should detect offline authentication availability', () async {
      final authService = AuthService();

      // Initially no offline auth available
      expect(await authService.isOfflineAuthAvailable(), isFalse);

      // Save user data
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

    test('should authenticate offline successfully', () async {
      final authService = AuthService();

      // Save user data for offline authentication
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        typeUser: 'Propietario',
        image: 'test.png',
      );
      await DatabaseService.saveUserOffline(user);

      // Attempt offline authentication
      final response = await authService.authenticateOffline('test@example.com', 'any_password');

      // Verify successful authentication
      expect(response.success, isTrue);
      expect(response.user.email, equals(user.email));
      expect(response.token, isNotNull);
      expect(response.token, startsWith('offline_'));

      // Verify session is restored
      expect(await authService.isLoggedIn(), isTrue);
      final currentUser = await authService.getUser();
      expect(currentUser, isNotNull);
      expect(currentUser!.email, equals(user.email));
    });

    test('should fail offline authentication with wrong email', () async {
      final authService = AuthService();

      // Save user data for offline authentication
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        typeUser: 'Propietario',
        image: 'test.png',
      );
      await DatabaseService.saveUserOffline(user);

      // Attempt offline authentication with wrong email
      expect(
        () async => await authService.authenticateOffline('wrong@example.com', 'any_password'),
        throwsException,
      );
    });

    test('should fail offline authentication with no cached data', () async {
      final authService = AuthService();

      // Attempt offline authentication without any cached data
      expect(
        () async => await authService.authenticateOffline('test@example.com', 'any_password'),
        throwsException,
      );
    });
  });
}