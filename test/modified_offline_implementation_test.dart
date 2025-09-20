import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Modified Offline Implementation Tests', () {
    test('should create database with modifiedOffline column in all tables', () async {
      // Initialize database which should create version 10
      final db = await DatabaseService.database;
      
      // Check that database version is 10
      expect(await db.getVersion(), equals(10));
      
      // List of all tables that should have modifiedOffline column
      final tables = [
        'users', 'fincas', 'estado_salud', 'tipo_animal', 'etapa', 'fuente_agua',
        'metodo_riego', 'ph_suelo', 'sexo', 'textura_suelo', 'tipo_explotacion',
        'tipo_relieve', 'rebanos', 'animales', 'composicion_raza', 'animal_detail',
        'cambios_animal', 'lactancia', 'peso_corporal', 'personal_finca'
      ];
      
      // Check each table has the modifiedOffline column
      for (final table in tables) {
        final result = await db.rawQuery("PRAGMA table_info($table)");
        final columns = result.map((row) => row['name'] as String).toList();
        expect(columns, contains('modifiedOffline'), 
               reason: 'Table $table should have modifiedOffline column');
      }
      
      print('✓ All ${tables.length} tables have modifiedOffline column');
    });
    
    test('should set modifiedOffline flag when saving animals offline', () async {
      // Create an animal offline
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

      final db = await DatabaseService.database;
      final result = await db.query(
        'animales',
        where: 'codigo_animal = ?',
        whereArgs: ['TEST-001'],
      );

      expect(result, isNotEmpty);
      expect(result.first['modifiedOffline'], equals(1));
      expect(result.first['is_pending'], equals(1));
      expect(result.first['pending_operation'], equals('CREATE'));
      
      print('✓ Animal created offline has modifiedOffline = 1');
    });

    test('should set modifiedOffline flag when updating animals offline', () async {
      // First create and sync an animal
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Animal to Update',
        codigoAnimal: 'UPDATE-001',
        sexo: 'F',
        fechaNacimiento: '2024-01-15',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      final db = await DatabaseService.database;
      final tempResult = await db.query(
        'animales',
        where: 'codigo_animal = ?',
        whereArgs: ['UPDATE-001'],
      );
      final tempId = tempResult.first['id_animal'] as int;

      // Simulate syncing - replace temp ID with real ID
      await DatabaseService.markAnimalAsSynced(tempId, 100);

      // Now update the animal offline
      await DatabaseService.savePendingAnimalUpdateOffline(
        idAnimal: 100,
        idRebano: 2,
        nombre: 'Updated Animal Offline',
        codigoAnimal: 'UPDATE-001-MODIFIED',
        sexo: 'F',
        fechaNacimiento: '2024-01-20',
        procedencia: 'External',
        fkComposicionRaza: 2,
        estadoId: 2,
        etapaId: 2,
      );

      final updatedResult = await db.query(
        'animales',
        where: 'id_animal = ?',
        whereArgs: [100],
      );

      expect(updatedResult, isNotEmpty);
      expect(updatedResult.first['modifiedOffline'], equals(1));
      expect(updatedResult.first['is_pending'], equals(1));
      expect(updatedResult.first['pending_operation'], equals('UPDATE'));
      expect(updatedResult.first['nombre'], equals('Updated Animal Offline'));
      
      print('✓ Animal updated offline has modifiedOffline = 1');
    });

    test('should set modifiedOffline flag when creating personal finca offline', () async {
      await DatabaseService.savePendingPersonalFincaOffline(
        idFinca: 1,
        cedula: 12345678,
        nombre: 'Juan',
        apellido: 'Offline',
        telefono: '3001234567',
        correo: 'juan.offline@test.com',
        tipoTrabajador: 'Administrador',
      );

      final db = await DatabaseService.database;
      final result = await db.query(
        'personal_finca',
        where: 'correo = ?',
        whereArgs: ['juan.offline@test.com'],
      );

      expect(result, isNotEmpty);
      expect(result.first['modifiedOffline'], equals(1));
      expect(result.first['is_pending'], equals(1));
      expect(result.first['pending_operation'], equals('CREATE'));
      
      print('✓ Personal finca created offline has modifiedOffline = 1');
    });

    test('should set modifiedOffline flag when updating personal finca offline', () async {
      // First create and sync a personal finca
      await DatabaseService.savePendingPersonalFincaOffline(
        idFinca: 1,
        cedula: 87654321,
        nombre: 'Maria',
        apellido: 'Test',
        telefono: '3009876543',
        correo: 'maria.test@test.com',
        tipoTrabajador: 'Supervisor',
      );

      final db = await DatabaseService.database;
      final tempResult = await db.query(
        'personal_finca',
        where: 'correo = ?',
        whereArgs: ['maria.test@test.com'],
      );
      final tempId = tempResult.first['id_tecnico'] as int;

      // Simulate syncing - replace temp ID with real ID
      await DatabaseService.markPersonalFincaAsSynced(tempId, 200);

      // Now update the personal finca offline
      await DatabaseService.savePendingPersonalFincaUpdateOffline(
        idTecnico: 200,
        idFinca: 2,
        cedula: 87654321,
        nombre: 'Maria Updated',
        apellido: 'Offline',
        telefono: '3001111111',
        correo: 'maria.updated@test.com',
        tipoTrabajador: 'Administrador',
      );

      final updatedResult = await db.query(
        'personal_finca',
        where: 'id_tecnico = ?',
        whereArgs: [200],
      );

      expect(updatedResult, isNotEmpty);
      expect(updatedResult.first['modifiedOffline'], equals(1));
      expect(updatedResult.first['is_pending'], equals(1));
      expect(updatedResult.first['pending_operation'], equals('UPDATE'));
      expect(updatedResult.first['nombre'], equals('Maria Updated'));
      
      print('✓ Personal finca updated offline has modifiedOffline = 1');
    });
  });
}