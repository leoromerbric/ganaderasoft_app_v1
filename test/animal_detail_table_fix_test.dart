import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('Animal Detail Table Fix Tests', () {
    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    test('Fresh installation should have animal_detail table', () async {
      // Test that a fresh database installation includes the animal_detail table
      final db = await DatabaseService.database;
      
      // Query to check if animal_detail table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='animal_detail'"
      );
      
      expect(tables.isNotEmpty, true, 
        reason: 'animal_detail table should exist in fresh installation');
      expect(tables.first['name'], 'animal_detail');
    });

    test('animal_detail table should have correct structure', () async {
      // Verify the table has the expected columns
      final db = await DatabaseService.database;
      
      final tableInfo = await db.rawQuery("PRAGMA table_info('animal_detail')");
      final columnNames = tableInfo.map((col) => col['name'] as String).toSet();
      
      final expectedColumns = {
        'id_animal',
        'animal_data', 
        'etapa_animales_data',
        'etapa_actual_data',
        'estados_data',
        'local_updated_at'
      };
      
      for (final expectedColumn in expectedColumns) {
        expect(columnNames.contains(expectedColumn), true,
          reason: 'animal_detail table should have $expectedColumn column');
      }
    });

    test('animal_detail table should support basic operations', () async {
      // Test that we can insert and query the table
      final db = await DatabaseService.database;
      
      // Test insert
      await db.insert('animal_detail', {
        'id_animal': 1,
        'animal_data': '{"test": "data"}',
        'etapa_animales_data': '[]',
        'etapa_actual_data': null,
        'estados_data': '[]',
        'local_updated_at': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Test query
      final result = await db.query('animal_detail', where: 'id_animal = ?', whereArgs: [1]);
      expect(result.isNotEmpty, true);
      expect(result.first['id_animal'], 1);
      
      // Cleanup
      await db.delete('animal_detail', where: 'id_animal = ?', whereArgs: [1]);
    });

    test('Database service methods should work without errors', () async {
      // Test that DatabaseService methods that depend on animal_detail table work
      try {
        // This would previously fail with "no such table: animal_detail"
        final result = await DatabaseService.getAnimalDetailOffline(999);
        expect(result, null); // Should return null for non-existent animal, but not crash
      } catch (e) {
        fail('getAnimalDetailOffline should not throw error for missing table: $e');
      }
    });
  });
}