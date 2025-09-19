import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:ganaderasoft_app_v1/models/pending_sync_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Offline Animal Creation Integration Tests', () {
    test('complete offline animal creation and sync flow', () async {
      // Step 1: Create an animal offline (simulating no connectivity)
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Vaca Holstein',
        codigoAnimal: 'HOL-001',
        sexo: 'F',
        fechaNacimiento: '2023-05-15',
        procedencia: 'Local',
        fkComposicionRaza: 5,
        estadoId: 1,
        etapaId: 3,
      );

      // Step 2: Verify it was saved as pending
      final pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      expect(pendingAnimals, isNotEmpty);
      expect(pendingAnimals.length, equals(1));

      final savedAnimal = pendingAnimals.first;
      expect(savedAnimal['nombre'], equals('Vaca Holstein'));
      expect(savedAnimal['codigo_animal'], equals('HOL-001'));
      expect(savedAnimal['is_pending'], equals(1));
      expect(savedAnimal['synced'], equals(0));
      
      // Temp ID should be negative
      final tempId = savedAnimal['id_animal'] as int;
      expect(tempId, lessThan(0));

      // Step 3: Verify it appears in all pending records
      final allPending = await DatabaseService.getAllPendingRecords();
      final animalRecords = allPending.where((r) => r['type'] == 'Animal').toList();
      expect(animalRecords, isNotEmpty);
      
      final pendingAnimalRecord = animalRecords.firstWhere(
        (r) => r['name'] == 'Vaca Holstein',
      );
      expect(pendingAnimalRecord['operation'], equals('CREATE'));

      // Step 4: Simulate successful sync by marking as synced
      const realServerId = 123;
      await DatabaseService.markAnimalAsSynced(tempId, realServerId);

      // Step 5: Verify it's no longer pending
      final stillPending = await DatabaseService.getPendingAnimalsOffline();
      final syncedAnimals = stillPending.where((a) => a['id_animal'] == realServerId);
      expect(syncedAnimals, isEmpty);

      // Step 6: Verify the all pending records list is updated
      final finalPending = await DatabaseService.getAllPendingRecords();
      final finalAnimalRecords = finalPending.where(
        (r) => r['type'] == 'Animal' && r['name'] == 'Vaca Holstein',
      ).toList();
      expect(finalAnimalRecords, isEmpty);
    });

    test('multiple offline animals can be created and tracked', () async {
      // Create multiple animals offline
      final animalsToCreate = [
        {
          'nombre': 'Toro Brahman',
          'codigo': 'BRA-001',
          'sexo': 'M',
          'rebano': 1,
        },
        {
          'nombre': 'Vaca Jersey',
          'codigo': 'JER-001',
          'sexo': 'F',
          'rebano': 2,
        },
        {
          'nombre': 'Novillo Angus',
          'codigo': 'ANG-001',
          'sexo': 'M',
          'rebano': 1,
        },
      ];

      for (final animalData in animalsToCreate) {
        await DatabaseService.savePendingAnimalOffline(
          idRebano: animalData['rebano'] as int,
          nombre: animalData['nombre'] as String,
          codigoAnimal: animalData['codigo'] as String,
          sexo: animalData['sexo'] as String,
          fechaNacimiento: '2023-06-01',
          procedencia: 'Local',
          fkComposicionRaza: 1,
          estadoId: 1,
          etapaId: 1,
        );
      }

      // Verify all are saved as pending
      final pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      expect(pendingAnimals.length, greaterThanOrEqualTo(3));

      // Verify each animal is correctly saved
      for (final animalData in animalsToCreate) {
        final savedAnimal = pendingAnimals.firstWhere(
          (a) => a['nombre'] == animalData['nombre'],
        );
        expect(savedAnimal['codigo_animal'], equals(animalData['codigo']));
        expect(savedAnimal['sexo'], equals(animalData['sexo']));
        expect(savedAnimal['id_rebano'], equals(animalData['rebano']));
        expect(savedAnimal['is_pending'], equals(1));
        expect(savedAnimal['synced'], equals(0));
      }

      // Verify they appear in the all pending records
      final allPending = await DatabaseService.getAllPendingRecords();
      final animalRecords = allPending.where((r) => r['type'] == 'Animal').toList();
      expect(animalRecords.length, greaterThanOrEqualTo(3));

      for (final animalData in animalsToCreate) {
        final foundRecord = animalRecords.where(
          (r) => r['name'] == animalData['nombre'],
        );
        expect(foundRecord, isNotEmpty);
      }
    });

    test('pending operations enum works correctly', () {
      // Test the enum functionality that would be used in the UI
      final createOp = PendingOperation.create;
      final updateOp = PendingOperation.update;
      final deleteOp = PendingOperation.delete;

      expect(createOp.value, equals('CREATE'));
      expect(updateOp.value, equals('UPDATE'));
      expect(deleteOp.value, equals('DELETE'));

      // Test parsing from strings (as would come from database)
      expect(PendingOperationExtension.fromString('CREATE'), equals(createOp));
      expect(PendingOperationExtension.fromString('UPDATE'), equals(updateOp));
      expect(PendingOperationExtension.fromString('DELETE'), equals(deleteOp));
    });
  });
}