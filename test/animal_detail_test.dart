import 'package:flutter_test/flutter_test.dart';
import '../lib/models/animal.dart';
import '../lib/models/configuration_models.dart';

void main() {
  group('AnimalDetail Model Tests', () {
    test('Should create AnimalDetail from JSON correctly', () {
      // Sample JSON response based on get_animal.txt
      final json = {
        "id_Animal": 13,
        "id_Rebano": 6,
        "Nombre": "Animal 1",
        "codigo_animal": "ANIMAL-001",
        "Sexo": "F",
        "fecha_nacimiento": "2025-03-15T00:00:00.000000Z",
        "Procedencia": "Finca Origen",
        "archivado": false,
        "created_at": "2025-08-18T21:35:24.000000Z",
        "updated_at": "2025-08-18T21:35:24.000000Z",
        "fk_composicion_raza": 70,
        "rebano": null,
        "composicion_raza": null,
        "estados": [
          {
            "esan_id": 13,
            "esan_fecha_ini": "2025-03-15T00:00:00.000000Z",
            "esan_fecha_fin": null,
            "esan_fk_estado_id": 15,
            "esan_fk_id_animal": 13,
            "estado_salud": {
              "estado_id": 15,
              "estado_nombre": "Sano"
            }
          }
        ],
        "etapa_animales": [
          {
            "etan_etapa_id": 15,
            "etan_animal_id": 13,
            "etan_fecha_ini": "2025-03-15T00:00:00.000000Z",
            "etan_fecha_fin": null,
            "etapa": {
              "etapa_id": 15,
              "etapa_nombre": "Becerro",
              "etapa_edad_ini": 0,
              "etapa_edad_fin": 365,
              "etapa_fk_tipo_animal_id": 3,
              "etapa_sexo": "M",
              "tipo_animal": {
                "tipo_animal_id": 3,
                "tipo_animal_nombre": "Vacuno"
              }
            }
          }
        ],
        "etapa_actual": {
          "etan_etapa_id": 15,
          "etan_animal_id": 13,
          "etan_fecha_ini": "2025-03-15T00:00:00.000000Z",
          "etan_fecha_fin": null,
          "etapa": {
            "etapa_id": 15,
            "etapa_nombre": "Becerro",
            "etapa_edad_ini": 0,
            "etapa_edad_fin": 365,
            "etapa_fk_tipo_animal_id": 3,
            "etapa_sexo": "M",
            "tipo_animal": {
              "tipo_animal_id": 3,
              "tipo_animal_nombre": "Vacuno"
            }
          }
        }
      };

      final animalDetail = AnimalDetail.fromJson(json);

      // Verify basic animal properties
      expect(animalDetail.idAnimal, 13);
      expect(animalDetail.nombre, "Animal 1");
      expect(animalDetail.codigoAnimal, "ANIMAL-001");
      expect(animalDetail.sexo, "F");

      // Verify estados
      expect(animalDetail.estados.length, 1);
      expect(animalDetail.estados[0].estadoSalud.estadoNombre, "Sano");

      // Verify etapa_animales
      expect(animalDetail.etapaAnimales.length, 1);
      expect(animalDetail.etapaAnimales[0].etapa.etapaNombre, "Becerro");
      expect(animalDetail.etapaAnimales[0].etanEtapaId, 15);

      // Verify etapa_actual
      expect(animalDetail.etapaActual, isNotNull);
      expect(animalDetail.etapaActual!.etapa.etapaNombre, "Becerro");
      expect(animalDetail.etapaActual!.etanEtapaId, 15);
    });

    test('Should serialize AnimalDetail to JSON correctly', () {
      // Create test data
      final tipoAnimal = TipoAnimal(
        tipoAnimalId: 3,
        tipoAnimalNombre: "Vacuno",
      );

      final etapa = Etapa(
        etapaId: 15,
        etapaNombre: "Becerro",
        etapaEdadIni: 0,
        etapaEdadFin: 365,
        etapaFkTipoAnimalId: 3,
        etapaSexo: "M",
        tipoAnimal: tipoAnimal,
      );

      final etapaAnimal = EtapaAnimal(
        etanEtapaId: 15,
        etanAnimalId: 13,
        etanFechaIni: "2025-03-15T00:00:00.000000Z",
        etanFechaFin: null,
        etapa: etapa,
      );

      final estadoSalud = EstadoSalud(
        estadoId: 15,
        estadoNombre: "Sano",
      );

      final estadoAnimal = EstadoAnimal(
        esanId: 13,
        esanFechaIni: "2025-03-15T00:00:00.000000Z",
        esanFechaFin: null,
        esanFkEstadoId: 15,
        esanFkIdAnimal: 13,
        estadoSalud: estadoSalud,
      );

      final animalDetail = AnimalDetail(
        idAnimal: 13,
        idRebano: 6,
        nombre: "Animal 1",
        codigoAnimal: "ANIMAL-001",
        sexo: "F",
        fechaNacimiento: "2025-03-15T00:00:00.000000Z",
        procedencia: "Finca Origen",
        archivado: false,
        createdAt: "2025-08-18T21:35:24.000000Z",
        updatedAt: "2025-08-18T21:35:24.000000Z",
        fkComposicionRaza: 70,
        estados: [estadoAnimal],
        etapaAnimales: [etapaAnimal],
        etapaActual: etapaAnimal,
      );

      final json = animalDetail.toJson();

      // Verify serialization
      expect(json['id_Animal'], 13);
      expect(json['Nombre'], "Animal 1");
      expect(json['estados'].length, 1);
      expect(json['etapa_animales'].length, 1);
      expect(json['etapa_actual'], isNotNull);
      expect(json['etapa_actual']['etan_etapa_id'], 15);
    });

    test('Should handle EtapaAnimal correctly', () {
      final tipoAnimal = TipoAnimal(
        tipoAnimalId: 3,
        tipoAnimalNombre: "Vacuno",
      );

      final etapa = Etapa(
        etapaId: 15,
        etapaNombre: "Becerro",
        etapaEdadIni: 0,
        etapaEdadFin: 365,
        etapaFkTipoAnimalId: 3,
        etapaSexo: "M",
        tipoAnimal: tipoAnimal,
      );

      final etapaAnimal = EtapaAnimal(
        etanEtapaId: 15,
        etanAnimalId: 13,
        etanFechaIni: "2025-03-15T00:00:00.000000Z",
        etanFechaFin: null,
        etapa: etapa,
      );

      // Verify properties
      expect(etapaAnimal.etanEtapaId, 15);
      expect(etapaAnimal.etanAnimalId, 13);
      expect(etapaAnimal.etapa.etapaNombre, "Becerro");
      expect(etapaAnimal.etanFechaFin, isNull); // Current stage

      // Test serialization/deserialization
      final json = etapaAnimal.toJson();
      final reconstructed = EtapaAnimal.fromJson(json);
      
      expect(reconstructed.etanEtapaId, etapaAnimal.etanEtapaId);
      expect(reconstructed.etapa.etapaNombre, etapaAnimal.etapa.etapaNombre);
    });
  });
}