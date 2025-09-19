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

  group('Pending Animal Offline Tests', () {
    test('should save and retrieve pending animals offline', () async {
      // Save a pending animal
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Test Animal Offline',
        codigoAnimal: 'TEST-001',
        sexo: 'M',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      // Retrieve pending animals
      final pendingAnimals = await DatabaseService.getPendingAnimalsOffline();

      // Verify
      expect(pendingAnimals, isNotEmpty);
      expect(pendingAnimals.length, equals(1));
      
      final animal = pendingAnimals.first;
      expect(animal['nombre'], equals('Test Animal Offline'));
      expect(animal['codigo_animal'], equals('TEST-001'));
      expect(animal['sexo'], equals('M'));
      expect(animal['is_pending'], equals(1));
      expect(animal['synced'], equals(0));
      expect(animal['pending_operation'], equals('CREATE'));
      expect(animal['estado_id'], equals(1));
      expect(animal['etapa_id'], equals(1));
    });

    test('should mark pending animal as synced', () async {
      // Save a pending animal first
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Test Animal to Sync',
        codigoAnimal: 'SYNC-001',
        sexo: 'F',
        fechaNacimiento: '2024-01-15',
        procedencia: 'Local',
        fkComposicionRaza: 2,
        estadoId: 1,
        etapaId: 2,
      );

      // Get the pending animal
      final pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      expect(pendingAnimals, isNotEmpty);
      
      final tempId = pendingAnimals.first['id_animal'] as int;
      expect(tempId, lessThan(0)); // Should be negative for temp IDs

      // Mark as synced with real ID
      const realId = 123;
      await DatabaseService.markAnimalAsSynced(tempId, realId);

      // Verify the animal is no longer pending
      final stillPending = await DatabaseService.getPendingAnimalsOffline();
      final syncedAnimal = stillPending.where((a) => a['id_animal'] == realId);
      
      // Should not find the animal in pending list anymore
      expect(syncedAnimal, isEmpty);
    });

    test('should retrieve all pending records including animals', () async {
      // Save multiple pending animals
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Pending Animal 1',
        codigoAnimal: 'PEND-001',
        sexo: 'M',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      await DatabaseService.savePendingAnimalOffline(
        idRebano: 2,
        nombre: 'Pending Animal 2',
        codigoAnimal: 'PEND-002',
        sexo: 'F',
        fechaNacimiento: '2024-01-02',
        procedencia: 'Local',
        fkComposicionRaza: 2,
        estadoId: 1,
        etapaId: 2,
      );

      // Get all pending records
      final allPending = await DatabaseService.getAllPendingRecords();

      // Verify we have at least the animals we created
      expect(allPending.length, greaterThanOrEqualTo(2));
      
      // Check that animals are included
      final animalRecords = allPending.where((r) => r['type'] == 'Animal').toList();
      expect(animalRecords.length, greaterThanOrEqualTo(2));
      
      // Verify record structure
      final firstAnimal = animalRecords.first;
      expect(firstAnimal['type'], equals('Animal'));
      expect(firstAnimal['operation'], equals('CREATE'));
      expect(firstAnimal['name'], isNotNull);
      expect(firstAnimal['id'], isNotNull);
      expect(firstAnimal['created_at'], isNotNull);
      expect(firstAnimal['data'], isNotNull);
    });

    test('should handle PendingOperation enum correctly', () {
      // Test enum to string conversion
      expect(PendingOperation.create.value, equals('CREATE'));
      expect(PendingOperation.update.value, equals('UPDATE'));
      expect(PendingOperation.delete.value, equals('DELETE'));

      // Test string to enum conversion
      expect(PendingOperationExtension.fromString('CREATE'), equals(PendingOperation.create));
      expect(PendingOperationExtension.fromString('UPDATE'), equals(PendingOperation.update));
      expect(PendingOperationExtension.fromString('DELETE'), equals(PendingOperation.delete));
      expect(PendingOperationExtension.fromString('create'), equals(PendingOperation.create)); // Case insensitive
      expect(PendingOperationExtension.fromString('UNKNOWN'), equals(PendingOperation.create)); // Default case
    });

    test('should generate unique temporary IDs for offline animals', () async {
      // Save multiple pending animals quickly
      final futures = <Future<void>>[];
      for (int i = 0; i < 5; i++) {
        futures.add(
          DatabaseService.savePendingAnimalOffline(
            idRebano: 1,
            nombre: 'Test Animal $i',
            codigoAnimal: 'TEST-$i',
            sexo: i.isEven ? 'M' : 'F',
            fechaNacimiento: '2024-01-0${i + 1}',
            procedencia: 'Local',
            fkComposicionRaza: 1,
            estadoId: 1,
            etapaId: 1,
          ),
        );
      }

      await Future.wait(futures);

      // Get all pending animals
      final pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      expect(pendingAnimals.length, greaterThanOrEqualTo(5));

      // Check that all have unique negative IDs
      final ids = pendingAnimals.map((a) => a['id_animal'] as int).toList();
      final uniqueIds = ids.toSet();
      expect(uniqueIds.length, equals(ids.length)); // No duplicates
      
      // All should be negative (temporary IDs)
      for (final id in ids) {
        expect(id, lessThan(0));
      }
    });
  });
}