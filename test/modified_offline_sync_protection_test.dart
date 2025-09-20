import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:ganaderasoft_app_v1/models/animal.dart';
import 'package:ganaderasoft_app_v1/models/finca.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('ModifiedOffline Sync Protection Tests', () {
    test('should not overwrite animals modified offline during sync', () async {
      // 1. Create an animal offline
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Original Animal',
        codigoAnimal: 'PROTECT-001',
        sexo: 'M',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      final db = await DatabaseService.database;
      
      // 2. Simulate syncing - give it a real server ID
      final tempResult = await db.query(
        'animales',
        where: 'codigo_animal = ?',
        whereArgs: ['PROTECT-001'],
      );
      final tempId = tempResult.first['id_animal'] as int;
      await DatabaseService.markAnimalAsSynced(tempId, 500);

      // 3. Modify the animal offline
      await DatabaseService.savePendingAnimalUpdateOffline(
        idAnimal: 500,
        idRebano: 2,
        nombre: 'Modified Offline Animal',
        codigoAnimal: 'PROTECT-001-MODIFIED',
        sexo: 'F',
        fechaNacimiento: '2024-01-15',
        procedencia: 'External',
        fkComposicionRaza: 2,
        estadoId: 2,
        etapaId: 2,
      );

      // Verify the animal is marked as modified offline
      final modifiedResult = await db.query(
        'animales',
        where: 'id_animal = ?',
        whereArgs: [500],
      );
      expect(modifiedResult.first['modifiedOffline'], equals(1));
      expect(modifiedResult.first['nombre'], equals('Modified Offline Animal'));

      // 4. Now simulate a sync from server with different data
      final serverAnimal = Animal(
        idAnimal: 500,
        idRebano: 3,
        nombre: 'Server Updated Animal',
        codigoAnimal: 'PROTECT-001-SERVER',
        sexo: 'M',
        fechaNacimiento: '2024-02-01',
        procedencia: 'Server',
        archivado: false,
        createdAt: '2024-01-01T00:00:00Z',
        updatedAt: '2024-02-01T00:00:00Z',
        fkComposicionRaza: 3,
      );

      // This should NOT overwrite the offline-modified animal
      await DatabaseService.saveAnimalesOffline([serverAnimal]);

      // 5. Verify the offline modification was preserved
      final finalResult = await db.query(
        'animales',
        where: 'id_animal = ?',
        whereArgs: [500],
      );

      expect(finalResult, isNotEmpty);
      expect(finalResult.first['modifiedOffline'], equals(1));
      expect(finalResult.first['nombre'], equals('Modified Offline Animal'), 
             reason: 'Offline modified animal should not be overwritten by server data');
      expect(finalResult.first['codigo_animal'], equals('PROTECT-001-MODIFIED'));
      expect(finalResult.first['sexo'], equals('F'));
      
      print('✓ Offline modified animal was protected from server overwrite');
    });

    test('should not overwrite fincas modified offline during sync', () async {
      // This test simulates a finca that was modified offline and should not be overwritten
      
      final db = await DatabaseService.database;
      
      // 1. Insert a finca that simulates one modified offline
      await db.insert('fincas', {
        'id_finca': 600,
        'id_propietario': 1,
        'nombre': 'Finca Modified Offline',
        'explotacion_tipo': 'Bovinos',
        'archivado': 0,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-15T00:00:00Z',
        'propietario_data': null,
        'local_updated_at': DateTime.now().millisecondsSinceEpoch,
        'modifiedOffline': 1, // Mark as modified offline
      });

      // 2. Create server finca data that would normally overwrite
      final serverFinca = Finca(
        idFinca: 600,
        idPropietario: 1,
        nombre: 'Server Finca Name',
        explotacionTipo: 'Caprinos',
        archivado: false,
        createdAt: '2024-01-01T00:00:00Z',
        updatedAt: '2024-02-01T00:00:00Z',
      );

      // 3. Try to save server fincas (this should skip the offline-modified one)
      await DatabaseService.saveFincasOffline([serverFinca]);

      // 4. Verify the offline modification was preserved
      final result = await db.query(
        'fincas',
        where: 'id_finca = ?',
        whereArgs: [600],
      );

      expect(result, isNotEmpty);
      expect(result.first['modifiedOffline'], equals(1));
      expect(result.first['nombre'], equals('Finca Modified Offline'),
             reason: 'Offline modified finca should not be overwritten by server data');
      expect(result.first['explotacion_tipo'], equals('Bovinos'));
      
      print('✓ Offline modified finca was protected from server overwrite');
    });

    test('should allow overwriting non-modified records during sync', () async {
      // This test ensures that normal (non-offline-modified) records can still be updated
      
      final db = await DatabaseService.database;
      
      // 1. Insert a normal animal (not modified offline)
      await db.insert('animales', {
        'id_animal': 700,
        'id_rebano': 1,
        'nombre': 'Normal Animal',
        'codigo_animal': 'NORMAL-001',
        'sexo': 'M',
        'fecha_nacimiento': '2024-01-01',
        'procedencia': 'Local',
        'archivado': 0,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
        'fk_composicion_raza': 1,
        'rebano_data': null,
        'composicion_raza_data': null,
        'synced': 1,
        'is_pending': 0,
        'pending_operation': null,
        'estado_id': 1,
        'etapa_id': 1,
        'local_updated_at': DateTime.now().millisecondsSinceEpoch,
        'modifiedOffline': 0, // NOT modified offline
      });

      // 2. Create server animal data that should overwrite
      final serverAnimal = Animal(
        idAnimal: 700,
        idRebano: 2,
        nombre: 'Updated From Server',
        codigoAnimal: 'NORMAL-001-UPDATED',
        sexo: 'F',
        fechaNacimiento: '2024-01-15',
        procedencia: 'Server',
        archivado: false,
        createdAt: '2024-01-01T00:00:00Z',
        updatedAt: '2024-02-01T00:00:00Z',
        fkComposicionRaza: 2,
      );

      // 3. Save server animal (this should overwrite the non-modified one)
      await DatabaseService.saveAnimalesOffline([serverAnimal]);

      // 4. Verify the record was updated with server data
      final result = await db.query(
        'animales',
        where: 'id_animal = ?',
        whereArgs: [700],
      );

      expect(result, isNotEmpty);
      expect(result.first['modifiedOffline'], equals(0)); // Should be set to 0 for server data
      expect(result.first['nombre'], equals('Updated From Server'),
             reason: 'Non-modified animal should be updated with server data');
      expect(result.first['sexo'], equals('F'));
      expect(result.first['codigo_animal'], equals('NORMAL-001-UPDATED'));
      
      print('✓ Non-modified animal was successfully updated from server');
    });

    test('should handle mixed scenarios with some modified and some normal records', () async {
      final db = await DatabaseService.database;
      
      // Setup: Create two animals - one modified offline, one normal
      await db.insert('animales', {
        'id_animal': 800,
        'id_rebano': 1,
        'nombre': 'Modified Animal',
        'codigo_animal': 'MIXED-001',
        'sexo': 'M',
        'fecha_nacimiento': '2024-01-01',
        'procedencia': 'Local',
        'archivado': 0,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
        'fk_composicion_raza': 1,
        'rebano_data': null,
        'composicion_raza_data': null,
        'synced': 0,
        'is_pending': 1,
        'pending_operation': 'UPDATE',
        'estado_id': 1,
        'etapa_id': 1,
        'local_updated_at': DateTime.now().millisecondsSinceEpoch,
        'modifiedOffline': 1, // Modified offline
      });

      await db.insert('animales', {
        'id_animal': 801,
        'id_rebano': 1,
        'nombre': 'Normal Animal',
        'codigo_animal': 'MIXED-002',
        'sexo': 'F',
        'fecha_nacimiento': '2024-01-01',
        'procedencia': 'Local',
        'archivado': 0,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
        'fk_composicion_raza': 1,
        'rebano_data': null,
        'composicion_raza_data': null,
        'synced': 1,
        'is_pending': 0,
        'pending_operation': null,
        'estado_id': 1,
        'etapa_id': 1,
        'local_updated_at': DateTime.now().millisecondsSinceEpoch,
        'modifiedOffline': 0, // Not modified offline
      });

      // Create server data for both
      final serverAnimals = [
        Animal(
          idAnimal: 800,
          idRebano: 2,
          nombre: 'Server Update 1',
          codigoAnimal: 'MIXED-001-SERVER',
          sexo: 'F',
          fechaNacimiento: '2024-02-01',
          procedencia: 'Server',
          archivado: false,
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-02-01T00:00:00Z',
          fkComposicionRaza: 2,
        ),
        Animal(
          idAnimal: 801,
          idRebano: 2,
          nombre: 'Server Update 2',
          codigoAnimal: 'MIXED-002-SERVER',
          sexo: 'M',
          fechaNacimiento: '2024-02-01',
          procedencia: 'Server',
          archivado: false,
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-02-01T00:00:00Z',
          fkComposicionRaza: 2,
        ),
      ];

      // Sync server data
      await DatabaseService.saveAnimalesOffline(serverAnimals);

      // Verify results
      final modifiedResult = await db.query(
        'animales',
        where: 'id_animal = ?',
        whereArgs: [800],
      );
      final normalResult = await db.query(
        'animales',
        where: 'id_animal = ?',
        whereArgs: [801],
      );

      // Modified offline should be preserved
      expect(modifiedResult.first['modifiedOffline'], equals(1));
      expect(modifiedResult.first['nombre'], equals('Modified Animal'));
      expect(modifiedResult.first['codigo_animal'], equals('MIXED-001'));

      // Normal should be updated
      expect(normalResult.first['modifiedOffline'], equals(0));
      expect(normalResult.first['nombre'], equals('Server Update 2'));
      expect(normalResult.first['codigo_animal'], equals('MIXED-002-SERVER'));
      
      print('✓ Mixed scenario handled correctly - protected offline modified, updated normal');
    });

    test('should reset modifiedOffline flag after successful sync', () async {
      // Test that modifiedOffline flag is reset to 0 after successful sync
      
      // 1. Create an animal offline
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Animal To Sync',
        codigoAnimal: 'SYNC-001',
        sexo: 'M',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      final db = await DatabaseService.database;
      
      // Verify it's marked as modified offline
      final tempResult = await db.query(
        'animales',
        where: 'codigo_animal = ?',
        whereArgs: ['SYNC-001'],
      );
      expect(tempResult.first['modifiedOffline'], equals(1));
      
      final tempId = tempResult.first['id_animal'] as int;
      
      // 2. Mark as synced (simulate successful sync to server)
      await DatabaseService.markAnimalAsSynced(tempId, 999);
      
      // 3. Verify modifiedOffline is reset
      final syncedResult = await db.query(
        'animales',
        where: 'id_animal = ?',
        whereArgs: [999],
      );
      
      expect(syncedResult, isNotEmpty);
      expect(syncedResult.first['modifiedOffline'], equals(0));
      expect(syncedResult.first['is_pending'], equals(0));
      expect(syncedResult.first['synced'], equals(1));
      
      print('✓ modifiedOffline flag reset after successful sync');
    });

    test('should reset modifiedOffline flag after successful update sync', () async {
      // Test update sync scenario
      
      // 1. Create and sync an animal first
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Update Sync Animal',
        codigoAnimal: 'UPDATE-SYNC-001',
        sexo: 'F',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      final db = await DatabaseService.database;
      final tempResult = await db.query(
        'animales',
        where: 'codigo_animal = ?',
        whereArgs: ['UPDATE-SYNC-001'],
      );
      final tempId = tempResult.first['id_animal'] as int;
      
      await DatabaseService.markAnimalAsSynced(tempId, 1000);
      
      // 2. Update the animal offline
      await DatabaseService.savePendingAnimalUpdateOffline(
        idAnimal: 1000,
        idRebano: 2,
        nombre: 'Updated Animal',
        codigoAnimal: 'UPDATE-SYNC-001-MOD',
        sexo: 'M',
        fechaNacimiento: '2024-01-15',
        procedencia: 'External',
        fkComposicionRaza: 2,
        estadoId: 2,
        etapaId: 2,
      );
      
      // Verify it's marked as modified offline
      final modifiedResult = await db.query(
        'animales',
        where: 'id_animal = ?',
        whereArgs: [1000],
      );
      expect(modifiedResult.first['modifiedOffline'], equals(1));
      expect(modifiedResult.first['is_pending'], equals(1));
      
      // 3. Mark update as synced
      await DatabaseService.markAnimalUpdateAsSynced(1000);
      
      // 4. Verify modifiedOffline is reset
      final finalResult = await db.query(
        'animales',
        where: 'id_animal = ?',
        whereArgs: [1000],
      );
      
      expect(finalResult, isNotEmpty);
      expect(finalResult.first['modifiedOffline'], equals(0));
      expect(finalResult.first['is_pending'], equals(0));
      expect(finalResult.first['synced'], equals(1));
      
      print('✓ modifiedOffline flag reset after successful update sync');
    });
  });
}