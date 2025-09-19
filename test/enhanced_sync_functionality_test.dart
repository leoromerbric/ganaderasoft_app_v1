import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Enhanced Sync Functionality Tests', () {
    test('should properly handle markAnimalUpdateAsSynced for UPDATE operations', () async {
      // Create an animal first and mark as synced
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
      final tempId = pendingAnimals.first['id_animal'] as int;
      
      // Mark as synced to simulate a real animal from server
      await DatabaseService.markAnimalAsSynced(tempId, 100);

      // Now update the animal offline
      await DatabaseService.savePendingAnimalUpdateOffline(
        idAnimal: 100,
        idRebano: 2,
        nombre: 'Updated Animal',
        codigoAnimal: 'TEST-001-UPD',
        sexo: 'F',
        fechaNacimiento: '2024-01-15',
        procedencia: 'External',
        fkComposicionRaza: 2,
        estadoId: 2,
        etapaId: 2,
      );

      // Verify the update is pending
      final pendingUpdates = await DatabaseService.getPendingAnimalsOffline();
      expect(pendingUpdates, isNotEmpty);
      expect(pendingUpdates.first['pending_operation'], equals('UPDATE'));

      // Mark the update as synced
      await DatabaseService.markAnimalUpdateAsSynced(100);

      // Verify the update is no longer pending
      final remainingPending = await DatabaseService.getPendingAnimalsOffline();
      final stillPending = remainingPending.any((a) => a['id_animal'] == 100);
      expect(stillPending, isFalse);
    });

    test('should properly handle markPersonalFincaUpdateAsSynced for UPDATE operations', () async {
      // Create a personal finca first and mark as synced
      await DatabaseService.savePendingPersonalFincaOffline(
        idFinca: 1,
        cedula: 12345678,
        nombre: 'Test Personal',
        apellido: 'Original',
        telefono: '3001234567',
        correo: 'test@original.com',
        tipoTrabajador: 'Administrador',
      );

      final pendingPersonal = await DatabaseService.getPendingPersonalFincaOffline();
      final tempId = pendingPersonal.first['id_tecnico'] as int;
      
      // Mark as synced to simulate real personal from server
      await DatabaseService.markPersonalFincaAsSynced(tempId, 200);

      // Now update the personal finca offline
      await DatabaseService.savePendingPersonalFincaUpdateOffline(
        idTecnico: 200,
        idFinca: 2,
        cedula: 87654321,
        nombre: 'Updated Personal',
        apellido: 'Modified',
        telefono: '3009876543',
        correo: 'updated@modified.com',
        tipoTrabajador: 'Supervisor',
      );

      // Verify the update is pending
      final pendingUpdates = await DatabaseService.getPendingPersonalFincaOffline();
      expect(pendingUpdates, isNotEmpty);
      expect(pendingUpdates.first['pending_operation'], equals('UPDATE'));

      // Mark the update as synced
      await DatabaseService.markPersonalFincaUpdateAsSynced(200);

      // Verify the update is no longer pending
      final remainingPending = await DatabaseService.getPendingPersonalFincaOffline();
      final stillPending = remainingPending.any((p) => p['id_tecnico'] == 200);
      expect(stillPending, isFalse);
    });

    test('should handle mixed CREATE and UPDATE operations in getAllPendingRecords', () async {
      // Create new animal offline (CREATE)
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'New Animal',
        codigoAnimal: 'NEW-001',
        sexo: 'M',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      // Create and sync an animal, then update (UPDATE)
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Existing Animal',
        codigoAnimal: 'EXIST-001',
        sexo: 'F',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      final animals = await DatabaseService.getPendingAnimalsOffline();
      final existingAnimalTempId = animals.last['id_animal'] as int;
      await DatabaseService.markAnimalAsSynced(existingAnimalTempId, 300);

      await DatabaseService.savePendingAnimalUpdateOffline(
        idAnimal: 300,
        idRebano: 2,
        nombre: 'Updated Existing Animal',
        codigoAnimal: 'EXIST-001-UPD',
        sexo: 'M',
        fechaNacimiento: '2024-01-15',
        procedencia: 'External',
        fkComposicionRaza: 2,
        estadoId: 2,
        etapaId: 2,
      );

      // Create new personal finca offline (CREATE)
      await DatabaseService.savePendingPersonalFincaOffline(
        idFinca: 1,
        cedula: 11111111,
        nombre: 'New Personal',
        apellido: 'Create',
        telefono: '3001111111',
        correo: 'new@create.com',
        tipoTrabajador: 'Operario',
      );

      // Create and sync personal finca, then update (UPDATE)
      await DatabaseService.savePendingPersonalFincaOffline(
        idFinca: 1,
        cedula: 22222222,
        nombre: 'Existing Personal',
        apellido: 'Update',
        telefono: '3002222222',
        correo: 'existing@update.com',
        tipoTrabajador: 'Tecnico',
      );

      final personal = await DatabaseService.getPendingPersonalFincaOffline();
      final existingPersonalTempId = personal.last['id_tecnico'] as int;
      await DatabaseService.markPersonalFincaAsSynced(existingPersonalTempId, 400);

      await DatabaseService.savePendingPersonalFincaUpdateOffline(
        idTecnico: 400,
        idFinca: 2,
        cedula: 33333333,
        nombre: 'Updated Existing Personal',
        apellido: 'Modified',
        telefono: '3003333333',
        correo: 'updated@existing.com',
        tipoTrabajador: 'Supervisor',
      );

      // Get all pending records
      final allPending = await DatabaseService.getAllPendingRecords();

      // Should have 4 pending operations
      expect(allPending.length, greaterThanOrEqualTo(4));

      // Filter by type and operation
      final animalCreates = allPending
          .where((r) => r['type'] == 'Animal' && r['operation'] == 'CREATE')
          .toList();
      final animalUpdates = allPending
          .where((r) => r['type'] == 'Animal' && r['operation'] == 'UPDATE')
          .toList();
      final personalCreates = allPending
          .where((r) => r['type'] == 'PersonalFinca' && r['operation'] == 'CREATE')
          .toList();
      final personalUpdates = allPending
          .where((r) => r['type'] == 'PersonalFinca' && r['operation'] == 'UPDATE')
          .toList();

      expect(animalCreates.length, greaterThanOrEqualTo(1));
      expect(animalUpdates.length, greaterThanOrEqualTo(1));
      expect(personalCreates.length, greaterThanOrEqualTo(1));
      expect(personalUpdates.length, greaterThanOrEqualTo(1));

      // Verify CREATE operations have negative IDs for new records
      for (final create in animalCreates) {
        if (create['name'] == 'New Animal') {
          expect(create['id'] as int, lessThan(0));
        }
      }

      for (final create in personalCreates) {
        if (create['name'] == 'New Personal Create') {
          expect(create['id'] as int, lessThan(0));
        }
      }

      // Verify UPDATE operations have positive IDs for existing records
      for (final update in animalUpdates) {
        expect(update['id'] as int, greaterThan(0));
      }

      for (final update in personalUpdates) {
        expect(update['id'] as int, greaterThan(0));
      }
    });

    test('should properly track different pending operation types', () async {
      // Test that the database correctly stores and retrieves operation types

      // Animal CREATE
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Create Test Animal',
        codigoAnimal: 'CREATE-001',
        sexo: 'M',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      // Animal UPDATE
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Update Test Animal Original',
        codigoAnimal: 'UPDATE-001',
        sexo: 'F',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      final animals = await DatabaseService.getPendingAnimalsOffline();
      final updateAnimalTempId = animals.last['id_animal'] as int;
      await DatabaseService.markAnimalAsSynced(updateAnimalTempId, 500);

      await DatabaseService.savePendingAnimalUpdateOffline(
        idAnimal: 500,
        idRebano: 2,
        nombre: 'Update Test Animal Modified',
        codigoAnimal: 'UPDATE-001-MOD',
        sexo: 'M',
        fechaNacimiento: '2024-01-15',
        procedencia: 'External',
        fkComposicionRaza: 2,
        estadoId: 2,
        etapaId: 2,
      );

      // Personal Finca CREATE
      await DatabaseService.savePendingPersonalFincaOffline(
        idFinca: 1,
        cedula: 44444444,
        nombre: 'Create Test Personal',
        apellido: 'Test',
        telefono: '3004444444',
        correo: 'create@test.com',
        tipoTrabajador: 'Vigilante',
      );

      // Personal Finca UPDATE
      await DatabaseService.savePendingPersonalFincaOffline(
        idFinca: 1,
        cedula: 55555555,
        nombre: 'Update Test Personal Original',
        apellido: 'Test',
        telefono: '3005555555',
        correo: 'update@test.com',
        tipoTrabajador: 'Operario',
      );

      final personal = await DatabaseService.getPendingPersonalFincaOffline();
      final updatePersonalTempId = personal.last['id_tecnico'] as int;
      await DatabaseService.markPersonalFincaAsSynced(updatePersonalTempId, 600);

      await DatabaseService.savePendingPersonalFincaUpdateOffline(
        idTecnico: 600,
        idFinca: 2,
        cedula: 66666666,
        nombre: 'Update Test Personal Modified',
        apellido: 'Modified',
        telefono: '3006666666',
        correo: 'update.modified@test.com',
        tipoTrabajador: 'Supervisor',
      );

      // Verify all operations are tracked correctly
      final allPending = await DatabaseService.getAllPendingRecords();
      
      final createOperations = allPending.where((r) => r['operation'] == 'CREATE').toList();
      final updateOperations = allPending.where((r) => r['operation'] == 'UPDATE').toList();

      expect(createOperations.length, greaterThanOrEqualTo(2)); // At least 1 animal + 1 personal
      expect(updateOperations.length, greaterThanOrEqualTo(2)); // At least 1 animal + 1 personal

      // Verify operations have correct data
      for (final create in createOperations) {
        expect(create['operation'], equals('CREATE'));
        final data = create['data'] as Map<String, dynamic>;
        expect(data['is_pending'], equals(1));
        expect(data['synced'], equals(0));
        expect(data['pending_operation'], equals('CREATE'));
      }

      for (final update in updateOperations) {
        expect(update['operation'], equals('UPDATE'));
        final data = update['data'] as Map<String, dynamic>;
        expect(data['is_pending'], equals(1));
        expect(data['synced'], equals(0));
        expect(data['pending_operation'], equals('UPDATE'));
      }
    });
  });
}