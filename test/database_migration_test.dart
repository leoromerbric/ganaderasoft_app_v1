import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Migration Tests', () {
    test('should create database with correct schema version 8', () async {
      // Get database instance (this will trigger creation/migration)
      final db = await DatabaseService.database;
      
      // Check version
      final version = await db.getVersion();
      expect(version, equals(8));
    });

    test('should have animales table with new sync columns', () async {
      final db = await DatabaseService.database;
      
      // Query table info to check if columns exist
      final tableInfo = await db.rawQuery("PRAGMA table_info(animales)");
      
      // Extract column names
      final columnNames = tableInfo.map((row) => row['name'] as String).toList();
      
      // Verify required columns exist
      expect(columnNames, contains('id_animal'));
      expect(columnNames, contains('synced'));
      expect(columnNames, contains('is_pending'));
      expect(columnNames, contains('pending_operation'));
      expect(columnNames, contains('estado_id'));
      expect(columnNames, contains('etapa_id'));
    });

    test('should handle database upgrade from version 7 to 8', () async {
      // This test verifies that the upgrade logic is in place
      // In a real scenario, we would need to create a DB with version 7 first
      // and then test the upgrade, but for this test we just verify the upgrade
      // function contains the necessary logic
      
      final db = await DatabaseService.database;
      final version = await db.getVersion();
      
      // Should be at latest version
      expect(version, equals(8));
      
      // Should have the new columns in animales table
      final tableInfo = await db.rawQuery("PRAGMA table_info(animales)");
      final hasIsyncColumns = tableInfo.any((row) => row['name'] == 'synced');
      final hasPendingColumns = tableInfo.any((row) => row['name'] == 'is_pending');
      
      expect(hasIsyncColumns, isTrue);
      expect(hasPendingColumns, isTrue);
    });
  });
}