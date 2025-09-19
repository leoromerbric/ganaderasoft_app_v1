import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Complete Offline Workflow Integration Tests', () {
    test('complete offline workflow: create, edit, sync for animals and personal finca', () async {
      print('=== Testing Complete Offline Workflow ===');

      // PHASE 1: Create records offline
      print('\n--- Phase 1: Creating records offline ---');

      // Create animal offline
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Vaca Offline',
        codigoAnimal: 'OFF-001',
        sexo: 'F',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      // Create personal finca offline
      await DatabaseService.savePendingPersonalFincaOffline(
        idFinca: 1,
        cedula: 12345678,
        nombre: 'Juan',
        apellido: 'Trabajador',
        telefono: '3001234567',
        correo: 'juan@offline.com',
        tipoTrabajador: 'Operario',
      );

      print('✓ Animal and personal finca created offline');

      // Verify pending records
      var allPending = await DatabaseService.getAllPendingRecords();
      var createRecords = allPending.where((r) => r['operation'] == 'CREATE').toList();
      expect(createRecords.length, greaterThanOrEqualTo(2));
      print('✓ Verified ${createRecords.length} CREATE operations pending');

      // PHASE 2: Simulate sync of created records
      print('\n--- Phase 2: Simulating sync of created records ---');

      final pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      final pendingPersonal = await DatabaseService.getPendingPersonalFincaOffline();

      // Simulate animal creation on server
      final animalTempId = pendingAnimals.first['id_animal'] as int;
      const animalRealId = 100;
      await DatabaseService.markAnimalAsSynced(animalTempId, animalRealId);
      print('✓ Animal synced: temp ID $animalTempId -> real ID $animalRealId');

      // Simulate personal finca creation on server
      final personalTempId = pendingPersonal.first['id_tecnico'] as int;
      const personalRealId = 200;
      await DatabaseService.markPersonalFincaAsSynced(personalTempId, personalRealId);
      print('✓ Personal finca synced: temp ID $personalTempId -> real ID $personalRealId');

      // Verify no more CREATE operations pending
      allPending = await DatabaseService.getAllPendingRecords();
      createRecords = allPending.where((r) => r['operation'] == 'CREATE').toList();
      expect(createRecords.length, equals(0));
      print('✓ No CREATE operations pending after sync');

      // PHASE 3: Edit records offline (UPDATE operations)
      print('\n--- Phase 3: Editing records offline ---');

      // Update animal offline
      await DatabaseService.savePendingAnimalUpdateOffline(
        idAnimal: animalRealId,
        idRebano: 2,
        nombre: 'Vaca Editada Offline',
        codigoAnimal: 'OFF-001-EDIT',
        sexo: 'F',
        fechaNacimiento: '2024-01-15',
        procedencia: 'External',
        fkComposicionRaza: 2,
        estadoId: 2,
        etapaId: 2,
      );

      // Update personal finca offline
      await DatabaseService.savePendingPersonalFincaUpdateOffline(
        idTecnico: personalRealId,
        idFinca: 2,
        cedula: 87654321,
        nombre: 'Juan Editado',
        apellido: 'Trabajador Modificado',
        telefono: '3009876543',
        correo: 'juan.editado@offline.com',
        tipoTrabajador: 'Supervisor',
      );

      print('✓ Animal and personal finca edited offline');

      // Verify UPDATE operations are pending
      allPending = await DatabaseService.getAllPendingRecords();
      final updateRecords = allPending.where((r) => r['operation'] == 'UPDATE').toList();
      expect(updateRecords.length, greaterThanOrEqualTo(2));
      print('✓ Verified ${updateRecords.length} UPDATE operations pending');

      // PHASE 4: Simulate sync of updated records
      print('\n--- Phase 4: Simulating sync of updated records ---');

      // Simulate animal update on server
      await DatabaseService.markAnimalUpdateAsSynced(animalRealId);
      print('✓ Animal update synced for ID $animalRealId');

      // Simulate personal finca update on server
      await DatabaseService.markPersonalFincaUpdateAsSynced(personalRealId);
      print('✓ Personal finca update synced for ID $personalRealId');

      // Verify no more UPDATE operations pending
      allPending = await DatabaseService.getAllPendingRecords();
      final remainingUpdateRecords = allPending.where((r) => r['operation'] == 'UPDATE').toList();
      expect(remainingUpdateRecords.length, equals(0));
      print('✓ No UPDATE operations pending after sync');

      // PHASE 5: Final verification
      print('\n--- Phase 5: Final verification ---');

      // Verify all operations are synced
      allPending = await DatabaseService.getAllPendingRecords();
      expect(allPending.length, equals(0));
      print('✓ No pending operations remaining');

      // Verify final data state in database
      final db = await DatabaseService.database;
      
      // Check animal final state
      final animalRecords = await db.query(
        'animales',
        where: 'id_animal = ?',
        whereArgs: [animalRealId],
      );
      expect(animalRecords, isNotEmpty);
      final finalAnimal = animalRecords.first;
      expect(finalAnimal['nombre'], equals('Vaca Editada Offline'));
      expect(finalAnimal['codigo_animal'], equals('OFF-001-EDIT'));
      expect(finalAnimal['synced'], equals(1));
      expect(finalAnimal['is_pending'], equals(0));
      print('✓ Animal final state verified: ${finalAnimal['nombre']}');

      // Check personal finca final state
      final personalRecords = await db.query(
        'personal_finca',
        where: 'id_tecnico = ?',
        whereArgs: [personalRealId],
      );
      expect(personalRecords, isNotEmpty);
      final finalPersonal = personalRecords.first;
      expect(finalPersonal['nombre'], equals('Juan Editado'));
      expect(finalPersonal['apellido'], equals('Trabajador Modificado'));
      expect(finalPersonal['synced'], equals(1));
      expect(finalPersonal['is_pending'], equals(0));
      print('✓ Personal finca final state verified: ${finalPersonal['nombre']} ${finalPersonal['apellido']}');

      print('\n=== Complete Offline Workflow Test PASSED ===');
    });

    test('multiple offline operations with mixed CREATE and UPDATE', () async {
      print('\n=== Testing Multiple Mixed Operations ===');

      // Create multiple animals offline
      final animalData = [
        {'nombre': 'Animal A', 'codigo': 'A-001'},
        {'nombre': 'Animal B', 'codigo': 'B-001'},
        {'nombre': 'Animal C', 'codigo': 'C-001'},
      ];

      for (final animal in animalData) {
        await DatabaseService.savePendingAnimalOffline(
          idRebano: 1,
          nombre: animal['nombre']!,
          codigoAnimal: animal['codigo']!,
          sexo: 'M',
          fechaNacimiento: '2024-01-01',
          procedencia: 'Local',
          fkComposicionRaza: 1,
          estadoId: 1,
          etapaId: 1,
        );
      }

      // Create multiple personal finca offline
      final personalData = [
        {'nombre': 'Personal A', 'apellido': 'Apellido A', 'cedula': 11111111},
        {'nombre': 'Personal B', 'apellido': 'Apellido B', 'cedula': 22222222},
        {'nombre': 'Personal C', 'apellido': 'Apellido C', 'cedula': 33333333},
      ];

      for (final personal in personalData) {
        await DatabaseService.savePendingPersonalFincaOffline(
          idFinca: 1,
          cedula: personal['cedula'] as int,
          nombre: personal['nombre']!,
          apellido: personal['apellido']!,
          telefono: '300${personal['cedula']}',
          correo: '${personal['nombre']!.toLowerCase()}@test.com',
          tipoTrabajador: 'Operario',
        );
      }

      print('✓ Created 3 animals and 3 personal finca offline');

      // Sync half of them and update the synced ones
      final pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      final pendingPersonal = await DatabaseService.getPendingPersonalFincaOffline();

      // Sync first animal and update it
      final firstAnimalTempId = pendingAnimals[0]['id_animal'] as int;
      await DatabaseService.markAnimalAsSynced(firstAnimalTempId, 1001);
      await DatabaseService.savePendingAnimalUpdateOffline(
        idAnimal: 1001,
        idRebano: 2,
        nombre: 'Animal A Updated',
        codigoAnimal: 'A-001-UPD',
        sexo: 'F',
        fechaNacimiento: '2024-01-15',
        procedencia: 'External',
        fkComposicionRaza: 2,
        estadoId: 2,
        etapaId: 2,
      );

      // Sync first personal and update it
      final firstPersonalTempId = pendingPersonal[0]['id_tecnico'] as int;
      await DatabaseService.markPersonalFincaAsSynced(firstPersonalTempId, 2001);
      await DatabaseService.savePendingPersonalFincaUpdateOffline(
        idTecnico: 2001,
        idFinca: 2,
        cedula: 99999999,
        nombre: 'Personal A Updated',
        apellido: 'Apellido A Modified',
        telefono: '3009999999',
        correo: 'personal.a.updated@test.com',
        tipoTrabajador: 'Supervisor',
      );

      print('✓ Synced and updated first animal and personal finca');

      // Verify mixed operations
      final allPending = await DatabaseService.getAllPendingRecords();
      final creates = allPending.where((r) => r['operation'] == 'CREATE').toList();
      final updates = allPending.where((r) => r['operation'] == 'UPDATE').toList();

      // Should have: 2 animal CREATEs + 2 personal CREATEs + 1 animal UPDATE + 1 personal UPDATE = 6 total
      expect(creates.length, equals(4)); // 2 animals + 2 personal remaining
      expect(updates.length, equals(2)); // 1 animal + 1 personal updated
      expect(allPending.length, equals(6));

      print('✓ Verified mixed operations: ${creates.length} CREATEs, ${updates.length} UPDATEs');

      // Verify operation distribution by type
      final animalRecords = allPending.where((r) => r['type'] == 'Animal').toList();
      final personalRecords = allPending.where((r) => r['type'] == 'PersonalFinca').toList();

      expect(animalRecords.length, equals(3)); // 2 CREATEs + 1 UPDATE
      expect(personalRecords.length, equals(3)); // 2 CREATEs + 1 UPDATE

      print('✓ Verified type distribution: ${animalRecords.length} Animal, ${personalRecords.length} PersonalFinca');

      print('=== Multiple Mixed Operations Test PASSED ===');
    });

    test('error scenarios and edge cases', () async {
      print('\n=== Testing Error Scenarios and Edge Cases ===');

      // Test updating non-existent record
      bool errorCaught = false;
      try {
        await DatabaseService.markAnimalUpdateAsSynced(99999);
      } catch (e) {
        errorCaught = true;
        expect(e.toString(), contains('not found or already synced'));
      }
      expect(errorCaught, isTrue);
      print('✓ Correctly handled attempt to sync non-existent animal');

      // Test updating non-existent personal finca
      errorCaught = false;
      try {
        await DatabaseService.markPersonalFincaUpdateAsSynced(99999);
      } catch (e) {
        errorCaught = true;
        expect(e.toString(), contains('not found or already synced'));
      }
      expect(errorCaught, isTrue);
      print('✓ Correctly handled attempt to sync non-existent personal finca');

      // Test double sync prevention
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Double Sync Test',
        codigoAnimal: 'DBL-001',
        sexo: 'M',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      final animals = await DatabaseService.getPendingAnimalsOffline();
      final tempId = animals.first['id_animal'] as int;
      
      // First sync should succeed
      await DatabaseService.markAnimalAsSynced(tempId, 5000);
      
      // Second sync should fail
      errorCaught = false;
      try {
        await DatabaseService.markAnimalAsSynced(tempId, 5001);
      } catch (e) {
        errorCaught = true;
      }
      expect(errorCaught, isTrue);
      print('✓ Correctly prevented double sync of same record');

      print('=== Error Scenarios Test PASSED ===');
    });
  });
}