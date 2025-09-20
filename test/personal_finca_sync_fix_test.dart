import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/services/database_service.dart';
import '../lib/services/logging_service.dart';

void main() {
  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory for unit testing
    databaseFactory = databaseFactoryFfi;
  });

  group('Personal Finca Sync Fix Tests', () {
    setUp(() async {
      // Initialize the database
      await DatabaseService.database;
      await DatabaseService.clearAllData();
    });

    test('should handle sync with current flow (no redundant save) - Issue #89 fix', () async {
      print('\n=== Testing sync with current flow (AuthService no longer saves to DB) ===');

      // Step 1: Create a pending personal finca with temp ID
      await DatabaseService.savePendingPersonalFincaOffline(
        idFinca: 1,
        cedula: 12345678,
        nombre: 'Test',
        apellido: 'Personal',
        telefono: '3001234567',
        correo: 'test@example.com',
        tipoTrabajador: 'Administrador',
      );

      // Get the temp ID
      final pendingPersonal = await DatabaseService.getPendingPersonalFincaOffline();
      expect(pendingPersonal.length, equals(1));
      final tempId = pendingPersonal.first['id_tecnico'] as int;
      expect(tempId < 0, isTrue); // Should be negative temp ID
      
      print('Created pending personal finca with temp ID: $tempId');

      // Step 2: Verify only temp record exists (AuthService no longer saves real ID record)
      final db = await DatabaseService.database;
      final allPersonal = await db.query('personal_finca');
      expect(allPersonal.length, equals(1));
      expect(allPersonal.first['id_tecnico'], equals(tempId));
      
      print('Verified only temp record exists (no redundant save from AuthService)');

      // Step 3: Call markPersonalFincaAsSynced (should update temp record with real ID)
      final realId = 1011;
      await DatabaseService.markPersonalFincaAsSynced(tempId, realId);
      print('Successfully called markPersonalFincaAsSynced');

      // Step 4: Verify the temp record is updated with real ID (not removed)
      final finalPersonal = await db.query('personal_finca');
      expect(finalPersonal.length, equals(1)); // Still 1 record (updated, not removed)
      expect(finalPersonal.first['id_tecnico'], equals(realId)); // Now has real ID
      expect(finalPersonal.first['synced'], equals(1));
      expect(finalPersonal.first['is_pending'], equals(0));
      
      print('✓ Temp record updated with real ID: $realId');

      // Step 5: Verify no pending records remain
      final stillPending = await DatabaseService.getPendingPersonalFincaOffline();
      expect(stillPending.length, equals(0));
      
      print('✓ No pending records remain');
      print('=== Test PASSED - Issue #89 Fixed ===');
    });

    test('should handle sync when real ID record does not exist', () async {
      print('\n=== Testing sync when real ID record does not exist ===');

      // Step 1: Create a pending personal finca with temp ID
      await DatabaseService.savePendingPersonalFincaOffline(
        idFinca: 1,
        cedula:87654321,
        nombre: 'Another',
        apellido: 'Person',
        telefono: '3007654321',
        correo: 'another@example.com',
        tipoTrabajador: 'Operario',
      );

      // Get the temp ID
      final pendingPersonal = await DatabaseService.getPendingPersonalFincaOffline();
      expect(pendingPersonal.length, equals(1));
      final tempId = pendingPersonal.first['id_tecnico'] as int;
      
      print('Created pending personal finca with temp ID: $tempId');

      // Step 2: Call markPersonalFincaAsSynced (should update the record)
      final realId = 2022;
      await DatabaseService.markPersonalFincaAsSynced(tempId, realId);
      print('Successfully called markPersonalFincaAsSynced');

      // Step 3: Verify the record was updated with real ID
      final db = await DatabaseService.database;
      final finalPersonal = await db.query('personal_finca');
      expect(finalPersonal.length, equals(1));
      expect(finalPersonal.first['id_tecnico'], equals(realId));
      expect(finalPersonal.first['synced'], equals(1));
      expect(finalPersonal.first['is_pending'], equals(0));
      expect(finalPersonal.first['pending_operation'], isNull);
      
      print('✓ Record updated with real ID: $realId');

      // Step 4: Verify no pending records remain
      final stillPending = await DatabaseService.getPendingPersonalFincaOffline();
      expect(stillPending.length, equals(0));
      
      print('✓ No pending records remain');
      print('=== Test PASSED ===');
    });

    test('should handle error cases appropriately', () async {
      print('\n=== Testing error cases ===');

      // Test updating non-existent record
      bool errorCaught = false;
      try {
        await DatabaseService.markPersonalFincaAsSynced(-99999, 3033);
      } catch (e) {
        errorCaught = true;
        expect(e.toString(), contains('not found'));
      }
      expect(errorCaught, isTrue);
      print('✓ Correctly handled attempt to sync non-existent personal finca');

      // Test updating already synced record
      await DatabaseService.savePendingPersonalFincaOffline(
        idFinca: 1,
        cedula: 11111111,
        nombre: 'Already',
        apellido: 'Synced',
        telefono: '3001111111',
        correo: 'synced@example.com',
        tipoTrabajador: 'Supervisor',
      );

      final pendingPersonal = await DatabaseService.getPendingPersonalFincaOffline();
      final tempId = pendingPersonal.first['id_tecnico'] as int;
      
      // Mark as synced first time
      await DatabaseService.markPersonalFincaAsSynced(tempId, 4044);
      
      // Try to mark as synced again
      errorCaught = false;
      try {
        await DatabaseService.markPersonalFincaAsSynced(tempId, 4044);
      } catch (e) {
        errorCaught = true;
        expect(e.toString(), contains('already synced'));
      }
      expect(errorCaught, isTrue);
      print('✓ Correctly handled attempt to sync already synced record');
      
      print('=== Error Cases Test PASSED ===');
    });
  });
}