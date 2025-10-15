import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/services/database_service.dart';

void main() {
  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory for unit testing
    databaseFactory = databaseFactoryFfi;
  });

  group('Issue #89 Sync Fix Tests', () {
    setUp(() async {
      // Initialize the database
      await DatabaseService.database;
      await DatabaseService.clearAllData();
    });

    test(
      'should handle personal finca sync correctly with new flow (no redundant save)',
      () async {
        print('\n=== Testing Issue #89: Personal finca sync with new flow ===');

        // Step 1: Create a pending personal finca offline (simulating offline creation)
        await DatabaseService.savePendingPersonalFincaOffline(
          idFinca: 1,
          cedula: 87654321,
          nombre: 'Offline',
          apellido: 'Created',
          telefono: '3001234567',
          correo: 'offline@example.com',
          tipoTrabajador: 'Administrador',
        );

        // Get the temp ID
        final pendingPersonal =
            await DatabaseService.getPendingPersonalFincaOffline();
        expect(pendingPersonal.length, equals(1));
        final tempId = pendingPersonal.first['id_tecnico'] as int;
        expect(tempId < 0, isTrue); // Should be negative temp ID

        print('Created pending personal finca with temp ID: $tempId');

        // Step 2: Verify only the temp record exists (no real ID record should exist)
        final db = await DatabaseService.database;
        final allPersonal = await db.query('personal_finca');
        expect(allPersonal.length, equals(1));
        expect(allPersonal.first['id_tecnico'], equals(tempId));

        print('Verified only temp record exists: ${allPersonal.first}');

        // Step 3: Simulate successful sync - call markPersonalFincaAsSynced
        // This simulates what happens after AuthService.createPersonalFinca returns with real ID
        const realId = 12345;
        await DatabaseService.markPersonalFincaAsSynced(tempId, realId);

        print(
          'Successfully called markPersonalFincaAsSynced: $tempId -> $realId',
        );

        // Step 4: Verify the temp record is updated with real ID (not removed)
        final finalPersonal = await db.query('personal_finca');
        expect(finalPersonal.length, equals(1)); // Should still be 1 record
        expect(
          finalPersonal.first['id_tecnico'],
          equals(realId),
        ); // Should have real ID now
        expect(
          finalPersonal.first['synced'],
          equals(1),
        ); // Should be marked as synced
        expect(
          finalPersonal.first['is_pending'],
          equals(0),
        ); // Should not be pending
        expect(
          finalPersonal.first['pending_operation'],
          isNull,
        ); // Should clear operation

        print('✓ Temp record updated with real ID: ${finalPersonal.first}');

        // Step 5: Verify no pending records remain
        final stillPending =
            await DatabaseService.getPendingPersonalFincaOffline();
        expect(stillPending.length, equals(0));

        print('✓ No pending records remain');
        print('=== Issue #89 Test PASSED ===');
      },
    );

    test(
      'should handle animal sync correctly (verification that animals work)',
      () async {
        print('\n=== Verifying animal sync still works correctly ===');

        // Create an animal offline
        await DatabaseService.savePendingAnimalOffline(
          idRebano: 1,
          nombre: 'Test Animal',
          codigoAnimal: 'TEST-001',
          sexo: 'M',
          fechaNacimiento: '2024-01-01',
          procedencia: 'Local',
          fkComposicionRaza: 1,
          estadoId: 1,
          etapaId: 1,
        );

        final pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
        expect(pendingAnimals.length, equals(1));
        final tempId = pendingAnimals.first['id_animal'] as int;
        expect(tempId < 0, isTrue);

        // Simulate sync
        const realId = 54321;
        await DatabaseService.markAnimalAsSynced(tempId, realId);

        // Verify
        final db = await DatabaseService.database;
        final finalAnimals = await db.query('animales');
        expect(finalAnimals.length, equals(1));
        expect(finalAnimals.first['id_animal'], equals(realId));
        expect(finalAnimals.first['synced'], equals(1));
        expect(finalAnimals.first['is_pending'], equals(0));

        print('✓ Animal sync still works correctly');
      },
    );

    test('should handle multiple pending records sync', () async {
      print('\n=== Testing multiple pending records sync ===');

      // Create multiple pending personal finca records
      await DatabaseService.savePendingPersonalFincaOffline(
        idFinca: 1,
        cedula: 11111111,
        nombre: 'First',
        apellido: 'Person',
        telefono: '3001111111',
        correo: 'first@example.com',
        tipoTrabajador: 'Administrador',
      );

      await DatabaseService.savePendingPersonalFincaOffline(
        idFinca: 2,
        cedula: 22222222,
        nombre: 'Second',
        apellido: 'Person',
        telefono: '3002222222',
        correo: 'second@example.com',
        tipoTrabajador: 'Operario',
      );

      final pendingPersonal =
          await DatabaseService.getPendingPersonalFincaOffline();
      expect(pendingPersonal.length, equals(2));

      // Sync both records
      final tempId1 = pendingPersonal[0]['id_tecnico'] as int;
      final tempId2 = pendingPersonal[1]['id_tecnico'] as int;

      await DatabaseService.markPersonalFincaAsSynced(tempId1, 100);
      await DatabaseService.markPersonalFincaAsSynced(tempId2, 200);

      // Verify both are synced
      final finalPending =
          await DatabaseService.getPendingPersonalFincaOffline();
      expect(finalPending.length, equals(0));

      final db = await DatabaseService.database;
      final allPersonal = await db.query(
        'personal_finca',
        orderBy: 'id_tecnico',
      );
      expect(allPersonal.length, equals(2));
      expect(allPersonal[0]['id_tecnico'], equals(100));
      expect(allPersonal[1]['id_tecnico'], equals(200));

      print('✓ Multiple records synced correctly');
    });
  });
}
