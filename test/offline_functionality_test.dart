import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:ganaderasoft_app_v1/models/farm_management_models.dart';

void main() {
  setUpAll(() {
    // Initialize the ffi loader if needed.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Offline Farm Management Data Tests', () {
    test('should save and retrieve CambiosAnimal offline', () async {
      // Create test data
      final testCambio = CambiosAnimal(
        idCambio: 1,
        fechaCambio: '2024-01-01',
        etapaCambio: 'Test Stage',
        peso: 50.0,
        altura: 120.0,
        comentario: 'Test comment',
        createdAt: '2024-01-01T10:00:00Z',
        updatedAt: '2024-01-01T10:00:00Z',
        cambiosEtapaAnid: 1,
        cambiosEtapaEtid: 2,
      );

      // Save offline
      await DatabaseService.saveCambiosAnimalOffline([testCambio]);

      // Retrieve offline
      final retrievedCambios = await DatabaseService.getCambiosAnimalOffline();

      // Verify
      expect(retrievedCambios.length, 1);
      expect(retrievedCambios.first.idCambio, testCambio.idCambio);
      expect(retrievedCambios.first.fechaCambio, testCambio.fechaCambio);
      expect(retrievedCambios.first.peso, testCambio.peso);
    });

    test('should save and retrieve Lactancia offline', () async {
      // Create test data
      final testLactancia = Lactancia(
        lactanciaId: 1,
        lactanciaFechaInicio: '2024-01-01',
        lactanciaFechaFin: null,
        lactanciaSecado: null,
        createdAt: '2024-01-01T10:00:00Z',
        updatedAt: '2024-01-01T10:00:00Z',
        lactanciaEtapaAnid: 1,
        lactanciaEtapaEtid: 2,
      );

      // Save offline
      await DatabaseService.saveLactanciaOffline([testLactancia]);

      // Retrieve offline
      final retrievedLactancia = await DatabaseService.getLactanciaOffline();

      // Verify
      expect(retrievedLactancia.length, 1);
      expect(retrievedLactancia.first.lactanciaId, testLactancia.lactanciaId);
      expect(retrievedLactancia.first.lactanciaFechaInicio, testLactancia.lactanciaFechaInicio);
    });

    test('should save and retrieve PesoCorporal offline', () async {
      // Create test data
      final testPeso = PesoCorporal(
        idPeso: 1,
        fechaPeso: '2024-01-01',
        peso: 75.5,
        comentario: 'Test weight comment',
        createdAt: '2024-01-01T10:00:00Z',
        updatedAt: '2024-01-01T10:00:00Z',
        pesoEtapaAnid: 1,
        pesoEtapaEtid: 2,
      );

      // Save offline
      await DatabaseService.savePesoCorporalOffline([testPeso]);

      // Retrieve offline
      final retrievedPesos = await DatabaseService.getPesoCorporalOffline();

      // Verify
      expect(retrievedPesos.length, 1);
      expect(retrievedPesos.first.idPeso, testPeso.idPeso);
      expect(retrievedPesos.first.peso, testPeso.peso);
      expect(retrievedPesos.first.comentario, testPeso.comentario);
    });

    test('should save and retrieve PersonalFinca offline', () async {
      // Create test data
      final testPersonal = PersonalFinca(
        idTecnico: 1,
        idFinca: 1,
        cedula: 12345678,
        nombre: 'Juan',
        apellido: 'Pérez',
        telefono: '1234567890',
        correo: 'juan@test.com',
        tipoTrabajador: 'Otro',
        createdAt: '2024-01-01T10:00:00Z',
        updatedAt: '2024-01-01T10:00:00Z',
      );

      // Save offline
      await DatabaseService.savePersonalFincaOffline([testPersonal]);

      // Retrieve offline
      final retrievedPersonal = await DatabaseService.getPersonalFincaOffline();

      // Verify
      expect(retrievedPersonal.length, 1);
      expect(retrievedPersonal.first.idTecnico, testPersonal.idTecnico);
      expect(retrievedPersonal.first.nombre, testPersonal.nombre);
      expect(retrievedPersonal.first.tipoTrabajador, 'Otro');
    });

    test('should filter data by animalId', () async {
      // Create test data for different animals
      final testCambios = [
        CambiosAnimal(
          idCambio: 1,
          fechaCambio: '2024-01-01',
          etapaCambio: 'Test Stage',
          peso: 50.0,
          altura: 120.0,
          comentario: 'Animal 1',
          createdAt: '2024-01-01T10:00:00Z',
          updatedAt: '2024-01-01T10:00:00Z',
          cambiosEtapaAnid: 1, // Animal 1
          cambiosEtapaEtid: 2,
        ),
        CambiosAnimal(
          idCambio: 2,
          fechaCambio: '2024-01-02',
          etapaCambio: 'Test Stage 2',
          peso: 60.0,
          altura: 130.0,
          comentario: 'Animal 2',
          createdAt: '2024-01-02T10:00:00Z',
          updatedAt: '2024-01-02T10:00:00Z',
          cambiosEtapaAnid: 2, // Animal 2
          cambiosEtapaEtid: 3,
        ),
      ];

      // Save offline
      await DatabaseService.saveCambiosAnimalOffline(testCambios);

      // Retrieve with filter
      final animal1Cambios = await DatabaseService.getCambiosAnimalOffline(animalId: 1);
      final animal2Cambios = await DatabaseService.getCambiosAnimalOffline(animalId: 2);

      // Verify filtering
      expect(animal1Cambios.length, 1);
      expect(animal1Cambios.first.comentario, 'Animal 1');
      expect(animal2Cambios.length, 1);
      expect(animal2Cambios.first.comentario, 'Animal 2');
    });
  });
}