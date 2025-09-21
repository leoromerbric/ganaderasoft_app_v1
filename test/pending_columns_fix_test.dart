import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Pending Columns Fix Tests', () {
    test('should create database with is_pending and pending_operation columns in all required tables', () async {
      // Get database instance (this will trigger creation)
      final db = await DatabaseService.database;
      
      // Check version
      final version = await db.getVersion();
      expect(version, equals(12));
      
      // List of tables that should have is_pending and pending_operation columns
      final tablesWithPendingColumns = [
        'animales',
        'cambios_animal', 
        'lactancia',
        'peso_corporal',
        'registro_lechero',
        'personal_finca'
      ];
      
      for (final tableName in tablesWithPendingColumns) {
        // Query table info to check if columns exist
        final tableInfo = await db.rawQuery("PRAGMA table_info($tableName)");
        
        // Extract column names
        final columnNames = tableInfo.map((row) => row['name'] as String).toList();
        
        // Verify required columns exist
        expect(columnNames, contains('is_pending'), 
          reason: 'Table $tableName should have is_pending column');
        expect(columnNames, contains('pending_operation'), 
          reason: 'Table $tableName should have pending_operation column');
        expect(columnNames, contains('synced'), 
          reason: 'Table $tableName should have synced column');
      }
    });

    test('should be able to query getAllPendingRecords without column errors', () async {
      // This test verifies that the query won't fail due to missing columns
      try {
        final pendingRecords = await DatabaseService.getAllPendingRecords();
        
        // Should not throw an exception
        expect(pendingRecords, isA<List<Map<String, dynamic>>>());
        
        // Initial database should have no pending records
        expect(pendingRecords, isEmpty);
      } catch (e) {
        fail('getAllPendingRecords should not throw exception: $e');
      }
    });
    
    test('lactancia table should have correct schema with all columns', () async {
      final db = await DatabaseService.database;
      
      // Query lactancia table info specifically
      final tableInfo = await db.rawQuery("PRAGMA table_info(lactancia)");
      
      // Extract column names
      final columnNames = tableInfo.map((row) => row['name'] as String).toList();
      
      // Verify all expected columns exist
      final expectedColumns = [
        'lactancia_id',
        'lactancia_fecha_inicio',
        'lactancia_fecha_fin',
        'lactancia_secado',
        'created_at',
        'updated_at',
        'lactancia_etapa_anid',
        'lactancia_etapa_etid',
        'synced',
        'local_updated_at',
        'modifiedOffline',
        'is_pending',
        'pending_operation'
      ];
      
      for (final column in expectedColumns) {
        expect(columnNames, contains(column), 
          reason: 'lactancia table should have $column column');
      }
    });
  });
}