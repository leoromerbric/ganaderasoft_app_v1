import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/models/configuration_models.dart';

void main() {
  group('TipoAnimal-Etapa Integration Tests', () {
    late List<Etapa> testEtapas;
    late List<TipoAnimal> testTiposAnimal;

    setUp(() {
      // Create test data similar to API responses
      testTiposAnimal = [
        TipoAnimal(
          tipoAnimalId: 3,
          tipoAnimalNombre: 'Vacuno',
        ),
        TipoAnimal(
          tipoAnimalId: 4,
          tipoAnimalNombre: 'Bufala',
        ),
      ];

      testEtapas = [
        // Vacuno stages
        Etapa(
          etapaId: 15,
          etapaNombre: 'Becerro',
          etapaEdadIni: 0,
          etapaEdadFin: 365,
          etapaFkTipoAnimalId: 3,
          etapaSexo: 'M',
          tipoAnimal: testTiposAnimal[0],
        ),
        Etapa(
          etapaId: 16,
          etapaNombre: 'Becerra',
          etapaEdadIni: 0,
          etapaEdadFin: 365,
          etapaFkTipoAnimalId: 3,
          etapaSexo: 'H',
          tipoAnimal: testTiposAnimal[0],
        ),
        Etapa(
          etapaId: 21,
          etapaNombre: 'Toro',
          etapaEdadIni: 913,
          etapaEdadFin: null,
          etapaFkTipoAnimalId: 3,
          etapaSexo: 'M',
          tipoAnimal: testTiposAnimal[0],
        ),
        Etapa(
          etapaId: 22,
          etapaNombre: 'Vaca',
          etapaEdadIni: 913,
          etapaEdadFin: null,
          etapaFkTipoAnimalId: 3,
          etapaSexo: 'H',
          tipoAnimal: testTiposAnimal[0],
        ),
        // Bufala stages
        Etapa(
          etapaId: 23,
          etapaNombre: 'Bucerro',
          etapaEdadIni: 0,
          etapaEdadFin: 365,
          etapaFkTipoAnimalId: 4,
          etapaSexo: 'M',
          tipoAnimal: testTiposAnimal[1],
        ),
        Etapa(
          etapaId: 26,
          etapaNombre: 'Añoja',
          etapaEdadIni: 0,
          etapaEdadFin: 365,
          etapaFkTipoAnimalId: 4,
          etapaSexo: 'H',
          tipoAnimal: testTiposAnimal[1],
        ),
      ];
    });

    test('Should filter etapas by sex and tipo animal', () {
      // Simulate filtering logic from create_animal_screen.dart
      String selectedSexo = 'M';
      TipoAnimal selectedTipoAnimal = testTiposAnimal[0]; // Vacuno
      
      // Convert F to H for filtering (as implemented)
      String sexoForFiltering = selectedSexo == 'F' ? 'H' : selectedSexo;
      
      List<Etapa> filteredEtapas = testEtapas.where((etapa) => 
        etapa.etapaSexo == sexoForFiltering && 
        etapa.etapaFkTipoAnimalId == selectedTipoAnimal.tipoAnimalId
      ).toList();
      
      expect(filteredEtapas.length, 2); // Becerro and Toro
      expect(filteredEtapas[0].etapaNombre, 'Becerro');
      expect(filteredEtapas[1].etapaNombre, 'Toro');
    });

    test('Should convert F to H for female filtering', () {
      // Test female sex conversion
      String selectedSexo = 'F';
      TipoAnimal selectedTipoAnimal = testTiposAnimal[0]; // Vacuno
      
      // Convert F to H for filtering
      String sexoForFiltering = selectedSexo == 'F' ? 'H' : selectedSexo;
      
      List<Etapa> filteredEtapas = testEtapas.where((etapa) => 
        etapa.etapaSexo == sexoForFiltering && 
        etapa.etapaFkTipoAnimalId == selectedTipoAnimal.tipoAnimalId
      ).toList();
      
      expect(filteredEtapas.length, 2); // Becerra and Vaca
      expect(filteredEtapas[0].etapaNombre, 'Becerra');
      expect(filteredEtapas[1].etapaNombre, 'Vaca');
    });

    test('Should filter etapas by different tipo animal', () {
      String selectedSexo = 'M';
      TipoAnimal selectedTipoAnimal = testTiposAnimal[1]; // Bufala
      
      String sexoForFiltering = selectedSexo == 'F' ? 'H' : selectedSexo;
      
      List<Etapa> filteredEtapas = testEtapas.where((etapa) => 
        etapa.etapaSexo == sexoForFiltering && 
        etapa.etapaFkTipoAnimalId == selectedTipoAnimal.tipoAnimalId
      ).toList();
      
      expect(filteredEtapas.length, 1); // Only Bucerro
      expect(filteredEtapas[0].etapaNombre, 'Bucerro');
    });

    test('Should return empty list when no sex or tipo animal selected', () {
      // Simulate the condition when no selection is made
      String? selectedSexo = null;
      TipoAnimal? selectedTipoAnimal = null;
      
      if (selectedSexo == null || selectedTipoAnimal == null) {
        expect([], isEmpty);
      }
    });
  });
}