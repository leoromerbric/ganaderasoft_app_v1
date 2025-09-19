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

  group('Offline Update Functionality Tests', () {
    test('should save and retrieve pending animal updates offline', () async {
      // Create an animal first (simulate existing animal)
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Test Animal Original',
        codigoAnimal: 'TEST-001',
        sexo: 'M',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      // Get the created animal ID
      final pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      expect(pendingAnimals, isNotEmpty);
      final animalId = pendingAnimals.first['id_animal'] as int;

      // Mark it as synced to simulate a real animal from server
      await DatabaseService.markAnimalAsSynced(animalId, 100); // Real ID 100

      // Now update the animal offline
      await DatabaseService.savePendingAnimalUpdateOffline(
        idAnimal: 100,
        idRebano: 2,
        nombre: 'Test Animal Updated',
        codigoAnimal: 'TEST-001-UPDATED',
        sexo: 'F',
        fechaNacimiento: '2024-01-15',
        procedencia: 'External',
        fkComposicionRaza: 2,
        estadoId: 2,
        etapaId: 2,
      );

      // Verify the update was saved
      final pendingUpdates = await DatabaseService.getPendingAnimalsOffline();
      expect(pendingUpdates, isNotEmpty);
      
      final updatedAnimal = pendingUpdates.first;
      expect(updatedAnimal['id_animal'], equals(100));
      expect(updatedAnimal['nombre'], equals('Test Animal Updated'));
      expect(updatedAnimal['codigo_animal'], equals('TEST-001-UPDATED'));
      expect(updatedAnimal['sexo'], equals('F'));
      expect(updatedAnimal['id_rebano'], equals(2));
      expect(updatedAnimal['is_pending'], equals(1));
      expect(updatedAnimal['pending_operation'], equals('UPDATE'));
      expect(updatedAnimal['synced'], equals(0));
    });

    test('should save and retrieve pending personal finca creation offline', () async {
      // Save a pending personal finca
      await DatabaseService.savePendingPersonalFincaOffline(
        idFinca: 1,
        cedula: 12345678,
        nombre: 'Juan',
        apellido: 'Perez',
        telefono: '3001234567',
        correo: 'juan.perez@test.com',
        tipoTrabajador: 'Administrador',
      );

      // Retrieve pending personal finca
      final pendingPersonal = await DatabaseService.getPendingPersonalFincaOffline();
      expect(pendingPersonal, isNotEmpty);
      
      final savedPersonal = pendingPersonal.first;
      expect(savedPersonal['nombre'], equals('Juan'));
      expect(savedPersonal['apellido'], equals('Perez'));
      expect(savedPersonal['cedula'], equals(12345678));
      expect(savedPersonal['telefono'], equals('3001234567'));
      expect(savedPersonal['correo'], equals('juan.perez@test.com'));
      expect(savedPersonal['tipo_trabajador'], equals('Administrador'));
      expect(savedPersonal['is_pending'], equals(1));
      expect(savedPersonal['pending_operation'], equals('CREATE'));
      expect(savedPersonal['synced'], equals(0));
      
      // Temp ID should be negative
      final tempId = savedPersonal['id_tecnico'] as int;
      expect(tempId, lessThan(0));
    });

    test('should save and retrieve pending personal finca updates offline', () async {
      // Create a personal finca first (simulate existing personal)
      await DatabaseService.savePendingPersonalFincaOffline(
        idFinca: 1,
        cedula: 87654321,
        nombre: 'Maria',
        apellido: 'Garcia',
        telefono: '3007654321',
        correo: 'maria.garcia@test.com',
        tipoTrabajador: 'Veterinario',
      );

      // Get the created personal ID
      final pendingPersonal = await DatabaseService.getPendingPersonalFincaOffline();
      expect(pendingPersonal, isNotEmpty);
      final personalId = pendingPersonal.first['id_tecnico'] as int;

      // Mark it as synced to simulate a real personal from server
      await DatabaseService.markPersonalFincaAsSynced(personalId, 200); // Real ID 200

      // Now update the personal finca offline
      await DatabaseService.savePendingPersonalFincaUpdateOffline(
        idTecnico: 200,
        idFinca: 2,
        cedula: 11111111,
        nombre: 'Maria Updated',
        apellido: 'Garcia Updated',
        telefono: '3009999999',
        correo: 'maria.updated@test.com',
        tipoTrabajador: 'Tecnico',
      );

      // Verify the update was saved
      final pendingUpdates = await DatabaseService.getPendingPersonalFincaOffline();
      expect(pendingUpdates, isNotEmpty);
      
      final updatedPersonal = pendingUpdates.first;
      expect(updatedPersonal['id_tecnico'], equals(200));
      expect(updatedPersonal['nombre'], equals('Maria Updated'));
      expect(updatedPersonal['apellido'], equals('Garcia Updated'));
      expect(updatedPersonal['cedula'], equals(11111111));
      expect(updatedPersonal['telefono'], equals('3009999999'));
      expect(updatedPersonal['correo'], equals('maria.updated@test.com'));
      expect(updatedPersonal['tipo_trabajador'], equals('Tecnico'));
      expect(updatedPersonal['is_pending'], equals(1));
      expect(updatedPersonal['pending_operation'], equals('UPDATE'));
      expect(updatedPersonal['synced'], equals(0));
    });

    test('should include all pending records in getAllPendingRecords', () async {
      // Create multiple pending records
      
      // Animal creation
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Pending Animal',
        codigoAnimal: 'PEND-001',
        sexo: 'M',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      // Animal update (first create and sync, then update)
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Update Animal Original',
        codigoAnimal: 'UPD-001',
        sexo: 'M',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );
      
      final animals = await DatabaseService.getPendingAnimalsOffline();
      final updateAnimalId = animals.last['id_animal'] as int;
      await DatabaseService.markAnimalAsSynced(updateAnimalId, 300);
      
      await DatabaseService.savePendingAnimalUpdateOffline(
        idAnimal: 300,
        idRebano: 2,
        nombre: 'Update Animal Modified',
        codigoAnimal: 'UPD-001-MOD',
        sexo: 'F',
        fechaNacimiento: '2024-01-15',
        procedencia: 'External',
        fkComposicionRaza: 2,
        estadoId: 2,
        etapaId: 2,
      );

      // Personal finca creation
      await DatabaseService.savePendingPersonalFincaOffline(
        idFinca: 1,
        cedula: 55555555,
        nombre: 'Pending Personal',
        apellido: 'Test',
        telefono: '3005555555',
        correo: 'pending@test.com',
        tipoTrabajador: 'Operario',
      );

      // Personal finca update (first create and sync, then update)
      await DatabaseService.savePendingPersonalFincaOffline(
        idFinca: 1,
        cedula: 66666666,
        nombre: 'Update Personal Original',
        apellido: 'Test',
        telefono: '3006666666',
        correo: 'update@test.com',
        tipoTrabajador: 'Supervisor',
      );
      
      final personal = await DatabaseService.getPendingPersonalFincaOffline();
      final updatePersonalId = personal.last['id_tecnico'] as int;
      await DatabaseService.markPersonalFincaAsSynced(updatePersonalId, 400);
      
      await DatabaseService.savePendingPersonalFincaUpdateOffline(
        idTecnico: 400,
        idFinca: 2,
        cedula: 77777777,
        nombre: 'Update Personal Modified',
        apellido: 'Test Modified',
        telefono: '3007777777',
        correo: 'update.modified@test.com',
        tipoTrabajador: 'Vigilante',
      );

      // Get all pending records
      final allPending = await DatabaseService.getAllPendingRecords();

      // Should have 4 pending records: 1 animal create, 1 animal update, 1 personal create, 1 personal update
      expect(allPending.length, greaterThanOrEqualTo(4));

      // Verify we have different types and operations
      final animalRecords = allPending.where((r) => r['type'] == 'Animal').toList();
      final personalRecords = allPending.where((r) => r['type'] == 'PersonalFinca').toList();

      expect(animalRecords.length, greaterThanOrEqualTo(2));
      expect(personalRecords.length, greaterThanOrEqualTo(2));

      // Check for CREATE and UPDATE operations
      final createRecords = allPending.where((r) => r['operation'] == 'CREATE').toList();
      final updateRecords = allPending.where((r) => r['operation'] == 'UPDATE').toList();

      expect(createRecords.length, greaterThanOrEqualTo(2));
      expect(updateRecords.length, greaterThanOrEqualTo(2));
    });

    test('markPersonalFincaAsSynced should work correctly', () async {
      // Create a pending personal finca
      await DatabaseService.savePendingPersonalFincaOffline(
        idFinca: 1,
        cedula: 99999999,
        nombre: 'Sync Test',
        apellido: 'Personal',
        telefono: '3009999999',
        correo: 'sync@test.com',
        tipoTrabajador: 'Otro',
      );

      // Get the temp ID
      final pendingPersonal = await DatabaseService.getPendingPersonalFincaOffline();
      expect(pendingPersonal, isNotEmpty);
      final tempId = pendingPersonal.first['id_tecnico'] as int;
      expect(tempId, lessThan(0)); // Should be negative

      // Mark as synced with real ID
      const realId = 500;
      await DatabaseService.markPersonalFincaAsSynced(tempId, realId);

      // Verify it's no longer pending
      final stillPending = await DatabaseService.getPendingPersonalFincaOffline();
      final foundInPending = stillPending.any((p) => p['id_tecnico'] == realId);
      expect(foundInPending, isFalse);

      // Verify it's marked as synced in the database
      final db = await DatabaseService.database;
      final syncedRecords = await db.query(
        'personal_finca',
        where: 'id_tecnico = ? AND synced = ? AND is_pending = ?',
        whereArgs: [realId, 1, 0],
      );
      expect(syncedRecords, isNotEmpty);
      expect(syncedRecords.first['nombre'], equals('Sync Test'));
    });
  });
}