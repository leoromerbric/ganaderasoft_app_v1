// Manual verification script to test the null handling fix
// This simulates the exact error scenario from the issue
import '../lib/models/animal.dart';
import '../lib/models/configuration_models.dart';

void main() {
  print('Testing Animal Detail Null Fix...\n');

  // Test 1: Simulate the original error scenario
  print('=== Test 1: Original Error Scenario ===');
  try {
    final problematicJson = {
      'success': true,
      'message': 'Animal detail retrieved',
      'data': {
        'id_Animal': 18,
        'id_Rebano': 6,
        'Nombre': 'Animal Test',
        'codigo_animal': 'TEST-001',
        'Sexo': 'M',
        'fecha_nacimiento': '2025-03-15T00:00:00.000000Z',
        'Procedencia': 'Test Farm',
        'archivado': false,
        'created_at': '2025-08-18T21:35:24.000000Z',
        'updated_at': '2025-08-18T21:35:24.000000Z',
        'fk_composicion_raza': 70,
        'estados': [],
        'etapa_animales': [
          {
            'etan_etapa_id': 15,
            'etan_animal_id': 18,
            'etan_fecha_ini': '2025-03-15T00:00:00.000000Z',
            'etan_fecha_fin': null,
            'etapa': null, // This was causing the original crash
          }
        ],
        'etapa_actual': {
          'etan_etapa_id': 15,
          'etan_animal_id': 18,
          'etan_fecha_ini': '2025-03-15T00:00:00.000000Z',
          'etan_fecha_fin': null,
          'etapa': null, // This was also causing the crash
        },
      }
    };

    final response = AnimalDetailResponse.fromJson(problematicJson);
    print('✅ SUCCESS: AnimalDetailResponse.fromJson handled null etapa gracefully');
    print('   Animal ID: ${response.data.idAnimal}');
    print('   Animal Name: ${response.data.nombre}');
    print('   Etapa Animales Count: ${response.data.etapaAnimales.length}');
    print('   Etapa Actual: ${response.data.etapaActual != null ? "Present" : "Null"}');
    
    if (response.data.etapaAnimales.isNotEmpty) {
      final firstEtapa = response.data.etapaAnimales.first;
      print('   First Etapa ID: ${firstEtapa.etapa.etapaId} (default: 0)');
      print('   First Etapa Name: "${firstEtapa.etapa.etapaNombre}" (default: empty)');
    }
  } catch (e) {
    print('❌ FAILED: $e');
  }

  print('\n=== Test 2: Null TipoAnimal Scenario ===');
  try {
    final nullTipoAnimalJson = {
      'etapa_id': 15,
      'etapa_nombre': 'Becerro',
      'etapa_edad_ini': 0,
      'etapa_edad_fin': 365,
      'etapa_fk_tipo_animal_id': 3,
      'etapa_sexo': 'M',
      'tipo_animal': null, // This should not crash
    };

    final etapa = Etapa.fromJson(nullTipoAnimalJson);
    print('✅ SUCCESS: Etapa.fromJson handled null tipo_animal gracefully');
    print('   Etapa ID: ${etapa.etapaId}');
    print('   Etapa Name: ${etapa.etapaNombre}');
    print('   TipoAnimal ID: ${etapa.tipoAnimal.tipoAnimalId} (default: 0)');
    print('   TipoAnimal Name: "${etapa.tipoAnimal.tipoAnimalNombre}" (default: empty)');
  } catch (e) {
    print('❌ FAILED: $e');
  }

  print('\n=== Test 3: Completely Empty JSON ===');
  try {
    final emptyJson = <String, dynamic>{};
    
    final etapa = Etapa.fromJson(emptyJson);
    print('✅ SUCCESS: Etapa.fromJson handled empty JSON gracefully');
    print('   All fields have default values:');
    print('   - etapaId: ${etapa.etapaId}');
    print('   - etapaNombre: "${etapa.etapaNombre}"');
    print('   - etapaEdadIni: ${etapa.etapaEdadIni}');
    print('   - tipoAnimal.tipoAnimalId: ${etapa.tipoAnimal.tipoAnimalId}');
    print('   - tipoAnimal.tipoAnimalNombre: "${etapa.tipoAnimal.tipoAnimalNombre}"');
  } catch (e) {
    print('❌ FAILED: $e');
  }

  print('\n=== All Tests Completed ===');
  print('The fix successfully prevents the "type \'Null\' is not a subtype of type \'Map\'" error');
  print('by providing fallback empty maps and default values for null fields.');
}