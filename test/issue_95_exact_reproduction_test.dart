import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// This test reproduces the exact scenario described in Issue #95
/// to verify that the fix resolves the problem.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Issue #95 Reproduction Test', () {
    test('exact scenario from issue: create offline → modify offline → sync should work', () async {
      // STEP 1: User creates an animal while offline
      print('🟡 Creating animal offline...');
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Test Animal Issue 95',
        codigoAnimal: 'ISSUE95-001',
        sexo: 'F',
        fechaNacimiento: '2023-05-15',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      // Verify it was created with CREATE operation
      final afterCreate = await DatabaseService.getPendingAnimalsOffline();
      expect(afterCreate, isNotEmpty);
      final createdAnimal = afterCreate.first;
      final animalId = createdAnimal['id_animal'] as int;
      
      print('✅ Animal created with ID: $animalId, operation: ${createdAnimal["pending_operation"]}');
      expect(createdAnimal['pending_operation'], equals('CREATE'));
      expect(createdAnimal['nombre'], equals('Test Animal Issue 95'));

      // STEP 2: User modifies the same animal while still offline
      print('🟡 Modifying same animal while still offline...');
      await DatabaseService.savePendingAnimalUpdateOffline(
        idAnimal: animalId,
        idRebano: 1,
        nombre: 'Modified Test Animal Issue 95', // Changed the name
        codigoAnimal: 'ISSUE95-001-MODIFIED',     // Changed the code
        sexo: 'F',
        fechaNacimiento: '2023-05-15',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      // STEP 3: Verify the operation is STILL CREATE (this is the fix!)
      final afterModify = await DatabaseService.getPendingAnimalsOffline();
      expect(afterModify, isNotEmpty);
      final modifiedAnimal = afterModify.firstWhere(
        (animal) => animal['id_animal'] == animalId,
      );

      print('✅ After modification: operation: ${modifiedAnimal["pending_operation"]}, name: ${modifiedAnimal["nombre"]}');
      
      // This is the KEY assertion - the operation should STILL be CREATE
      expect(modifiedAnimal['pending_operation'], equals('CREATE'),
        reason: 'Animal created offline should remain CREATE operation even after modification');
      
      // The data should be updated to the latest values
      expect(modifiedAnimal['nombre'], equals('Modified Test Animal Issue 95'));
      expect(modifiedAnimal['codigo_animal'], equals('ISSUE95-001-MODIFIED'));

      // STEP 4: Simulate what happens during sync
      print('🟡 Simulating sync process...');
      final allPending = await DatabaseService.getAllPendingRecords();
      final animalRecord = allPending.firstWhere(
        (record) => record['type'] == 'Animal' && record['name'] == 'Modified Test Animal Issue 95',
      );
      
      expect(animalRecord['operation'], equals('CREATE'),
        reason: 'When syncing, this should be treated as a CREATE operation');

      print('✅ Success! Sync will correctly CREATE the record with the modified data');
      print('🎉 Issue #95 scenario is now working correctly!');
    });

    test('demonstrates the original problem would have occurred', () async {
      // This test shows what WOULD have happened with the old implementation
      // by manually setting the operation to UPDATE after CREATE
      
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Problem Demo Animal',
        codigoAnimal: 'PROBLEM-001',
        sexo: 'M',
        fechaNacimiento: '2023-06-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      final animals = await DatabaseService.getPendingAnimalsOffline();
      final animalId = animals.first['id_animal'] as int;

      // Manually simulate what the OLD code would have done
      final db = await DatabaseService.database;
      await db.update(
        'animales',
        {'pending_operation': 'UPDATE'}, // Old behavior: always set to UPDATE
        where: 'id_animal = ?',
        whereArgs: [animalId],
      );

      final afterBadUpdate = await DatabaseService.getPendingAnimalsOffline();
      final problemAnimal = afterBadUpdate.firstWhere(
        (animal) => animal['id_animal'] == animalId,
      );

      print('❌ Old behavior would have: operation: ${problemAnimal["pending_operation"]}');
      expect(problemAnimal['pending_operation'], equals('UPDATE'));
      
      print('💥 This would cause sync failure: trying to UPDATE a record that doesn\'t exist on server yet!');
    });
  });
}