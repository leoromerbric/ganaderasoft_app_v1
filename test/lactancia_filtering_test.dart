import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/models/farm_management_models.dart';

void main() {
  group('Lactancia Filtering Logic Tests', () {
    late List<Lactancia> testLactancias;

    setUp(() {
      testLactancias = [
        // Active lactancia (no end date)
        Lactancia(
          lactanciaId: 1,
          lactanciaFechaInicio: '2024-01-01T00:00:00.000000Z',
          lactanciaFechaFin: null,
          lactanciaSecado: null,
          createdAt: '2024-01-01T00:00:00.000000Z',
          updatedAt: '2024-01-01T00:00:00.000000Z',
          lactanciaEtapaAnid: 1,
          lactanciaEtapaEtid: 1,
        ),
        // Finished lactancia (has end date)
        Lactancia(
          lactanciaId: 2,
          lactanciaFechaInicio: '2023-06-01T00:00:00.000000Z',
          lactanciaFechaFin: '2023-12-01T00:00:00.000000Z',
          lactanciaSecado: '2023-11-15T00:00:00.000000Z',
          createdAt: '2023-06-01T00:00:00.000000Z',
          updatedAt: '2023-12-01T00:00:00.000000Z',
          lactanciaEtapaAnid: 2,
          lactanciaEtapaEtid: 1,
        ),
        // Another active lactancia
        Lactancia(
          lactanciaId: 3,
          lactanciaFechaInicio: '2024-03-01T00:00:00.000000Z',
          lactanciaFechaFin: null,
          lactanciaSecado: null,
          createdAt: '2024-03-01T00:00:00.000000Z',
          updatedAt: '2024-03-01T00:00:00.000000Z',
          lactanciaEtapaAnid: 1,
          lactanciaEtapaEtid: 1,
        ),
      ];
    });

    test('should correctly identify active lactancias', () {
      // Function to check if lactancia is active (same logic as in screen)
      bool isLactanciaActive(Lactancia lactancia) {
        return lactancia.lactanciaFechaFin == null;
      }

      final activeLactancias = testLactancias.where(isLactanciaActive).toList();
      
      expect(activeLactancias.length, equals(2));
      expect(activeLactancias[0].lactanciaId, equals(1));
      expect(activeLactancias[1].lactanciaId, equals(3));
    });

    test('should correctly identify finished lactancias', () {
      // Function to check if lactancia is active (same logic as in screen)
      bool isLactanciaActive(Lactancia lactancia) {
        return lactancia.lactanciaFechaFin == null;
      }

      final finishedLactancias = testLactancias.where((l) => !isLactanciaActive(l)).toList();
      
      expect(finishedLactancias.length, equals(1));
      expect(finishedLactancias[0].lactanciaId, equals(2));
    });

    test('should filter by animal ID correctly', () {
      final animal1Lactancias = testLactancias
          .where((lactancia) => lactancia.lactanciaEtapaAnid == 1)
          .toList();
      
      expect(animal1Lactancias.length, equals(2));
      expect(animal1Lactancias[0].lactanciaId, equals(1));
      expect(animal1Lactancias[1].lactanciaId, equals(3));

      final animal2Lactancias = testLactancias
          .where((lactancia) => lactancia.lactanciaEtapaAnid == 2)
          .toList();
      
      expect(animal2Lactancias.length, equals(1));
      expect(animal2Lactancias[0].lactanciaId, equals(2));
    });

    test('should apply combined filters correctly', () {
      // Function to check if lactancia is active (same logic as in screen)
      bool isLactanciaActive(Lactancia lactancia) {
        return lactancia.lactanciaFechaFin == null;
      }

      // Filter by animal 1 AND active status
      final animal1ActiveLactancias = testLactancias
          .where((lactancia) => lactancia.lactanciaEtapaAnid == 1)
          .where(isLactanciaActive)
          .toList();
      
      expect(animal1ActiveLactancias.length, equals(2));
      
      // Filter by animal 2 AND active status (should be empty)
      final animal2ActiveLactancias = testLactancias
          .where((lactancia) => lactancia.lactanciaEtapaAnid == 2)
          .where(isLactanciaActive)
          .toList();
      
      expect(animal2ActiveLactancias.length, equals(0));
    });

    test('should sort lactancias by start date descending', () {
      final sortedLactancias = List<Lactancia>.from(testLactancias);
      sortedLactancias.sort((a, b) => 
          DateTime.parse(b.lactanciaFechaInicio).compareTo(DateTime.parse(a.lactanciaFechaInicio)));
      
      expect(sortedLactancias[0].lactanciaId, equals(3)); // 2024-03-01
      expect(sortedLactancias[1].lactanciaId, equals(1)); // 2024-01-01
      expect(sortedLactancias[2].lactanciaId, equals(2)); // 2023-06-01
    });
  });

  group('Count Display Text Tests', () {
    test('should generate correct count text for different statuses', () {
      // Test for "todas" (all)
      String getCountDisplayText(int count, String selectedStatus) {
        final plural = count != 1;
        
        String statusText = '';
        switch (selectedStatus) {
          case 'activas':
            statusText = ' activa${plural ? 's' : ''}';
            break;
          case 'finalizadas':
            statusText = ' finalizada${plural ? 's' : ''}';
            break;
          default:
            statusText = '';
        }
        
        return '$count lactancia${plural ? 's' : ''}$statusText${plural ? ' encontradas' : ' encontrada'}';
      }

      expect(getCountDisplayText(0, 'todas'), equals('0 lactancias encontradas'));
      expect(getCountDisplayText(1, 'todas'), equals('1 lactancia encontrada'));
      expect(getCountDisplayText(2, 'todas'), equals('2 lactancias encontradas'));
      
      expect(getCountDisplayText(1, 'activas'), equals('1 lactancia activa encontrada'));
      expect(getCountDisplayText(2, 'activas'), equals('2 lactancias activas encontradas'));
      
      expect(getCountDisplayText(1, 'finalizadas'), equals('1 lactancia finalizada encontrada'));
      expect(getCountDisplayText(2, 'finalizadas'), equals('2 lactancias finalizadas encontradas'));
    });
  });

  group('Empty State Message Tests', () {
    test('should generate correct empty state messages', () {
      String getEmptyStateTitle(String selectedStatus) {
        switch (selectedStatus) {
          case 'activas':
            return 'No hay lactancias activas';
          case 'finalizadas':
            return 'No hay lactancias finalizadas';
          default:
            return 'No hay lactancias registradas';
        }
      }

      String getEmptyStateSubtitle(String selectedStatus) {
        switch (selectedStatus) {
          case 'activas':
            return 'No se encontraron lactancias en curso';
          case 'finalizadas':
            return 'No se encontraron lactancias terminadas';
          default:
            return 'Agrega el primer período de lactancia';
        }
      }

      expect(getEmptyStateTitle('todas'), equals('No hay lactancias registradas'));
      expect(getEmptyStateTitle('activas'), equals('No hay lactancias activas'));
      expect(getEmptyStateTitle('finalizadas'), equals('No hay lactancias finalizadas'));

      expect(getEmptyStateSubtitle('todas'), equals('Agrega el primer período de lactancia'));
      expect(getEmptyStateSubtitle('activas'), equals('No se encontraron lactancias en curso'));
      expect(getEmptyStateSubtitle('finalizadas'), equals('No se encontraron lactancias terminadas'));
    });
  });
}