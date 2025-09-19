import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Synchronization Fix Verification', () {
    test('verifies that markAnimalAsSynced works correctly after pending animal creation', () async {
      print('=== Testing Synchronization Fix ===');
      
      // Step 1: Create an animal offline (simulating offline mode)
      print('Step 1: Creating animal offline...');
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Test Sync Fix',
        codigoAnimal: 'SYNC-FIX-001',
        sexo: 'M',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      // Step 2: Verify animal is in pending state
      print('Step 2: Verifying animal is in pending state...');
      var pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      expect(pendingAnimals.length, equals(1), reason: 'Should have 1 pending animal');
      
      final tempId = pendingAnimals.first['id_animal'] as int;
      print('   Temp ID: $tempId');
      expect(tempId, lessThan(0), reason: 'Temp ID should be negative');

      // Step 3: Simulate successful server creation (this should NOT call saveAnimalesOffline)
      print('Step 3: Simulating successful server creation...');
      const realId = 42; // This would come from server response
      
      // The fix: no more saveAnimalesOffline call that would replace the pending record
      // We go directly to marking it as synced
      
      // Step 4: Mark animal as synced (this should work now)
      print('Step 4: Marking animal as synced...');
      await DatabaseService.markAnimalAsSynced(tempId, realId);
      print('   Marked animal as synced: $tempId -> $realId');

      // Step 5: Verify animal is no longer pending
      print('Step 5: Verifying animal is no longer pending...');
      pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      print('   Pending animals after sync: ${pendingAnimals.length}');
      expect(pendingAnimals.length, equals(0), reason: 'No animals should be pending after successful sync');

      // Step 6: Verify animal is marked as synced using the real ID
      print('Step 6: Verifying animal is properly marked as synced...');
      final isAlreadySynced = await DatabaseService.isAnimalAlreadySynced(realId);
      expect(isAlreadySynced, isTrue, reason: 'Animal should be marked as synced with real ID');

      // Step 7: Verify the record still exists with the real ID
      print('Step 7: Verifying record exists with real ID...');
      final db = await DatabaseService.database;
      final records = await db.query(
        'animales',
        where: 'id_animal = ?',
        whereArgs: [realId],
      );
      expect(records.length, equals(1), reason: 'Should have exactly one record with real ID');
      expect(records.first['synced'], equals(1), reason: 'Record should be marked as synced');
      expect(records.first['is_pending'], equals(0), reason: 'Record should not be pending');

      print('=== Synchronization Fix test completed successfully! ===');
    });
  });
}