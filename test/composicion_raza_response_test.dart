import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/models/configuration_models.dart';

void main() {
  group('ComposicionRazaResponse JSON Parsing Tests', () {
    test('should parse ComposicionRazaResponse from API-like JSON structure', () {
      // Simulate a typical API response structure for composicion raza
      final apiResponseJson = {
        'success': true,
        'message': 'Composicion raza fetched successfully',
        'data': {
          'current_page': 1,
          'data': [
            {
              'id_Composicion': 1,
              'Nombre': 'Holstein',
              'Siglas': 'HOL',
              'Pelaje': 'Negro y Blanco',
              'Proposito': 'Leche',
              'Tipo_Raza': 'Bos Taurus',
              'Origen': 'Holanda',
              'Caracteristica_Especial': 'Alta producción láctea',
              'Proporcion_Raza': 'Grande',
              'created_at': '2024-01-01T00:00:00.000000Z',
              'updated_at': '2024-01-01T00:00:00.000000Z',
              'fk_id_Finca': null,
              'fk_tipo_animal_id': null,
              'synced': false,
            },
            {
              'id_Composicion': 2,
              'Nombre': 'Angus',
              'Siglas': 'ANG',
              'Pelaje': 'Negro',
              'Proposito': 'Carne',
              'Tipo_Raza': 'Bos Taurus',
              'Origen': 'Escocia',
              'Caracteristica_Especial': 'Marmoleo',
              'Proporcion_Raza': 'Mediano',
              'created_at': null,
              'updated_at': null,
              'fk_id_Finca': null,
              'fk_tipo_animal_id': null,
              'synced': false,
            }
          ],
          'total': 2,
          'per_page': 50,
        }
      };

      // This should not throw an error
      final response = ComposicionRazaResponse.fromJson(apiResponseJson);

      // Verify the response structure
      expect(response.success, isTrue);
      expect(response.message, equals('Composicion raza fetched successfully'));
      expect(response.data.currentPage, equals(1));
      expect(response.data.total, equals(2));
      expect(response.data.perPage, equals(50));
      expect(response.data.data, hasLength(2));

      // Verify first item
      final firstItem = response.data.data[0];
      expect(firstItem.idComposicion, equals(1));
      expect(firstItem.nombre, equals('Holstein'));
      expect(firstItem.siglas, equals('HOL'));
      expect(firstItem.fkIdFinca, isNull);
      expect(firstItem.fkTipoAnimalId, isNull);

      // Verify second item with null timestamps
      final secondItem = response.data.data[1];
      expect(secondItem.idComposicion, equals(2));
      expect(secondItem.nombre, equals('Angus'));
      expect(secondItem.createdAt, isNull);
      expect(secondItem.updatedAt, isNull);
    });

    test('should handle empty data array', () {
      final apiResponseJson = {
        'success': true,
        'message': 'No composicion raza found',
        'data': {
          'current_page': 1,
          'data': [],
          'total': 0,
          'per_page': 50,
        }
      };

      final response = ComposicionRazaResponse.fromJson(apiResponseJson);

      expect(response.success, isTrue);
      expect(response.data.data, isEmpty);
      expect(response.data.total, equals(0));
    });

    test('should handle missing optional fields in individual items', () {
      final apiResponseJson = {
        'success': true,
        'message': 'Composicion raza fetched successfully',
        'data': {
          'current_page': 1,
          'data': [
            {
              'id_Composicion': 10,
              'Nombre': 'Minimal Breed',
              'Siglas': 'MIN',
              'Pelaje': 'Various',
              'Proposito': 'Mixed',
              'Tipo_Raza': 'Mixed',
              'Origen': 'Unknown',
              'Caracteristica_Especial': 'Adaptable',
              'Proporcion_Raza': 'Small',
              // Missing created_at, updated_at, fk_id_Finca, fk_tipo_animal_id, synced
            }
          ],
          'total': 1,
          'per_page': 50,
        }
      };

      final response = ComposicionRazaResponse.fromJson(apiResponseJson);
      final item = response.data.data[0];

      expect(item.idComposicion, equals(10));
      expect(item.nombre, equals('Minimal Breed'));
      expect(item.createdAt, isNull);
      expect(item.updatedAt, isNull);
      expect(item.fkIdFinca, isNull);
      expect(item.fkTipoAnimalId, isNull);
      expect(item.synced, isFalse); // Should default to false
    });
  });
}