import 'package:flutter_test/flutter_test.dart';
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

  group('Offline Database Service Tests', () {
    test('should save and retrieve user data offline', () async {
      // Create test user
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        typeUser: 'Propietario',
        image: 'test.png',
      );

      // Save user
      await DatabaseService.saveUserOffline(user);

      // Retrieve user
      final retrievedUser = await DatabaseService.getUserOffline();

      // Verify
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.id, equals(user.id));
      expect(retrievedUser.name, equals(user.name));
      expect(retrievedUser.email, equals(user.email));
      expect(retrievedUser.typeUser, equals(user.typeUser));
    });

    test('should save and retrieve fincas data offline', () async {
      // Create test finca
      final propietario = Propietario(
        id: 1,
        idPersonal: 100,
        nombre: 'Juan',
        apellido: 'Pérez',
        telefono: '1234567890',
        archivado: false,
      );

      final finca = Finca(
        idFinca: 1,
        idPropietario: 1,
        nombre: 'Finca Test',
        explotacionTipo: 'Bovinos',
        archivado: false,
        createdAt: '2024-01-01T00:00:00.000000Z',
        updatedAt: '2024-01-01T00:00:00.000000Z',
        propietario: propietario,
      );

      // Save fincas
      await DatabaseService.saveFincasOffline([finca]);

      // Retrieve fincas
      final retrievedFincas = await DatabaseService.getFincasOffline();

      // Verify
      expect(retrievedFincas, isNotEmpty);
      expect(retrievedFincas.first.idFinca, equals(finca.idFinca));
      expect(retrievedFincas.first.nombre, equals(finca.nombre));
      expect(retrievedFincas.first.propietario, isNotNull);
      expect(retrievedFincas.first.propietario!.nombre, equals(propietario.nombre));
    });

    test('should return last updated times', () async {
      // Save test data
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        typeUser: 'Propietario',
        image: 'test.png',
      );
      await DatabaseService.saveUserOffline(user);

      // Check last updated time
      final userLastUpdated = await DatabaseService.getUserLastUpdated();
      expect(userLastUpdated, isNotNull);

      final now = DateTime.now();
      final diff = now.difference(userLastUpdated!);
      expect(diff.inMinutes, lessThan(1)); // Should be very recent
    });

    test('should clear all data', () async {
      // Save test data
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        typeUser: 'Propietario',
        image: 'test.png',
      );
      await DatabaseService.saveUserOffline(user);

      // Clear all data
      await DatabaseService.clearAllData();

      // Verify data is cleared
      final retrievedUser = await DatabaseService.getUserOffline();
      expect(retrievedUser, isNull);

      final retrievedFincas = await DatabaseService.getFincasOffline();
      expect(retrievedFincas, isEmpty);
    });
  });
}