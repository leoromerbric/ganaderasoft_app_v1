import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Offline Record Modification Tests', () {
    test('animal created and modified offline should remain CREATE operation', () async {
      // Step 1: Create an animal offline (this sets pending_operation = 'CREATE')
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Test Animal',
        codigoAnimal: 'TEST-001',
        sexo: 'F',
        fechaNacimiento: '2023-05-15',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      // Step 2: Verify it was saved with CREATE operation
      final pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      expect(pendingAnimals, isNotEmpty);
      
      final createdAnimal = pendingAnimals.first;
      final animalId = createdAnimal['id_animal'] as int;
      expect(createdAnimal['pending_operation'], equals('CREATE'));
      expect(createdAnimal['nombre'], equals('Test Animal'));
      expect(animalId, lessThan(0)); // Temporary negative ID

      // Step 3: Modify the animal while still offline
      // ISSUE: This currently changes pending_operation to 'UPDATE' 
      // but it should remain 'CREATE' since the record was originally created offline
      await DatabaseService.savePendingAnimalUpdateOffline(
        idAnimal: animalId,
        idRebano: 1,
        nombre: 'Modified Test Animal', // Changed name
        codigoAnimal: 'TEST-001-MOD',   // Changed code
        sexo: 'F',
        fechaNacimiento: '2023-05-15',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      // Step 4: Verify the operation is still CREATE (this is what should happen)
      final updatedPendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      expect(updatedPendingAnimals, isNotEmpty);
      
      final modifiedAnimal = updatedPendingAnimals.firstWhere(
        (animal) => animal['id_animal'] == animalId,
      );
      
      // The data should be updated
      expect(modifiedAnimal['nombre'], equals('Modified Test Animal'));
      expect(modifiedAnimal['codigo_animal'], equals('TEST-001-MOD'));
      
      // BUT the operation should still be CREATE, not UPDATE
      // This will fail with current implementation but should pass after fix
      expect(modifiedAnimal['pending_operation'], equals('CREATE'),
        reason: 'Record created offline should remain CREATE operation even after modification');
    });

    test('personal finca created and modified offline should remain CREATE operation', () async {
      // Step 1: Create a personal finca offline
      await DatabaseService.savePendingPersonalFincaOffline(
        idFinca: 1,
        cedula: 12345678,
        nombre: 'Test Personal',
        apellido: 'Test Apellido',
        telefono: '3001234567',
        correo: 'test@test.com',
        tipoTrabajador: 'Tecnico',
      );

      // Step 2: Verify it was saved with CREATE operation
      final pendingPersonal = await DatabaseService.getPendingPersonalFincaOffline();
      expect(pendingPersonal, isNotEmpty);
      
      final createdPersonal = pendingPersonal.first;
      final personalId = createdPersonal['id_tecnico'] as int;
      expect(createdPersonal['pending_operation'], equals('CREATE'));
      expect(createdPersonal['nombre'], equals('Test Personal'));
      expect(personalId, lessThan(0)); // Temporary negative ID

      // Step 3: Modify the personal finca while still offline
      await DatabaseService.savePendingPersonalFincaUpdateOffline(
        idTecnico: personalId,
        idFinca: 1,
        cedula: 12345678,
        nombre: 'Modified Test Personal', // Changed name
        apellido: 'Modified Apellido',    // Changed apellido
        telefono: '3009876543',           // Changed phone
        correo: 'modified@test.com',      // Changed email
        tipoTrabajador: 'Supervisor',     // Changed type
      );

      // Step 4: Verify the operation is still CREATE
      final updatedPendingPersonal = await DatabaseService.getPendingPersonalFincaOffline();
      expect(updatedPendingPersonal, isNotEmpty);
      
      final modifiedPersonal = updatedPendingPersonal.firstWhere(
        (personal) => personal['id_tecnico'] == personalId,
      );
      
      // The data should be updated
      expect(modifiedPersonal['nombre'], equals('Modified Test Personal'));
      expect(modifiedPersonal['apellido'], equals('Modified Apellido'));
      expect(modifiedPersonal['telefono'], equals('3009876543'));
      expect(modifiedPersonal['correo'], equals('modified@test.com'));
      expect(modifiedPersonal['tipo_trabajador'], equals('Supervisor'));
      
      // BUT the operation should still be CREATE, not UPDATE
      expect(modifiedPersonal['pending_operation'], equals('CREATE'),
        reason: 'Personal finca created offline should remain CREATE operation even after modification');
    });

    test('existing synced record modified offline should use UPDATE operation', () async {
      // This test ensures our fix doesn't break the normal update flow
      // for records that were already synced to the server
      
      // Step 1: Simulate an existing synced animal
      final db = await DatabaseService.database;
      const existingAnimalId = 100; // Positive ID indicates server record
      
      await db.insert('animales', {
        'id_animal': existingAnimalId,
        'id_rebano': 1,
        'nombre': 'Existing Animal',
        'codigo_animal': 'EXIST-001',
        'sexo': 'M',
        'fecha_nacimiento': '2023-01-01',
        'procedencia': 'External',
        'archivado': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'fk_composicion_raza': 1,
        'rebano_data': null,
        'composicion_raza_data': null,
        'synced': 1, // Already synced
        'is_pending': 0,
        'pending_operation': null, // No pending operation initially
        'estado_id': 1,
        'etapa_id': 1,
        'local_updated_at': DateTime.now().millisecondsSinceEpoch,
        'modifiedOffline': 0,
      });

      // Step 2: Modify this existing synced record offline
      await DatabaseService.savePendingAnimalUpdateOffline(
        idAnimal: existingAnimalId,
        idRebano: 1,
        nombre: 'Modified Existing Animal',
        codigoAnimal: 'EXIST-001-MOD',
        sexo: 'M',
        fechaNacimiento: '2023-01-01',
        procedencia: 'External',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      // Step 3: Verify this gets UPDATE operation (since it was originally synced)
      final pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      final modifiedExisting = pendingAnimals.firstWhere(
        (animal) => animal['id_animal'] == existingAnimalId,
      );
      
      expect(modifiedExisting['pending_operation'], equals('UPDATE'),
        reason: 'Previously synced records should use UPDATE operation when modified offline');
      expect(modifiedExisting['nombre'], equals('Modified Existing Animal'));
    });

    test('record with existing UPDATE operation should remain UPDATE', () async {
      // This test ensures that if a record already has UPDATE operation,
      // subsequent modifications don't change it to CREATE
      
      final db = await DatabaseService.database;
      const existingAnimalId = 200; // Positive ID
      
      // Step 1: Create a record that's already marked for UPDATE
      await db.insert('animales', {
        'id_animal': existingAnimalId,
        'id_rebano': 1,
        'nombre': 'Update Animal',
        'codigo_animal': 'UPD-001',
        'sexo': 'F',
        'fecha_nacimiento': '2023-02-01',
        'procedencia': 'External',
        'archivado': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'fk_composicion_raza': 1,
        'rebano_data': null,
        'composicion_raza_data': null,
        'synced': 0,
        'is_pending': 1,
        'pending_operation': 'UPDATE', // Already marked for UPDATE
        'estado_id': 1,
        'etapa_id': 1,
        'local_updated_at': DateTime.now().millisecondsSinceEpoch,
        'modifiedOffline': 1,
      });

      // Step 2: Modify it again
      await DatabaseService.savePendingAnimalUpdateOffline(
        idAnimal: existingAnimalId,
        idRebano: 1,
        nombre: 'Double Modified Update Animal',
        codigoAnimal: 'UPD-001-MOD',
        sexo: 'F',
        fechaNacimiento: '2023-02-01',
        procedencia: 'External',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      // Step 3: Verify it's still UPDATE
      final pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      final modifiedUpdate = pendingAnimals.firstWhere(
        (animal) => animal['id_animal'] == existingAnimalId,
      );
      
      expect(modifiedUpdate['pending_operation'], equals('UPDATE'),
        reason: 'Records already marked UPDATE should remain UPDATE');
      expect(modifiedUpdate['nombre'], equals('Double Modified Update Animal'));
    });
  });
}