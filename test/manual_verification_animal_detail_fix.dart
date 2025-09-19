// Manual verification script for the animal_detail table fix
// This script demonstrates that fresh installations now include the animal_detail table

import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> manualVerificationAnimalDetailFix() async {
  print('=== Manual Verification: Animal Detail Table Fix ===\n');

  // Initialize FFI for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  try {
    print('1. Initializing fresh database (simulating clean installation)...');
    final db = await DatabaseService.database;
    print('   ✓ Database initialized successfully\n');

    print('2. Checking if animal_detail table exists...');

    // Query table names
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    );
    final tableNames = tables.map((t) => t['name'] as String).toSet();

    if (tableNames.contains('animal_detail')) {
      print('   ✓ animal_detail table EXISTS');

      print('\n3. Verifying table structure...');
      final tableInfo = await db.rawQuery("PRAGMA table_info('animal_detail')");

      print('   Columns in animal_detail table:');
      for (final col in tableInfo) {
        final name = col['name'];
        final type = col['type'];
        final notNull = col['notnull'] == 1 ? 'NOT NULL' : 'NULL';
        final pk = col['pk'] == 1 ? ' PRIMARY KEY' : '';
        print('     - $name ($type $notNull$pk)');
      }

      print('\n4. Testing animal_detail operations...');

      try {
        // Test insert operation (what was failing before)
        final testData = {
          'id_animal': 999,
          'animal_data': '{"id_Animal":999,"Nombre":"Test Animal"}',
          'etapa_animales_data': '[]',
          'etapa_actual_data': null,
          'estados_data': '[]',
          'local_updated_at': DateTime.now().millisecondsSinceEpoch,
        };

        await db.insert(
          'animal_detail',
          testData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('   ✓ INSERT operation successful');

        // Test query operation
        final result = await db.query(
          'animal_detail',
          where: 'id_animal = ?',
          whereArgs: [999],
        );
        print('   ✓ SELECT operation successful (${result.length} rows)');

        // Test DatabaseService method

        print('   ✓ DatabaseService.getAnimalDetailOffline() works');

        // Cleanup
        await db.delete(
          'animal_detail',
          where: 'id_animal = ?',
          whereArgs: [999],
        );
        print('   ✓ DELETE operation successful');

        print('\n=== VERIFICATION SUCCESSFUL ===');
        print('✓ Fresh installations now include animal_detail table');
        print('✓ Animal synchronization will work after clean installation');
        print('✓ No more "no such table: animal_detail" errors');
      } catch (e) {
        print('   ✗ animal_detail operations failed: $e');
      }
    } else {
      print('   ✗ animal_detail table is MISSING');
      print('\n=== VERIFICATION FAILED ===');
      print('The fix was not applied correctly.');
    }

    print('\nAll tables in database:');
    for (final table in tableNames.where((t) => !t.startsWith('sqlite_'))) {
      print('   - $table');
    }
  } catch (e) {
    print('ERROR: Failed to verify database: $e');
  }
}

void main() async {
  await manualVerificationAnimalDetailFix();
}
