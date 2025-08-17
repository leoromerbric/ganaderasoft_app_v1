import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:ganaderasoft_app_v1/models/configuration_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Configuration Database Tests', () {
    test('should save and retrieve estados de salud offline', () async {
      // Create test data
      final estados = [
        EstadoSalud(
          estadoId: 1,
          estadoNombre: 'Sano',
          synced: true,
        ),
        EstadoSalud(
          estadoId: 2,
          estadoNombre: 'Enfermo',
          synced: false,
        ),
      ];

      // Save data
      await DatabaseService.saveEstadosSaludOffline(estados);

      // Retrieve data
      final retrievedEstados = await DatabaseService.getEstadosSaludOffline();

      // Verify
      expect(retrievedEstados, isNotEmpty);
      expect(retrievedEstados.length, equals(2));
      expect(retrievedEstados[0].estadoNombre, equals('Enfermo')); // Should be ordered by name
      expect(retrievedEstados[1].estadoNombre, equals('Sano'));
      expect(retrievedEstados[0].synced, isFalse);
      expect(retrievedEstados[1].synced, isTrue);
    });

    test('should save and retrieve tipos de animal offline', () async {
      // Create test data
      final tipos = [
        TipoAnimal(
          tipoAnimalId: 1,
          tipoAnimalNombre: 'Vacuno',
          synced: true,
        ),
        TipoAnimal(
          tipoAnimalId: 2,
          tipoAnimalNombre: 'Bufala',
          synced: false,
        ),
      ];

      // Save data
      await DatabaseService.saveTiposAnimalOffline(tipos);

      // Retrieve data
      final retrievedTipos = await DatabaseService.getTiposAnimalOffline();

      // Verify
      expect(retrievedTipos, isNotEmpty);
      expect(retrievedTipos.length, equals(2));
      expect(retrievedTipos[0].tipoAnimalNombre, equals('Bufala')); // Should be ordered by name
      expect(retrievedTipos[1].tipoAnimalNombre, equals('Vacuno'));
    });

    test('should save and retrieve etapas offline', () async {
      // Create test data
      final tipoAnimal = TipoAnimal(
        tipoAnimalId: 1,
        tipoAnimalNombre: 'Vacuno',
      );

      final etapas = [
        Etapa(
          etapaId: 1,
          etapaNombre: 'Becerro',
          etapaEdadIni: 0,
          etapaEdadFin: 365,
          etapaFkTipoAnimalId: 1,
          etapaSexo: 'M',
          tipoAnimal: tipoAnimal,
          synced: true,
        ),
      ];

      // Save data
      await DatabaseService.saveEtapasOffline(etapas);

      // Retrieve data
      final retrievedEtapas = await DatabaseService.getEtapasOffline();

      // Verify
      expect(retrievedEtapas, isNotEmpty);
      expect(retrievedEtapas.length, equals(1));
      expect(retrievedEtapas[0].etapaNombre, equals('Becerro'));
      expect(retrievedEtapas[0].etapaEdadIni, equals(0));
      expect(retrievedEtapas[0].etapaEdadFin, equals(365));
      expect(retrievedEtapas[0].tipoAnimal.tipoAnimalNombre, equals('Vacuno'));
    });

    test('should save and retrieve fuente agua offline', () async {
      // Create test data
      final fuenteAgua = [
        FuenteAgua(
          codigo: 'superficial',
          nombre: 'Superficial',
          synced: true,
        ),
        FuenteAgua(
          codigo: 'subterranea',
          nombre: 'Subterránea',
          synced: false,
        ),
      ];

      // Save data
      await DatabaseService.saveFuenteAguaOffline(fuenteAgua);

      // Retrieve data
      final retrievedFuenteAgua = await DatabaseService.getFuenteAguaOffline();

      // Verify
      expect(retrievedFuenteAgua, isNotEmpty);
      expect(retrievedFuenteAgua.length, equals(2));
      expect(retrievedFuenteAgua[0].nombre, equals('Subterránea')); // Should be ordered by name
      expect(retrievedFuenteAgua[1].nombre, equals('Superficial'));
    });

    test('should save and retrieve pH suelo offline', () async {
      // Create test data
      final phSuelo = [
        PhSuelo(
          codigo: '7',
          nombre: '7',
          descripcion: 'Neutro',
          synced: true,
        ),
        PhSuelo(
          codigo: '6',
          nombre: '6',
          descripcion: 'Ligeramente ácido',
          synced: false,
        ),
      ];

      // Save data
      await DatabaseService.savePhSueloOffline(phSuelo);

      // Retrieve data
      final retrievedPhSuelo = await DatabaseService.getPhSueloOffline();

      // Verify
      expect(retrievedPhSuelo, isNotEmpty);
      expect(retrievedPhSuelo.length, equals(2));
      expect(retrievedPhSuelo[0].descripcion, contains('ácido'));
      expect(retrievedPhSuelo[1].descripcion, equals('Neutro'));
    });

    test('should save and retrieve tipo relieve offline', () async {
      // Create test data
      final tipoRelieve = [
        TipoRelieve(
          id: 1,
          valor: 'Plano',
          descripcion: 'Terreno plano sin pendientes significativas',
          synced: true,
        ),
        TipoRelieve(
          id: 2,
          valor: 'Ondulado',
          descripcion: 'Terreno con ondulaciones suaves',
          synced: false,
        ),
      ];

      // Save data
      await DatabaseService.saveTipoRelieveOffline(tipoRelieve);

      // Retrieve data
      final retrievedTipoRelieve = await DatabaseService.getTipoRelieveOffline();

      // Verify
      expect(retrievedTipoRelieve, isNotEmpty);
      expect(retrievedTipoRelieve.length, equals(2));
      expect(retrievedTipoRelieve[0].valor, equals('Ondulado')); // Should be ordered by valor
      expect(retrievedTipoRelieve[1].valor, equals('Plano'));
    });

    test('should handle database operations for all simple configuration types', () async {
      // Test Sexo
      final sexoData = [
        Sexo(codigo: 'M', nombre: 'Macho', synced: true),
        Sexo(codigo: 'H', nombre: 'Hembra', synced: false),
      ];
      await DatabaseService.saveSexoOffline(sexoData);
      final retrievedSexo = await DatabaseService.getSexoOffline();
      expect(retrievedSexo.length, equals(2));

      // Test Método Riego
      final metodoRiegoData = [
        MetodoRiego(codigo: 'aspersion', nombre: 'Aspersión', synced: true),
        MetodoRiego(codigo: 'goteo', nombre: 'Goteo', synced: false),
      ];
      await DatabaseService.saveMetodoRiegoOffline(metodoRiegoData);
      final retrievedMetodoRiego = await DatabaseService.getMetodoRiegoOffline();
      expect(retrievedMetodoRiego.length, equals(2));

      // Test Textura Suelo
      final texturaSueloData = [
        TexturaSuelo(codigo: 'arcilla', nombre: 'Arcilla', synced: true),
        TexturaSuelo(codigo: 'franco', nombre: 'Franco', synced: false),
      ];
      await DatabaseService.saveTexturaSueloOffline(texturaSueloData);
      final retrievedTexturaSuelo = await DatabaseService.getTexturaSueloOffline();
      expect(retrievedTexturaSuelo.length, equals(2));

      // Test Tipo Explotación
      final tipoExplotacionData = [
        TipoExplotacion(codigo: 'intensiva', nombre: 'Intensiva', synced: true),
        TipoExplotacion(codigo: 'extensiva', nombre: 'Extensiva', synced: false),
      ];
      await DatabaseService.saveTipoExplotacionOffline(tipoExplotacionData);
      final retrievedTipoExplotacion = await DatabaseService.getTipoExplotacionOffline();
      expect(retrievedTipoExplotacion.length, equals(2));
    });

    test('should clear all configuration data', () async {
      // Save some test data first
      await DatabaseService.saveEstadosSaludOffline([
        EstadoSalud(estadoId: 1, estadoNombre: 'Sano'),
      ]);
      await DatabaseService.saveFuenteAguaOffline([
        FuenteAgua(codigo: 'test', nombre: 'Test'),
      ]);

      // Verify data exists
      expect((await DatabaseService.getEstadosSaludOffline()).length, equals(1));
      expect((await DatabaseService.getFuenteAguaOffline()).length, equals(1));

      // Clear all data
      await DatabaseService.clearAllData();

      // Verify all data is cleared
      expect((await DatabaseService.getEstadosSaludOffline()).length, equals(0));
      expect((await DatabaseService.getFuenteAguaOffline()).length, equals(0));
    });
  });

  group('Configuration Models Tests', () {
    test('should serialize and deserialize EstadoSalud correctly', () async {
      final estado = EstadoSalud(
        estadoId: 15,
        estadoNombre: 'Sano',
        synced: true,
      );

      final json = estado.toJson();
      final recreated = EstadoSalud.fromJson(json);

      expect(recreated.estadoId, equals(estado.estadoId));
      expect(recreated.estadoNombre, equals(estado.estadoNombre));
      expect(recreated.synced, equals(estado.synced));
    });

    test('should serialize and deserialize Etapa with nested TipoAnimal correctly', () async {
      final tipoAnimal = TipoAnimal(
        tipoAnimalId: 3,
        tipoAnimalNombre: 'Vacuno',
      );

      final etapa = Etapa(
        etapaId: 16,
        etapaNombre: 'Ternero',
        etapaEdadIni: 0,
        etapaEdadFin: 365,
        etapaFkTipoAnimalId: 3,
        etapaSexo: 'M',
        tipoAnimal: tipoAnimal,
        synced: true,
      );

      final json = etapa.toJson();
      final recreated = Etapa.fromJson(json);

      expect(recreated.etapaId, equals(etapa.etapaId));
      expect(recreated.etapaNombre, equals(etapa.etapaNombre));
      expect(recreated.tipoAnimal.tipoAnimalNombre, equals('Vacuno'));
      expect(recreated.synced, equals(etapa.synced));
    });

    test('should serialize and deserialize PhSuelo correctly', () async {
      final phSuelo = PhSuelo(
        codigo: '7',
        nombre: '7',
        descripcion: 'Neutro',
        synced: false,
      );

      final json = phSuelo.toJson();
      final recreated = PhSuelo.fromJson(json);

      expect(recreated.codigo, equals(phSuelo.codigo));
      expect(recreated.nombre, equals(phSuelo.nombre));
      expect(recreated.descripcion, equals(phSuelo.descripcion));
      expect(recreated.synced, equals(phSuelo.synced));
    });

    test('should handle nullable fields correctly', () async {
      final etapa = Etapa(
        etapaId: 16,
        etapaNombre: 'Adulto',
        etapaEdadIni: 730,
        etapaEdadFin: null, // null end age
        etapaFkTipoAnimalId: 3,
        etapaSexo: 'M',
        tipoAnimal: TipoAnimal(tipoAnimalId: 3, tipoAnimalNombre: 'Vacuno'),
      );

      final json = etapa.toJson();
      final recreated = Etapa.fromJson(json);

      expect(recreated.etapaEdadFin, isNull);
      expect(recreated.etapaEdadIni, equals(730));
    });
  });
}