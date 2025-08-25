// Integration test to simulate the exact error scenario from the issue
// This demonstrates that the fix resolves the "no such table: animal_detail" error

import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:ganaderasoft_app_v1/models/animal.dart';
import 'package:ganaderasoft_app_v1/models/configuration_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('Animal Detail Error Scenario Fix', () {
    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    test('Simulate exact error scenario from issue - should NOT crash', () async {
      // This test simulates the exact scenario described in the issue:
      // 1. Fresh installation (clean database)
      // 2. User logs in and syncs animal data
      // 3. saveAnimalDetailOffline is called
      // 4. Before fix: "no such table: animal_detail" error
      // 5. After fix: should work without error

      // Step 1: Initialize fresh database (simulates clean installation)
      final db = await DatabaseService.database;
      
      // Step 2: Create a sample AnimalDetail object like what would come from the API
      // Based on the JSON structure from the error logs
      final animalDetail = AnimalDetail(
        idAnimal: 22,
        idRebano: 6,
        nombre: "Esperanza",
        codigoAnimal: "ESP-001",
        sexo: "F",
        fechaNacimiento: "2022-03-15T00:00:00.000000Z",
        procedencia: "Finca San Jose",
        archivado: false,
        createdAt: "2025-08-24T00:31:48.000000Z",
        updatedAt: "2025-08-24T00:31:48.000000Z",
        fkComposicionRaza: 72,
        estados: [], // Empty list as in the error scenario
        etapaAnimales: [], // Empty list as in the error scenario
        etapaActual: null, // Null as in the error scenario
      );

      // Step 3: Try to save animal detail offline - this was failing before fix
      try {
        await DatabaseService.saveAnimalDetailOffline(animalDetail);
        
        // If we get here, the fix worked!
        print('✓ saveAnimalDetailOffline completed successfully');
        
        // Verify data was actually saved
        final savedDetail = await DatabaseService.getAnimalDetailOffline(22);
        expect(savedDetail, isNotNull);
        expect(savedDetail!.idAnimal, 22);
        expect(savedDetail.nombre, "Esperanza");
        
        print('✓ Animal detail retrieved successfully from database');
        
      } catch (e) {
        fail('saveAnimalDetailOffline should not fail with "no such table" error: $e');
      }
    });

    test('Verify database has animal_detail table after fresh creation', () async {
      // Double-check that the table exists and has correct structure
      final db = await DatabaseService.database;
      
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='animal_detail'"
      );
      
      expect(tableExists.isNotEmpty, true, 
        reason: 'animal_detail table must exist in fresh database');
      
      // Verify table structure matches what saveAnimalDetailOffline expects
      final columns = await db.rawQuery("PRAGMA table_info('animal_detail')");
      final columnNames = columns.map((col) => col['name'] as String).toSet();
      
      final requiredColumns = {
        'id_animal', 'animal_data', 'etapa_animales_data', 
        'etapa_actual_data', 'estados_data', 'local_updated_at'
      };
      
      for (final col in requiredColumns) {
        expect(columnNames.contains(col), true,
          reason: 'Column $col must exist for saveAnimalDetailOffline to work');
      }
    });
  });
}