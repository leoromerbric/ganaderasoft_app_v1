import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:ganaderasoft_app_v1/models/animal.dart';
import 'package:ganaderasoft_app_v1/models/finca.dart';

void main() {
  group('Animales Filtering Tests', () {
    test('DatabaseService should filter animals by rebano ID', () async {
      // This test verifies that the database filtering logic works correctly
      
      // Test offline filtering with specific rebano ID
      final animales = await DatabaseService.getAnimalesOffline(
        idRebano: 1, // Specific rebano ID
        idFinca: null,
      );
      
      // All returned animals should belong to rebano ID 1
      for (final animal in animales) {
        expect(animal.idRebano, equals(1), 
               reason: 'Animal ${animal.idAnimal} should belong to rebano 1 but belongs to ${animal.idRebano}');
      }
      
      print('Test completed: Found ${animales.length} animals for rebano 1');
    });

    test('DatabaseService should filter animals by finca ID when rebano is null', () async {
      // Test offline filtering with finca ID only
      final animales = await DatabaseService.getAnimalesOffline(
        idRebano: null,
        idFinca: 15, // Specific finca ID
      );
      
      // Should return animals from all rebanos in the finca
      print('Test completed: Found ${animales.length} animals for finca 15');
      
      // Verify that all animals belong to rebanos from the specified finca
      if (animales.isNotEmpty) {
        final rebanos = await DatabaseService.getRebanosOffline(idFinca: 15);
        final rebanoIds = rebanos.map((r) => r.idRebano).toList();
        
        for (final animal in animales) {
          expect(rebanoIds.contains(animal.idRebano), isTrue,
                 reason: 'Animal ${animal.idAnimal} belongs to rebano ${animal.idRebano} which should be in finca 15');
        }
      }
    });
  });
}