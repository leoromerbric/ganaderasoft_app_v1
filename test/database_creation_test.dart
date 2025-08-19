import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Creation Tests', () {
    test('should create all required tables on fresh installation', () async {
      // Get database instance to trigger fresh creation
      final db = await DatabaseService.database;
      
      // Verify all required tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
      );
      
      final tableNames = tables.map((t) => t['name'] as String).toSet();
      
      // Verify core tables exist
      expect(tableNames, contains('users'));
      expect(tableNames, contains('fincas'));
      
      // Verify configuration tables exist
      expect(tableNames, contains('estado_salud'));
      expect(tableNames, contains('tipo_animal'));
      expect(tableNames, contains('etapa'));
      expect(tableNames, contains('fuente_agua'));
      expect(tableNames, contains('metodo_riego'));
      expect(tableNames, contains('ph_suelo'));
      expect(tableNames, contains('sexo'));
      expect(tableNames, contains('textura_suelo'));
      expect(tableNames, contains('tipo_explotacion'));
      expect(tableNames, contains('tipo_relieve'));
      
      // Verify main business logic tables exist (these were missing before the fix)
      expect(tableNames, contains('rebanos'));
      expect(tableNames, contains('animales'));
      expect(tableNames, contains('composicion_raza'));
    });

    test('should be able to query rebanos and animales tables after fresh creation', () async {
      // Get database instance
      final db = await DatabaseService.database;
      
      // These queries should not throw errors if tables exist
      expect(() async => await db.query('rebanos'), returnsNormally);
      expect(() async => await db.query('animales'), returnsNormally);
      expect(() async => await db.query('composicion_raza'), returnsNormally);
      
      // Verify the tables return empty results (they should exist but be empty)
      final rebanos = await db.query('rebanos');
      final animales = await db.query('animales');
      final composicionRaza = await db.query('composicion_raza');
      
      expect(rebanos, isEmpty);
      expect(animales, isEmpty);
      expect(composicionRaza, isEmpty);
    });

    test('should have correct schema for rebanos table', () async {
      final db = await DatabaseService.database;
      
      final columns = await db.rawQuery("PRAGMA table_info(rebanos)");
      final columnNames = columns.map((c) => c['name'] as String).toSet();
      
      // Verify all required columns exist
      expect(columnNames, contains('id_rebano'));
      expect(columnNames, contains('id_finca'));
      expect(columnNames, contains('nombre'));
      expect(columnNames, contains('archivado'));
      expect(columnNames, contains('created_at'));
      expect(columnNames, contains('updated_at'));
      expect(columnNames, contains('finca_data'));
      expect(columnNames, contains('local_updated_at'));
    });

    test('should have correct schema for animales table', () async {
      final db = await DatabaseService.database;
      
      final columns = await db.rawQuery("PRAGMA table_info(animales)");
      final columnNames = columns.map((c) => c['name'] as String).toSet();
      
      // Verify all required columns exist
      expect(columnNames, contains('id_animal'));
      expect(columnNames, contains('id_rebano'));
      expect(columnNames, contains('nombre'));
      expect(columnNames, contains('codigo_animal'));
      expect(columnNames, contains('sexo'));
      expect(columnNames, contains('fecha_nacimiento'));
      expect(columnNames, contains('procedencia'));
      expect(columnNames, contains('archivado'));
      expect(columnNames, contains('created_at'));
      expect(columnNames, contains('updated_at'));
      expect(columnNames, contains('fk_composicion_raza'));
      expect(columnNames, contains('rebano_data'));
      expect(columnNames, contains('composicion_raza_data'));
      expect(columnNames, contains('local_updated_at'));
    });
  });
}