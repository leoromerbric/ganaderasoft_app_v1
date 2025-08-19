// Manual verification script to demonstrate the database fix
// This script can be run to verify that the database tables are created correctly

import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> manualVerification() async {
  print('=== Manual Verification: Database Table Creation Fix ===\n');
  
  // Initialize FFI for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  try {
    print('1. Initializing fresh database...');
    final db = await DatabaseService.database;
    print('   ✓ Database initialized successfully\n');
    
    print('2. Checking if critical tables exist...');
    
    // Query table names
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
    );
    final tableNames = tables.map((t) => t['name'] as String).toSet();
    
    // Check required tables
    final requiredTables = ['rebanos', 'animales', 'composicion_raza'];
    final missingTables = <String>[];
    
    for (final tableName in requiredTables) {
      if (tableNames.contains(tableName)) {
        print('   ✓ Table \'$tableName\' exists');
      } else {
        print('   ✗ Table \'$tableName\' is MISSING');
        missingTables.add(tableName);
      }
    }
    
    if (missingTables.isEmpty) {
      print('\n3. Testing table queries...');
      
      // Test if we can query the tables without errors
      try {
        await db.query('rebanos');
        print('   ✓ rebanos table can be queried');
        
        await db.query('animales');
        print('   ✓ animales table can be queried');
        
        await db.query('composicion_raza');
        print('   ✓ composicion_raza table can be queried');
        
        print('\n4. Testing DatabaseService methods...');
        
        // Test the specific methods that would fail before the fix
        try {
          await DatabaseService.getRebanosOffline();
          print('   ✓ DatabaseService.getRebanosOffline() works');
          
          await DatabaseService.getAnimalesOffline();
          print('   ✓ DatabaseService.getAnimalesOffline() works');
          
          await DatabaseService.getComposicionRazaOffline();
          print('   ✓ DatabaseService.getComposicionRazaOffline() works');
          
          // Test last updated methods
          await DatabaseService.getRebanosLastUpdated();
          print('   ✓ DatabaseService.getRebanosLastUpdated() works');
          
          await DatabaseService.getAnimalesLastUpdated();
          print('   ✓ DatabaseService.getAnimalesLastUpdated() works');
          
          print('\n=== VERIFICATION SUCCESSFUL ===');
          print('The fix resolves the APK installation issue!');
          print('Fresh installations will now have all required tables.');
          
        } catch (e) {
          print('   ✗ DatabaseService method failed: $e');
        }
        
      } catch (e) {
        print('   ✗ Table query failed: $e');
      }
      
    } else {
      print('\n=== VERIFICATION FAILED ===');
      print('Missing tables: ${missingTables.join(', ')}');
      print('The fix needs to be applied to resolve the issue.');
    }
    
    print('\nAll tables found:');
    for (final table in tableNames.where((t) => !t.startsWith('sqlite_'))) {
      print('   - $table');
    }
    
  } catch (e) {
    print('ERROR: Failed to verify database: $e');
  }
}

void main() async {
  await manualVerification();
}