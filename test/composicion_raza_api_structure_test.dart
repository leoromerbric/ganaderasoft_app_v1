import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/models/configuration_models.dart';

void main() {
  group('ComposicionRazaResponse API Structure Tests', () {
    test('should parse response from actual composicion-raza API structure', () {
      // This is the actual structure returned by the composicion-raza API
      final actualApiResponse = {
        'success': true,
        'message': 'Lista de composiciones de raza obtenida exitosamente',
        'data': [
          {
            'id_Composicion': 70,
            'Nombre': 'Shortorn',
            'Siglas': 'SHO',
            'Pelaje': 'Rojo-Blanco',
            'Proposito': 'Doble',
            'Tipo_Raza': 'Bos Taurus',
            'Origen': 'Noroeste Inglaterra',
            'Caracteristica_Especial': 'Adaptabilidad',
            'Proporcion_Raza': 'Grande',
            'created_at': null,
            'updated_at': null,
            'fk_id_Finca': null,
            'fk_tipo_animal_id': null,
            'finca': null,
            'tipo_animal': null
          },
          {
            'id_Composicion': 71,
            'Nombre': 'Hereford',
            'Siglas': 'HER',
            'Pelaje': 'Colorado Bayo y manchas blancas en la cabeza',
            'Proposito': 'Carne',
            'Tipo_Raza': 'Bos Taurus',
            'Origen': 'Suroeste Inglaterra',
            'Caracteristica_Especial': 'madurez precoz',
            'Proporcion_Raza': 'Grande',
            'created_at': null,
            'updated_at': null,
            'fk_id_Finca': null,
            'fk_tipo_animal_id': null,
            'finca': null,
            'tipo_animal': null
          }
        ],
        'pagination': {
          'current_page': 1,
          'last_page': 2,
          'per_page': 15,
          'total': 23
        }
      };

      // This should not throw "type 'List' is not a subtype of type 'Map'"
      final response = ComposicionRazaResponse.fromJson(actualApiResponse);

      // Verify the response was parsed correctly
      expect(response.success, isTrue);
      expect(response.message, equals('Lista de composiciones de raza obtenida exitosamente'));

      // Verify pagination data was extracted correctly
      expect(response.data.currentPage, equals(1));
      expect(response.data.total, equals(23));
      expect(response.data.perPage, equals(15));

      // Verify breed data
      expect(response.data.data, hasLength(2));

      final shortorn = response.data.data[0];
      expect(shortorn.idComposicion, equals(70));
      expect(shortorn.nombre, equals('Shortorn'));
      expect(shortorn.siglas, equals('SHO'));
      expect(shortorn.pelaje, equals('Rojo-Blanco'));
      expect(shortorn.fkIdFinca, isNull);
      expect(shortorn.fkTipoAnimalId, isNull);

      final hereford = response.data.data[1];
      expect(hereford.idComposicion, equals(71));
      expect(hereford.nombre, equals('Hereford'));
      expect(hereford.caracteristicaEspecial, equals('madurez precoz'));
    });

    test('should handle API response without pagination object', () {
      // Handle case where pagination object might be missing
      final responseWithoutPagination = {
        'success': true,
        'message': 'Lista de composiciones de raza obtenida exitosamente',
        'data': [
          {
            'id_Composicion': 99,
            'Nombre': 'Test Breed',
            'Siglas': 'TST',
            'Pelaje': 'Test Color',
            'Proposito': 'Test Purpose',
            'Tipo_Raza': 'Test Type',
            'Origen': 'Test Origin',
            'Caracteristica_Especial': 'Test Feature',
            'Proporcion_Raza': 'Test Size',
            'created_at': null,
            'updated_at': null,
            'fk_id_Finca': null,
            'fk_tipo_animal_id': null
          }
        ]
        // No pagination object
      };

      final response = ComposicionRazaResponse.fromJson(responseWithoutPagination);

      expect(response.success, isTrue);
      expect(response.data.currentPage, equals(1)); // Default value
      expect(response.data.total, equals(1)); // Should default to data length
      expect(response.data.perPage, equals(1)); // Should default to data length
      expect(response.data.data, hasLength(1));

      final breed = response.data.data[0];
      expect(breed.idComposicion, equals(99));
      expect(breed.nombre, equals('Test Breed'));
    });

    test('should still work with standard paginated format for backwards compatibility', () {
      // Test that it still works with the expected format from other APIs
      final standardApiResponse = {
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
              'created_at': '2023-01-01T00:00:00.000000Z',
              'updated_at': '2023-01-01T00:00:00.000000Z',
              'fk_id_Finca': null,
              'fk_tipo_animal_id': null
            }
          ],
          'total': 1,
          'per_page': 50,
        }
      };

      final response = ComposicionRazaResponse.fromJson(standardApiResponse);

      expect(response.success, isTrue);
      expect(response.data.currentPage, equals(1));
      expect(response.data.total, equals(1));
      expect(response.data.perPage, equals(50));
      expect(response.data.data, hasLength(1));

      final holstein = response.data.data[0];
      expect(holstein.nombre, equals('Holstein'));
    });
  });
}