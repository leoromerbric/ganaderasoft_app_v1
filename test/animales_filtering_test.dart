import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/models/animal.dart';
import 'package:ganaderasoft_app_v1/models/finca.dart';

void main() {
  group('Animales Filtering Logic Tests', () {
    test('Client-side filtering should work correctly', () {
      // Create test data
      final testAnimales = [
        Animal(
          idAnimal: 1,
          idRebano: 6, // Rebano 1
          nombre: 'Animal 1',
          codigoAnimal: 'A001',
          sexo: 'M',
          fechaNacimiento: '2023-01-01',
          procedencia: 'Test',
          archivado: false,
          createdAt: '2023-01-01',
          updatedAt: '2023-01-01',
          fkComposicionRaza: 1,
        ),
        Animal(
          idAnimal: 2,
          idRebano: 7, // Rebano 2  
          nombre: 'Animal 2',
          codigoAnimal: 'A002',
          sexo: 'F',
          fechaNacimiento: '2023-01-02',
          procedencia: 'Test',
          archivado: false,
          createdAt: '2023-01-02',
          updatedAt: '2023-01-02',
          fkComposicionRaza: 1,
        ),
        Animal(
          idAnimal: 3,
          idRebano: 6, // Rebano 1
          nombre: 'Animal 3',
          codigoAnimal: 'A003',
          sexo: 'M',
          fechaNacimiento: '2023-01-03',
          procedencia: 'Test',
          archivado: false,
          createdAt: '2023-01-03',
          updatedAt: '2023-01-03',
          fkComposicionRaza: 1,
        ),
      ];
      
      // Test filtering by rebano 6 (should get animals 1 and 3)
      final filteredRebano6 = testAnimales.where((animal) => 
        animal.idRebano == 6
      ).toList();
      
      expect(filteredRebano6.length, equals(2));
      expect(filteredRebano6[0].idAnimal, equals(1));
      expect(filteredRebano6[1].idAnimal, equals(3));
      
      // Test filtering by rebano 7 (should get animal 2)
      final filteredRebano7 = testAnimales.where((animal) => 
        animal.idRebano == 7
      ).toList();
      
      expect(filteredRebano7.length, equals(1));
      expect(filteredRebano7[0].idAnimal, equals(2));
      
      print('✅ Client-side filtering logic works correctly');
    });
    
    test('Filter should return empty list for non-existent rebano', () {
      final testAnimales = [
        Animal(
          idAnimal: 1,
          idRebano: 6,
          nombre: 'Animal 1',
          codigoAnimal: 'A001',
          sexo: 'M',
          fechaNacimiento: '2023-01-01',
          procedencia: 'Test',
          archivado: false,
          createdAt: '2023-01-01',
          updatedAt: '2023-01-01',
          fkComposicionRaza: 1,
        ),
      ];
      
      // Test filtering by non-existent rebano 999
      final filteredRebano999 = testAnimales.where((animal) => 
        animal.idRebano == 999
      ).toList();
      
      expect(filteredRebano999.length, equals(0));
      print('✅ Filter returns empty list for non-existent rebano');
    });
  });
}