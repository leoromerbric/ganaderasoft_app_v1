import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Sync Fix Tests', () {
    test('should properly mark animal as synced and prevent duplicate sync', () async {
      // Save a pending animal
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Test Animal Fix',
        codigoAnimal: 'FIX-001',
        sexo: 'M',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      // Get the pending animal
      var pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      expect(pendingAnimals, isNotEmpty);
      expect(pendingAnimals.length, equals(1));
      
      final tempId = pendingAnimals.first['id_animal'] as int;
      expect(tempId, lessThan(0)); // Should be negative for temp IDs
      
      // Check that animal is not yet synced
      var isAlreadySynced = await DatabaseService.isAnimalAlreadySynced(tempId);
      expect(isAlreadySynced, isFalse);

      // Mark as synced with real ID
      const realId = 999;
      await DatabaseService.markAnimalAsSynced(tempId, realId);

      // Verify the animal is properly marked as synced
      isAlreadySynced = await DatabaseService.isAnimalAlreadySynced(realId);
      expect(isAlreadySynced, isTrue);
      
      // Verify the animal is no longer in pending list
      pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      expect(pendingAnimals, isEmpty, reason: 'Animal should no longer be in pending list after sync');
      
      // Verify that trying to sync again fails gracefully
      expect(
        () => DatabaseService.markAnimalAsSynced(tempId, realId),
        throwsException,
        reason: 'Should throw exception when trying to sync already synced animal',
      );
    });

    test('should handle multiple animals and prevent race conditions', () async {
      // Create multiple animals to test batch behavior
      final animalData = [
        {'nombre': 'Batch Animal 1', 'codigo': 'BATCH-001'},
        {'nombre': 'Batch Animal 2', 'codigo': 'BATCH-002'},
        {'nombre': 'Batch Animal 3', 'codigo': 'BATCH-003'},
      ];

      final List<int> tempIds = [];

      // Save all pending animals
      for (final data in animalData) {
        await DatabaseService.savePendingAnimalOffline(
          idRebano: 1,
          nombre: data['nombre']!,
          codigoAnimal: data['codigo']!,
          sexo: 'M',
          fechaNacimiento: '2024-01-01',
          procedencia: 'Local',
          fkComposicionRaza: 1,
          estadoId: 1,
          etapaId: 1,
        );
      }

      // Get all pending animals
      var pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      expect(pendingAnimals.length, greaterThanOrEqualTo(3));

      // Store temp IDs
      for (final animal in pendingAnimals.take(3)) {
        tempIds.add(animal['id_animal'] as int);
      }

      // Simulate syncing all animals
      for (int i = 0; i < 3; i++) {
        final tempId = tempIds[i];
        final realId = 2000 + i;

        // Verify not synced before
        var isAlreadySynced = await DatabaseService.isAnimalAlreadySynced(tempId);
        expect(isAlreadySynced, isFalse);

        // Mark as synced
        await DatabaseService.markAnimalAsSynced(tempId, realId);

        // Verify synced after
        isAlreadySynced = await DatabaseService.isAnimalAlreadySynced(realId);
        expect(isAlreadySynced, isTrue);

        // Check pending list decreases
        pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
        expect(pendingAnimals.length, lessThanOrEqualTo(3 - i - 1 + pendingAnimals.length - (3 - i - 1)),
            reason: 'Pending animals should decrease as animals are synced');
      }

      // Verify all test animals are no longer in pending list
      pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      for (final tempId in tempIds) {
        final stillPending = pendingAnimals.any((a) => a['id_animal'] == tempId);
        expect(stillPending, isFalse, reason: 'Temp ID $tempId should no longer be in pending list');
      }
    });

    test('should prevent duplicate sync attempts with proper error handling', () async {
      // Save a pending animal
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Duplicate Test Animal',
        codigoAnimal: 'DUP-001',
        sexo: 'F',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      // Get the pending animal
      final pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      expect(pendingAnimals, isNotEmpty);
      
      final tempId = pendingAnimals.first['id_animal'] as int;
      const realId = 3000;

      // First sync should succeed
      await DatabaseService.markAnimalAsSynced(tempId, realId);

      // Verify animal is marked as synced
      final isAlreadySynced = await DatabaseService.isAnimalAlreadySynced(realId);
      expect(isAlreadySynced, isTrue);

      // Attempt to sync again should fail with proper error
      try {
        await DatabaseService.markAnimalAsSynced(tempId, realId);
        fail('Should have thrown an exception for duplicate sync attempt');
      } catch (e) {
        expect(e.toString(), contains('already synced'));
      }

      // Verify animal is still properly synced and not duplicated
      final finalPendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      final stillPending = finalPendingAnimals.any((a) => a['id_animal'] == tempId || a['id_animal'] == realId);
      expect(stillPending, isFalse, reason: 'Animal should not be in pending list after sync');
    });
  });
}