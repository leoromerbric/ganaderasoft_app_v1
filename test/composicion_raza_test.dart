import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:ganaderasoft_app_v1/models/configuration_models.dart';

void main() {
  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  });

  group('ComposicionRaza Database Tests', () {
    test('should save and retrieve composicion raza offline', () async {
      // Create test data
      final composicionRaza = [
        ComposicionRaza(
          idComposicion: 1,
          nombre: 'Aberdeen Angus',
          siglas: 'ANG',
          pelaje: 'Negro o Rojo',
          proposito: 'Carne',
          tipoRaza: 'Bos Taurus',
          origen: 'Escocia',
          caracteristicaEspecial: 'longevidad',
          proporcionRaza: 'Grande',
          synced: true,
        ),
        ComposicionRaza(
          idComposicion: 2,
          nombre: 'Nelore',
          siglas: 'NEL',
          pelaje: 'Blanco',
          proposito: 'Doble',
          tipoRaza: 'Bos Indicus',
          origen: 'Madras - India',
          caracteristicaEspecial: 'Rusticidad',
          proporcionRaza: 'Grande',
          synced: false,
        ),
      ];

      // Save data
      await DatabaseService.saveComposicionRazaOffline(composicionRaza);

      // Retrieve data
      final retrievedComposicionRaza = await DatabaseService.getComposicionRazaOffline();

      // Verify
      expect(retrievedComposicionRaza, isNotEmpty);
      expect(retrievedComposicionRaza.length, equals(2));
      expect(retrievedComposicionRaza[0].nombre, equals('Aberdeen Angus')); // Should be ordered by name
      expect(retrievedComposicionRaza[1].nombre, equals('Nelore'));
      expect(retrievedComposicionRaza[0].synced, isTrue);
      expect(retrievedComposicionRaza[1].synced, isFalse);
      expect(retrievedComposicionRaza[0].siglas, equals('ANG'));
      expect(retrievedComposicionRaza[1].siglas, equals('NEL'));
    });

    test('should handle empty composicion raza list', () async {
      // Save empty list
      await DatabaseService.saveComposicionRazaOffline([]);

      // Retrieve data
      final retrievedComposicionRaza = await DatabaseService.getComposicionRazaOffline();

      // Verify
      expect(retrievedComposicionRaza, isEmpty);
    });

    test('should properly store all composicion raza fields', () async {
      // Create comprehensive test data
      final composicion = ComposicionRaza(
        idComposicion: 99,
        nombre: 'Test Breed',
        siglas: 'TST',
        pelaje: 'Test Color',
        proposito: 'Test Purpose',
        tipoRaza: 'Test Type',
        origen: 'Test Origin',
        caracteristicaEspecial: 'Test Characteristic',
        proporcionRaza: 'Test Proportion',
        createdAt: '2025-01-01T00:00:00.000000Z',
        updatedAt: '2025-01-02T00:00:00.000000Z',
        fkIdFinca: 15,
        fkTipoAnimalId: 3,
        synced: true,
      );

      // Save data
      await DatabaseService.saveComposicionRazaOffline([composicion]);

      // Retrieve data
      final retrieved = await DatabaseService.getComposicionRazaOffline();

      // Verify all fields
      expect(retrieved, hasLength(1));
      final item = retrieved.first;
      expect(item.idComposicion, equals(99));
      expect(item.nombre, equals('Test Breed'));
      expect(item.siglas, equals('TST'));
      expect(item.pelaje, equals('Test Color'));
      expect(item.proposito, equals('Test Purpose'));
      expect(item.tipoRaza, equals('Test Type'));
      expect(item.origen, equals('Test Origin'));
      expect(item.caracteristicaEspecial, equals('Test Characteristic'));
      expect(item.proporcionRaza, equals('Test Proportion'));
      expect(item.createdAt, equals('2025-01-01T00:00:00.000000Z'));
      expect(item.updatedAt, equals('2025-01-02T00:00:00.000000Z'));
      expect(item.fkIdFinca, equals(15));
      expect(item.fkTipoAnimalId, equals(3));
      expect(item.synced, isTrue);
    });

    test('should handle null fkIdFinca and fkTipoAnimalId fields correctly', () async {
      // Create test data with null foreign key fields (like API data)
      final composicion = ComposicionRaza(
        idComposicion: 100,
        nombre: 'API Breed',
        siglas: 'API',
        pelaje: 'API Color',
        proposito: 'API Purpose',
        tipoRaza: 'API Type',
        origen: 'API Origin',
        caracteristicaEspecial: 'API Characteristic',
        proporcionRaza: 'API Proportion',
        createdAt: null,
        updatedAt: null,
        fkIdFinca: null, // These fields can be null from API
        fkTipoAnimalId: null, // These fields can be null from API
        synced: false,
      );

      // Save data
      await DatabaseService.saveComposicionRazaOffline([composicion]);

      // Retrieve data - this should not throw an error
      final retrieved = await DatabaseService.getComposicionRazaOffline();

      // Verify all fields including null ones
      expect(retrieved, hasLength(1));
      final item = retrieved.first;
      expect(item.idComposicion, equals(100));
      expect(item.nombre, equals('API Breed'));
      expect(item.fkIdFinca, isNull); // Should be null
      expect(item.fkTipoAnimalId, isNull); // Should be null
      expect(item.createdAt, isNull);
      expect(item.updatedAt, isNull);
      expect(item.synced, isFalse);
    });
  });
}