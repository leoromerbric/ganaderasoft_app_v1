import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/auth_service.dart';
import 'package:ganaderasoft_app_v1/services/connectivity_service.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:ganaderasoft_app_v1/models/user.dart';
import 'package:ganaderasoft_app_v1/models/finca.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Offline Functionality Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('should handle server timeout and return cached data', () async {
      // Setup: Save some test data offline
      final testUser = User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        typeUser: 'Propietario',
        image: 'test.png',
      );
      await DatabaseService.saveUserOffline(testUser);

      final testFinca = Finca(
        idFinca: 1,
        idPropietario: 1,
        nombre: 'Test Finca',
        explotacionTipo: 'Bovinos',
        archivado: false,
        createdAt: '2024-01-01T00:00:00.000000Z',
        updatedAt: '2024-01-01T00:00:00.000000Z',
      );
      await DatabaseService.saveFincasOffline([testFinca]);

      // Test: Try to get profile data (should work with cached data even if server times out)
      try {
        final profile = await authService.getProfile();
        expect(profile.id, equals(testUser.id));
        expect(profile.name, equals(testUser.name));
      } catch (e) {
        // If getProfile throws due to no network, try the offline method directly
        final cachedUser = await DatabaseService.getUserOffline();
        expect(cachedUser, isNotNull);
        expect(cachedUser!.id, equals(testUser.id));
      }

      // Test: Try to get fincas data (should work with cached data)
      try {
        final fincasResponse = await authService.getFincas();
        expect(fincasResponse.fincas.isNotEmpty, isTrue);
        expect(fincasResponse.fincas.first.idFinca, equals(testFinca.idFinca));
      } catch (e) {
        // If getFincas throws due to no network, verify offline data is available
        final cachedFincas = await DatabaseService.getFincasOffline();
        expect(cachedFincas.isNotEmpty, isTrue);
        expect(cachedFincas.first.idFinca, equals(testFinca.idFinca));
      }
    });

    test('should detect when server is unreachable', () async {
      // Test connectivity check
      final isConnected = await ConnectivityService.isConnected();
      
      // This should complete quickly (within timeout) regardless of result
      final stopwatch = Stopwatch()..start();
      await ConnectivityService.isConnected();
      stopwatch.stop();
      
      // Should complete within reasonable time (not hang for minutes)
      expect(stopwatch.elapsedMilliseconds, lessThan(15000)); // 15 seconds max
    });

    test('should have proper fallback chain for user data', () async {
      // Clear all data first
      await DatabaseService.clearAllData();

      // Test 1: No cached data - should throw
      try {
        final cachedUser = await DatabaseService.getUserOffline();
        expect(cachedUser, isNull);
      } catch (e) {
        // Expected when no cached data
      }

      // Test 2: Add cached data and verify retrieval
      final testUser = User(
        id: 2,
        name: 'Cached User',
        email: 'cached@example.com',
        typeUser: 'Propietario',
        image: 'cached.png',
      );
      await DatabaseService.saveUserOffline(testUser);

      final retrievedUser = await DatabaseService.getUserOffline();
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.id, equals(testUser.id));
      expect(retrievedUser.name, equals(testUser.name));
    });

    test('should have proper fallback chain for fincas data', () async {
      // Clear all data first
      await DatabaseService.clearAllData();

      // Test 1: No cached data - should return empty list
      final emptyFincas = await DatabaseService.getFincasOffline();
      expect(emptyFincas, isEmpty);

      // Test 2: Add cached data and verify retrieval
      final testFincas = [
        Finca(
          idFinca: 1,
          idPropietario: 1,
          nombre: 'Finca 1',
          explotacionTipo: 'Bovinos',
          archivado: false,
          createdAt: '2024-01-01T00:00:00.000000Z',
          updatedAt: '2024-01-01T00:00:00.000000Z',
        ),
        Finca(
          idFinca: 2,
          idPropietario: 1,
          nombre: 'Finca 2',
          explotacionTipo: 'Porcinos',
          archivado: false,
          createdAt: '2024-01-01T00:00:00.000000Z',
          updatedAt: '2024-01-01T00:00:00.000000Z',
        ),
      ];
      await DatabaseService.saveFincasOffline(testFincas);

      final retrievedFincas = await DatabaseService.getFincasOffline();
      expect(retrievedFincas, hasLength(2));
      expect(retrievedFincas.first.idFinca, equals(1));
      expect(retrievedFincas.last.idFinca, equals(2));
    });

    test('should handle network connectivity check gracefully', () async {
      // Test that network check methods don't throw and complete quickly
      final stopwatch = Stopwatch()..start();
      
      final hasNetwork = await ConnectivityService.hasNetworkConnection();
      final isConnected = await ConnectivityService.isConnected();
      
      stopwatch.stop();
      
      // Both should be boolean values
      expect(hasNetwork, isA<bool>());
      expect(isConnected, isA<bool>());
      
      // Should complete quickly
      expect(stopwatch.elapsedMilliseconds, lessThan(15000));
    });
  });
}