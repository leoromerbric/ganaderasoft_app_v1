import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/models/animal.dart';
import 'package:ganaderasoft_app_v1/models/finca.dart';
import 'package:ganaderasoft_app_v1/models/farm_management_models.dart';

void main() {
  group('Finca Filtering Tests', () {
    late List<Animal> fincaAnimales;
    late List<Lactancia> lactancias;
    late List<CambiosAnimal> cambios;

    setUp(() {
      // Create test animals for finca
      fincaAnimales = [
        Animal(
          idAnimal: 1,
          idRebano: 1,
          nombre: 'Vaca 1',
          codigoAnimal: 'V001',
          sexo: 'F',
          fechaNacimiento: '2020-01-01',
          procedencia: 'Propia',
          archivado: false,
          createdAt: '2023-01-01',
          updatedAt: '2023-01-01',
          fkComposicionRaza: 1,
        ),
        Animal(
          idAnimal: 2,
          idRebano: 1,
          nombre: 'Vaca 2',
          codigoAnimal: 'V002',
          sexo: 'F',
          fechaNacimiento: '2020-02-01',
          procedencia: 'Propia',
          archivado: false,
          createdAt: '2023-01-01',
          updatedAt: '2023-01-01',
          fkComposicionRaza: 1,
        ),
      ];

      // Create test lactancias - some belong to finca animals, some don't
      lactancias = [
        Lactancia(
          lactanciaId: 1,
          lactanciaFechaInicio: '2023-01-01',
          lactanciaFechaFin: '2023-06-01',
          createdAt: '2023-01-01',
          updatedAt: '2023-01-01',
          lactanciaEtapaAnid: 1, // Belongs to finca animal
          lactanciaEtapaEtid: 1,
        ),
        Lactancia(
          lactanciaId: 2,
          lactanciaFechaInicio: '2023-02-01',
          createdAt: '2023-02-01',
          updatedAt: '2023-02-01',
          lactanciaEtapaAnid: 2, // Belongs to finca animal
          lactanciaEtapaEtid: 1,
        ),
        Lactancia(
          lactanciaId: 3,
          lactanciaFechaInicio: '2023-03-01',
          createdAt: '2023-03-01',
          updatedAt: '2023-03-01',
          lactanciaEtapaAnid: 999, // Does NOT belong to finca animals
          lactanciaEtapaEtid: 1,
        ),
      ];

      // Create test cambios - some belong to finca animals, some don't
      cambios = [
        CambiosAnimal(
          idCambio: 1,
          fechaCambio: '2023-01-01',
          etapaCambio: 'Lactancia',
          peso: 500.0,
          altura: 150.0,
          comentario: 'Cambio 1',
          createdAt: '2023-01-01',
          updatedAt: '2023-01-01',
          cambiosEtapaAnid: 1, // Belongs to finca animal
          cambiosEtapaEtid: 1,
        ),
        CambiosAnimal(
          idCambio: 2,
          fechaCambio: '2023-02-01',
          etapaCambio: 'Desarrollo',
          peso: 520.0,
          altura: 155.0,
          comentario: 'Cambio 2',
          createdAt: '2023-02-01',
          updatedAt: '2023-02-01',
          cambiosEtapaAnid: 2, // Belongs to finca animal
          cambiosEtapaEtid: 1,
        ),
        CambiosAnimal(
          idCambio: 3,
          fechaCambio: '2023-03-01',
          etapaCambio: 'Finalizado',
          peso: 600.0,
          altura: 160.0,
          comentario: 'Cambio 3',
          createdAt: '2023-03-01',
          updatedAt: '2023-03-01',
          cambiosEtapaAnid: 999, // Does NOT belong to finca animals
          cambiosEtapaEtid: 1,
        ),
      ];
    });

    test('Lactancia filtering should only show records for finca animals', () {
      // Get finca animal IDs
      final fincaAnimalIds = fincaAnimales.map((animal) => animal.idAnimal).toSet();

      // Filter lactancias
      final filteredLactancias = lactancias
          .where((lactancia) => fincaAnimalIds.contains(lactancia.lactanciaEtapaAnid))
          .toList();

      // Should only have 2 lactancias (those with animalIds 1 and 2)
      expect(filteredLactancias.length, 2);
      expect(filteredLactancias.any((l) => l.lactanciaEtapaAnid == 1), true);
      expect(filteredLactancias.any((l) => l.lactanciaEtapaAnid == 2), true);
      expect(filteredLactancias.any((l) => l.lactanciaEtapaAnid == 999), false);
    });

    test('Cambios filtering should only show records for finca animals', () {
      // Get finca animal IDs
      final fincaAnimalIds = fincaAnimales.map((animal) => animal.idAnimal).toSet();

      // Filter cambios
      final filteredCambios = cambios
          .where((cambio) => fincaAnimalIds.contains(cambio.cambiosEtapaAnid))
          .toList();

      // Should only have 2 cambios (those with animalIds 1 and 2)
      expect(filteredCambios.length, 2);
      expect(filteredCambios.any((c) => c.cambiosEtapaAnid == 1), true);
      expect(filteredCambios.any((c) => c.cambiosEtapaAnid == 2), true);
      expect(filteredCambios.any((c) => c.cambiosEtapaAnid == 999), false);
    });

    test('Combined filtering - by finca and specific animal', () {
      // Get finca animal IDs
      final fincaAnimalIds = fincaAnimales.map((animal) => animal.idAnimal).toSet();

      // First filter by finca animals
      var filteredLactancias = lactancias
          .where((lactancia) => fincaAnimalIds.contains(lactancia.lactanciaEtapaAnid))
          .toList();

      // Then filter by specific animal (animal with ID 1)
      filteredLactancias = filteredLactancias
          .where((lactancia) => lactancia.lactanciaEtapaAnid == 1)
          .toList();

      // Should only have 1 lactancia (for animal 1)
      expect(filteredLactancias.length, 1);
      expect(filteredLactancias.first.lactanciaEtapaAnid, 1);
    });

    test('Empty finca animals should result in empty filtered lists', () {
      final emptyAnimalIds = <int>{};

      final filteredLactancias = lactancias
          .where((lactancia) => emptyAnimalIds.contains(lactancia.lactanciaEtapaAnid))
          .toList();

      final filteredCambios = cambios
          .where((cambio) => emptyAnimalIds.contains(cambio.cambiosEtapaAnid))
          .toList();

      expect(filteredLactancias.length, 0);
      expect(filteredCambios.length, 0);
    });
  });
}