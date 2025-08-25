import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/models/animal.dart';
import 'package:ganaderasoft_app_v1/models/configuration_models.dart';

void main() {
  group('Animal Detail Null Fix Tests', () {
    test('Should handle null etapa in EtapaAnimal.fromJson', () {
      final jsonWithNullEtapa = {
        'etan_etapa_id': 15,
        'etan_animal_id': 13,
        'etan_fecha_ini': '2025-03-15T00:00:00.000000Z',
        'etan_fecha_fin': null,
        'etapa': null, // This should not crash
      };

      // This should not throw "type 'Null' is not a subtype of type 'Map"
      expect(() => EtapaAnimal.fromJson(jsonWithNullEtapa), returnsNormally);
      
      final etapaAnimal = EtapaAnimal.fromJson(jsonWithNullEtapa);
      expect(etapaAnimal.etanEtapaId, equals(15));
      expect(etapaAnimal.etanAnimalId, equals(13));
      // Etapa should be created with default values due to empty map fallback
      expect(etapaAnimal.etapa.etapaId, equals(0));
      expect(etapaAnimal.etapa.etapaNombre, equals(''));
    });

    test('Should handle null tipo_animal in Etapa.fromJson', () {
      final jsonWithNullTipoAnimal = {
        'etapa_id': 15,
        'etapa_nombre': 'Becerro',
        'etapa_edad_ini': 0,
        'etapa_edad_fin': 365,
        'etapa_fk_tipo_animal_id': 3,
        'etapa_sexo': 'M',
        'tipo_animal': null, // This should not crash
      };

      // This should not throw "type 'Null' is not a subtype of type 'Map"
      expect(() => Etapa.fromJson(jsonWithNullTipoAnimal), returnsNormally);
      
      final etapa = Etapa.fromJson(jsonWithNullTipoAnimal);
      expect(etapa.etapaId, equals(15));
      expect(etapa.etapaNombre, equals('Becerro'));
      // TipoAnimal should be created with default values due to empty map fallback
      expect(etapa.tipoAnimal.tipoAnimalId, equals(0));
      expect(etapa.tipoAnimal.tipoAnimalNombre, equals(''));
    });

    test('Should handle completely empty JSON in Etapa.fromJson', () {
      final emptyJson = <String, dynamic>{};

      // This should not crash and create object with default values
      expect(() => Etapa.fromJson(emptyJson), returnsNormally);
      
      final etapa = Etapa.fromJson(emptyJson);
      expect(etapa.etapaId, equals(0));
      expect(etapa.etapaNombre, equals(''));
      expect(etapa.etapaEdadIni, equals(0));
      expect(etapa.etapaFkTipoAnimalId, equals(0));
      expect(etapa.etapaSexo, equals(''));
      expect(etapa.tipoAnimal.tipoAnimalId, equals(0));
      expect(etapa.tipoAnimal.tipoAnimalNombre, equals(''));
    });

    test('Should handle completely empty JSON in TipoAnimal.fromJson', () {
      final emptyJson = <String, dynamic>{};

      // This should not crash and create object with default values
      expect(() => TipoAnimal.fromJson(emptyJson), returnsNormally);
      
      final tipoAnimal = TipoAnimal.fromJson(emptyJson);
      expect(tipoAnimal.tipoAnimalId, equals(0));
      expect(tipoAnimal.tipoAnimalNombre, equals(''));
      expect(tipoAnimal.synced, equals(false));
    });

    test('Should handle null etapa_actual in AnimalDetail.fromJson', () {
      // This simulates the API response that was causing the original error
      final animalDetailJson = {
        'id_Animal': 18,
        'id_Rebano': 6,
        'Nombre': 'Animal Test',
        'codigo_animal': 'TEST-001',
        'Sexo': 'M',
        'fecha_nacimiento': '2025-03-15T00:00:00.000000Z',
        'Procedencia': 'Test Farm',
        'archivado': false,
        'created_at': '2025-08-18T21:35:24.000000Z',
        'updated_at': '2025-08-18T21:35:24.000000Z',
        'fk_composicion_raza': 70,
        'estados': [],
        'etapa_animales': [
          {
            'etan_etapa_id': 15,
            'etan_animal_id': 18,
            'etan_fecha_ini': '2025-03-15T00:00:00.000000Z',
            'etan_fecha_fin': null,
            'etapa': null, // This was causing the crash
          }
        ],
        'etapa_actual': {
          'etan_etapa_id': 15,
          'etan_animal_id': 18,
          'etan_fecha_ini': '2025-03-15T00:00:00.000000Z',
          'etan_fecha_fin': null,
          'etapa': null, // This was also causing the crash
        },
      };

      // This should not throw the "type 'Null' is not a subtype of type 'Map" error
      expect(() => AnimalDetail.fromJson(animalDetailJson), returnsNormally);
      
      final animalDetail = AnimalDetail.fromJson(animalDetailJson);
      expect(animalDetail.idAnimal, equals(18));
      expect(animalDetail.nombre, equals('Animal Test'));
      expect(animalDetail.etapaAnimales.length, equals(1));
      expect(animalDetail.etapaActual, isNotNull);
      
      // The etapa should have default values instead of causing a crash
      final etapaAnimal = animalDetail.etapaAnimales.first;
      expect(etapaAnimal.etapa.etapaId, equals(0));
      expect(etapaAnimal.etapa.etapaNombre, equals(''));
    });
  });
}