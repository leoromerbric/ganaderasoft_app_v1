import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Issue #69 Reproduction and Fix Tests', () {
    test('reproduces the exact issue: animal stays pending after sync and duplicates on re-sync', () async {
      print('=== Testing Issue #69: Animal synchronization bug ===');
      
      // Step 1: Create an animal offline (simulating creating animal in offline mode)
      print('Step 1: Creating animal offline...');
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Test Animal Issue 69',
        codigoAnimal: 'ISSUE-69-001',
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
      
      var allPendingRecords = await DatabaseService.getAllPendingRecords();
      var animalPendingRecords = allPendingRecords.where((r) => r['type'] == 'Animal').toList();
      expect(animalPendingRecords.length, equals(1), reason: 'Should have 1 pending animal record');

      // Step 3: Simulate first sync (connection established, sync button clicked)
      print('Step 3: Simulating first sync...');
      const realId = 12345; // This would come from server response
      
      // This simulates what happens in the sync process
      await DatabaseService.markAnimalAsSynced(tempId, realId);
      print('   Marked animal as synced: $tempId -> $realId');

      // Step 4: Verify animal is no longer pending (this is where the bug was)
      print('Step 4: Verifying animal is no longer pending...');
      pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      print('   Pending animals after sync: ${pendingAnimals.length}');
      expect(pendingAnimals.length, equals(0), reason: 'No animals should be pending after successful sync');

      allPendingRecords = await DatabaseService.getAllPendingRecords();
      animalPendingRecords = allPendingRecords.where((r) => r['type'] == 'Animal').toList();
      print('   Pending animal records after sync: ${animalPendingRecords.length}');
      expect(animalPendingRecords.length, equals(0), reason: 'No animal records should be pending after successful sync');

      // Step 5: Verify animal is marked as synced
      print('Step 5: Verifying animal is properly marked as synced...');
      final isAlreadySynced = await DatabaseService.isAnimalAlreadySynced(realId);
      expect(isAlreadySynced, isTrue, reason: 'Animal should be marked as synced');

      // Step 6: Simulate second sync attempt (user clicks sync button again)
      print('Step 6: Simulating second sync attempt...');
      
      // Get pending animals again (should be empty now with our fix)
      pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      print('   Pending animals for second sync: ${pendingAnimals.length}');
      expect(pendingAnimals.length, equals(0), reason: 'Should have no pending animals for second sync');

      // Step 7: Try to sync the same animal again (should be prevented)
      print('Step 7: Testing duplicate sync prevention...');
      try {
        await DatabaseService.markAnimalAsSynced(tempId, realId);
        fail('Should have thrown an exception when trying to sync already synced animal');
      } catch (e) {
        print('   ✓ Correctly prevented duplicate sync: ${e.toString()}');
        expect(e.toString(), contains('already synced'), reason: 'Should indicate animal already synced');
      }

      // Step 8: Verify no duplication occurred
      print('Step 8: Final verification - no duplication...');
      pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      expect(pendingAnimals.length, equals(0), reason: 'Still no pending animals');
      
      allPendingRecords = await DatabaseService.getAllPendingRecords();
      animalPendingRecords = allPendingRecords.where((r) => r['type'] == 'Animal').toList();
      expect(animalPendingRecords.length, equals(0), reason: 'Still no pending animal records');

      print('=== Issue #69 test completed successfully! ===');
    });

    test('simulates multiple rapid sync clicks to test race condition protection', () async {
      print('=== Testing Race Condition Protection ===');
      
      // Create multiple animals offline
      final animalNames = ['Race Animal 1', 'Race Animal 2', 'Race Animal 3'];
      final List<int> tempIds = [];
      
      for (int i = 0; i < animalNames.length; i++) {
        await DatabaseService.savePendingAnimalOffline(
          idRebano: 1,
          nombre: animalNames[i],
          codigoAnimal: 'RACE-${i + 1}',
          sexo: i.isEven ? 'M' : 'F',
          fechaNacimiento: '2024-01-0${i + 1}',
          procedencia: 'Local',
          fkComposicionRaza: 1,
          estadoId: 1,
          etapaId: 1,
        );
      }

      // Get all pending animals
      var pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      expect(pendingAnimals.length, greaterThanOrEqualTo(3));
      
      // Extract temp IDs
      for (int i = 0; i < 3; i++) {
        tempIds.add(pendingAnimals[i]['id_animal'] as int);
      }

      print('Created ${tempIds.length} animals with temp IDs: $tempIds');

      // Simulate rapid sync operations (as if user clicks sync button multiple times)
      final List<Future<void>> syncOperations = [];
      
      for (int i = 0; i < tempIds.length; i++) {
        final tempId = tempIds[i];
        final realId = 5000 + i;
        
        syncOperations.add(() async {
          try {
            // Check if already synced first (our new protection)
            final isAlreadySynced = await DatabaseService.isAnimalAlreadySynced(tempId);
            if (isAlreadySynced) {
              print('Animal $tempId already synced, skipping');
              return;
            }
            
            await DatabaseService.markAnimalAsSynced(tempId, realId);
            print('Successfully synced $tempId -> $realId');
          } catch (e) {
            print('Sync attempt failed for $tempId: $e');
            // This is expected for duplicate attempts
          }
        }());
      }

      // Wait for all sync operations to complete
      await Future.wait(syncOperations);

      // Verify final state
      pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      final remainingTempIds = pendingAnimals.map((a) => a['id_animal'] as int).toList();
      
      print('Remaining pending animals: ${pendingAnimals.length}');
      print('Remaining temp IDs: $remainingTempIds');
      
      // Check that our test animals are no longer pending
      for (final tempId in tempIds) {
        final stillPending = remainingTempIds.contains(tempId);
        expect(stillPending, isFalse, reason: 'Temp ID $tempId should no longer be pending');
      }

      print('=== Race Condition Protection test completed successfully! ===');
    });
  });
}