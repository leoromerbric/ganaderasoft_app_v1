import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/models/animal.dart';
import 'package:ganaderasoft_app_v1/models/farm_management_models.dart';

void main() {
  group('Milk Records Filtering Logic Tests', () {
    late List<Animal> testAnimals;
    late List<Lactancia> testLactancias;
    late List<RegistroLechero> testRegistrosLeche;

    setUp(() {
      testAnimals = [
        Animal(
          idAnimal: 1,
          nombre: 'Vaca1',
          codigoAnimal: 'V001',
          sexo: 'F',
          fechaNacimiento: '2020-01-01',
          procedencia: 'Local',
          idRebano: 6,
          archivado: false,
          createdAt: '',
          updatedAt: '',
          fkComposicionRaza: 72,
        ),
        Animal(
          idAnimal: 2,
          nombre: 'Vaca2',
          codigoAnimal: 'V002',
          sexo: 'F',
          fechaNacimiento: '2020-02-01',
          procedencia: 'Local',
          idRebano: 6,
          archivado: false,
          createdAt: '',
          updatedAt: '',
          fkComposicionRaza: 71,
        ),
        Animal(
          idAnimal: 3,
          nombre: 'Toro1',
          codigoAnimal: 'T001',
          sexo: 'M',
          fechaNacimiento: '2019-01-01',
          procedencia: 'Local',
          idRebano: 6,
          archivado: false,
          createdAt: '',
          updatedAt: '',
          fkComposicionRaza: 70,
        ),
      ];

      testLactancias = [
        Lactancia(
          lactanciaId: 1,
          lactanciaFechaInicio: '2024-01-01T00:00:00.000000Z',
          lactanciaFechaFin: null,
          lactanciaSecado: null,
          createdAt: '2024-01-01T00:00:00.000000Z',
          updatedAt: '2024-01-01T00:00:00.000000Z',
          lactanciaEtapaAnid: 1, // Vaca1
          lactanciaEtapaEtid: 1,
        ),
        Lactancia(
          lactanciaId: 2,
          lactanciaFechaInicio: '2024-02-01T00:00:00.000000Z',
          lactanciaFechaFin: null,
          lactanciaSecado: null,
          createdAt: '2024-02-01T00:00:00.000000Z',
          updatedAt: '2024-02-01T00:00:00.000000Z',
          lactanciaEtapaAnid: 2, // Vaca2
          lactanciaEtapaEtid: 1,
        ),
        Lactancia(
          lactanciaId: 3,
          lactanciaFechaInicio: '2023-12-01T00:00:00.000000Z',
          lactanciaFechaFin: '2024-06-01T00:00:00.000000Z',
          lactanciaSecado: null,
          createdAt: '2023-12-01T00:00:00.000000Z',
          updatedAt: '2024-06-01T00:00:00.000000Z',
          lactanciaEtapaAnid: 1, // Vaca1 (finished lactation)
          lactanciaEtapaEtid: 1,
        ),
      ];

      testRegistrosLeche = [
        RegistroLechero(
          lecheId: 1,
          lecheFechaPesaje: '2024-01-05T00:00:00.000000Z',
          lechePesajeTotal: '25.5',
          createdAt: '2024-01-05T00:00:00.000000Z',
          updatedAt: '2024-01-05T00:00:00.000000Z',
          lecheLactanciaId: 1, // Lactancia 1
        ),
        RegistroLechero(
          lecheId: 2,
          lecheFechaPesaje: '2024-01-10T00:00:00.000000Z',
          lechePesajeTotal: '28.0',
          createdAt: '2024-01-10T00:00:00.000000Z',
          updatedAt: '2024-01-10T00:00:00.000000Z',
          lecheLactanciaId: 1, // Lactancia 1
        ),
        RegistroLechero(
          lecheId: 3,
          lecheFechaPesaje: '2024-02-05T00:00:00.000000Z',
          lechePesajeTotal: '22.0',
          createdAt: '2024-02-05T00:00:00.000000Z',
          updatedAt: '2024-02-05T00:00:00.000000Z',
          lecheLactanciaId: 2, // Lactancia 2
        ),
        RegistroLechero(
          lecheId: 4,
          lecheFechaPesaje: '2024-01-01T00:00:00.000000Z',
          lechePesajeTotal: '20.0',
          createdAt: '2024-01-01T00:00:00.000000Z',
          updatedAt: '2024-01-01T00:00:00.000000Z',
          lecheLactanciaId: 3, // Lactancia 3 (finished)
        ),
      ];
    });

    test('should filter only female animals correctly', () {
      final femaleAnimals = testAnimals
          .where((animal) => animal.sexo.toLowerCase() == 'hembra')
          .toList();

      expect(femaleAnimals.length, equals(2));
      expect(femaleAnimals[0].nombre, equals('Vaca1'));
      expect(femaleAnimals[1].nombre, equals('Vaca2'));
    });

    test('should filter milk records by selected animal correctly', () {
      // Simulate filtering by animal ID 1 (Vaca1)
      final selectedAnimalId = 1;

      // Get lactancias for selected animal
      final animalLactancias = testLactancias
          .where(
            (lactancia) => lactancia.lactanciaEtapaAnid == selectedAnimalId,
          )
          .map((lactancia) => lactancia.lactanciaId)
          .toSet();

      // Filter milk records for these lactancias
      final filteredRecords = testRegistrosLeche
          .where(
            (registro) => animalLactancias.contains(registro.lecheLactanciaId),
          )
          .toList();

      expect(
        filteredRecords.length,
        equals(3),
      ); // Records from lactancia 1 and 3
      expect(filteredRecords.any((r) => r.lecheId == 1), isTrue);
      expect(filteredRecords.any((r) => r.lecheId == 2), isTrue);
      expect(filteredRecords.any((r) => r.lecheId == 4), isTrue);
    });

    test('should filter milk records by selected lactancia correctly', () {
      // Simulate filtering by lactancia ID 1
      final selectedLactanciaId = 1;

      final filteredRecords = testRegistrosLeche
          .where((registro) => registro.lecheLactanciaId == selectedLactanciaId)
          .toList();

      expect(filteredRecords.length, equals(2)); // Records 1 and 2
      expect(filteredRecords[0].lecheId, equals(1));
      expect(filteredRecords[1].lecheId, equals(2));
    });

    test('should get available lactancias for selected animal correctly', () {
      // Simulate getting lactancias for animal ID 1
      final selectedAnimalId = 1;

      final availableLactancias = testLactancias
          .where(
            (lactancia) => lactancia.lactanciaEtapaAnid == selectedAnimalId,
          )
          .toList();

      expect(availableLactancias.length, equals(2)); // Lactancias 1 and 3
      expect(availableLactancias[0].lactanciaId, equals(1));
      expect(availableLactancias[1].lactanciaId, equals(3));
    });

    test('should sort milk records by date descending correctly', () {
      final sortedRecords = List<RegistroLechero>.from(testRegistrosLeche);
      sortedRecords.sort(
        (a, b) => DateTime.parse(
          b.lecheFechaPesaje,
        ).compareTo(DateTime.parse(a.lecheFechaPesaje)),
      );

      expect(sortedRecords[0].lecheId, equals(3)); // 2024-02-05
      expect(sortedRecords[1].lecheId, equals(2)); // 2024-01-10
      expect(sortedRecords[2].lecheId, equals(1)); // 2024-01-05
      expect(sortedRecords[3].lecheId, equals(4)); // 2024-01-01
    });

    test('should apply combined filters (animal + lactancia) correctly', () {
      // Filter by animal 1 and lactancia 1
      final selectedAnimalId = 1;
      final selectedLactanciaId = 1;

      // First filter by animal
      final animalLactancias = testLactancias
          .where(
            (lactancia) => lactancia.lactanciaEtapaAnid == selectedAnimalId,
          )
          .map((lactancia) => lactancia.lactanciaId)
          .toSet();

      var filteredRecords = testRegistrosLeche
          .where(
            (registro) => animalLactancias.contains(registro.lecheLactanciaId),
          )
          .toList();

      // Then filter by specific lactancia
      filteredRecords = filteredRecords
          .where((registro) => registro.lecheLactanciaId == selectedLactanciaId)
          .toList();

      expect(
        filteredRecords.length,
        equals(2),
      ); // Only records from lactancia 1
      expect(filteredRecords[0].lecheId, equals(1));
      expect(filteredRecords[1].lecheId, equals(2));
    });
  });

  group('Helper Functions Tests', () {
    test('should format date correctly', () {
      String formatDate(String dateString) {
        try {
          final date = DateTime.parse(dateString);
          return '${date.day}/${date.month}/${date.year}';
        } catch (e) {
          return dateString;
        }
      }

      expect(formatDate('2024-01-05T00:00:00.000000Z'), equals('5/1/2024'));
      expect(formatDate('2024-12-25T00:00:00.000000Z'), equals('25/12/2024'));
      expect(formatDate('invalid-date'), equals('invalid-date'));
    });

    test('should generate correct count display text', () {
      String getCountDisplayText(int count) {
        final plural = count != 1;
        return '$count registro${plural ? 's' : ''} de leche${plural ? ' encontrados' : ' encontrado'}';
      }

      expect(
        getCountDisplayText(0),
        equals('0 registros de leche encontrados'),
      );
      expect(getCountDisplayText(1), equals('1 registro de leche encontrado'));
      expect(
        getCountDisplayText(5),
        equals('5 registros de leche encontrados'),
      );
    });

    test('should get animal name by ID correctly', () {
      final testAnimals = [
        Animal(
          idAnimal: 13,
          nombre: 'Vaca1',
          codigoAnimal: 'V001',
          sexo: 'F',
          fechaNacimiento: '2020-01-01',
          procedencia: 'Local',
          idRebano: 6,
          archivado: false,
          createdAt: '',
          updatedAt: '',
          fkComposicionRaza: 70,
        ),
      ];

      String getAnimalName(int animalId, List<Animal> femaleAnimals) {
        try {
          final animal = femaleAnimals.firstWhere(
            (a) => a.idAnimal == animalId,
          );
          return animal.nombre;
        } catch (e) {
          return 'Animal #$animalId';
        }
      }

      expect(getAnimalName(1, testAnimals), equals('Vaca1'));
      expect(getAnimalName(999, testAnimals), equals('Animal #999'));
    });
  });
}
