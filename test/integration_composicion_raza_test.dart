import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/models/configuration_models.dart';

void main() {
  group('Integration: ConfigurationService ComposicionRaza Fix', () {
    test('should successfully parse real API response structure', () {
      // This simulates the actual API response structure that was causing the error
      // Based on the error logs, the server returns a 200 response but with this structure
      final mockApiResponse = {
        'success': true,
        'message': 'Datos obtenidos correctamente',
        'data': {
          'current_page': 1,
          'data': [
            {
              'id_Composicion': 1,
              'Nombre': 'Holstein Friesian',
              'Siglas': 'HOL',
              'Pelaje': 'Negro y Blanco',
              'Proposito': 'Leche',
              'Tipo_Raza': 'Bos Taurus',
              'Origen': 'Países Bajos',
              'Caracteristica_Especial': 'Alta producción láctea',
              'Proporcion_Raza': 'Grande',
              'created_at': '2024-01-15T10:30:00.000000Z',
              'updated_at': '2024-01-15T10:30:00.000000Z',
              'fk_id_Finca': null,
              'fk_tipo_animal_id': null,
              'synced': false,
            },
            {
              'id_Composicion': 2,
              'Nombre': 'Aberdeen Angus',
              'Siglas': 'ANG',
              'Pelaje': 'Negro',
              'Proposito': 'Carne',
              'Tipo_Raza': 'Bos Taurus',
              'Origen': 'Escocia',
              'Caracteristica_Especial': 'Marmoleo excelente',
              'Proporcion_Raza': 'Mediano',
              'created_at': null, // API can return null timestamps
              'updated_at': null,
              'fk_id_Finca': null, // API returns null for these foreign keys
              'fk_tipo_animal_id': null,
              'synced': false,
            }
          ],
          'total': 2,
          'per_page': 50,
          'last_page': 1,
          'from': 1,
          'to': 2
        }
      };

      // This should now work without throwing "type 'Null' is not a subtype of type 'int'"
      final response = ComposicionRazaResponse.fromJson(mockApiResponse);

      // Verify the response was parsed correctly
      expect(response.success, isTrue);
      expect(response.message, equals('Datos obtenidos correctamente'));

      // Verify pagination data
      expect(response.data.currentPage, equals(1));
      expect(response.data.total, equals(2));
      expect(response.data.perPage, equals(50));

      // Verify breed data
      expect(response.data.data, hasLength(2));

      final holstein = response.data.data[0];
      expect(holstein.idComposicion, equals(1));
      expect(holstein.nombre, equals('Holstein Friesian'));
      expect(holstein.siglas, equals('HOL'));
      expect(holstein.fkIdFinca, isNull);
      expect(holstein.fkTipoAnimalId, isNull);
      expect(holstein.createdAt, isNotNull);

      final angus = response.data.data[1];
      expect(angus.idComposicion, equals(2));
      expect(angus.nombre, equals('Aberdeen Angus'));
      expect(angus.createdAt, isNull); // Handles null timestamps
      expect(angus.updatedAt, isNull);
    });

    test('should handle edge case: empty data array', () {
      final emptyResponse = {
        'success': true,
        'message': 'No hay composiciones de raza disponibles',
        'data': {
          'current_page': 1,
          'data': [],
          'total': 0,
          'per_page': 50,
        }
      };

      final response = ComposicionRazaResponse.fromJson(emptyResponse);

      expect(response.success, isTrue);
      expect(response.data.data, isEmpty);
      expect(response.data.total, equals(0));
    });

    test('should handle edge case: all null optional fields', () {
      final responseWithNulls = {
        'success': true,
        'message': 'Composicion raza with minimal data',
        'data': {
          'current_page': 1,
          'data': [
            {
              'id_Composicion': 999,
              'Nombre': 'Test Breed',
              'Siglas': 'TEST',
              'Pelaje': 'Mixed',
              'Proposito': 'Test',
              'Tipo_Raza': 'Test Type',
              'Origen': 'Laboratory',
              'Caracteristica_Especial': 'Experimental',
              'Proporcion_Raza': 'Variable',
              // All optional fields are null or missing
              'created_at': null,
              'updated_at': null,
              'fk_id_Finca': null,
              'fk_tipo_animal_id': null,
              // synced field missing - should default to false
            }
          ],
          'total': 1,
          'per_page': 50,
        }
      };

      final response = ComposicionRazaResponse.fromJson(responseWithNulls);
      final breed = response.data.data[0];

      expect(breed.idComposicion, equals(999));
      expect(breed.nombre, equals('Test Breed'));
      expect(breed.createdAt, isNull);
      expect(breed.updatedAt, isNull);
      expect(breed.fkIdFinca, isNull);
      expect(breed.fkTipoAnimalId, isNull);
      expect(breed.synced, isFalse); // Should default to false
    });
  });
}