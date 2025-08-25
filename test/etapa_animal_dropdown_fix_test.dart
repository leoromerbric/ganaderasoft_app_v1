import 'package:flutter_test/flutter_test.dart';
import '../lib/models/animal.dart';
import '../lib/models/configuration_models.dart';

void main() {
  group('EtapaAnimal Dropdown Fix Tests', () {
    test('EtapaAnimal should have proper equality operators', () {
      final tipoAnimal = TipoAnimal(
        tipoAnimalId: 3,
        tipoAnimalNombre: 'Vacuno',
        synced: true,
      );

      final etapa = Etapa(
        etapaId: 15,
        etapaNombre: 'Becerro',
        etapaEdadIni: 0,
        etapaEdadFin: 365,
        etapaFkTipoAnimalId: 3,
        etapaSexo: 'M',
        tipoAnimal: tipoAnimal,
      );

      final etapaAnimal1 = EtapaAnimal(
        etanEtapaId: 15,
        etanAnimalId: 10,
        etanFechaIni: '2025-01-01T00:00:00.000000Z',
        etanFechaFin: null,
        etapa: etapa,
      );

      final etapaAnimal2 = EtapaAnimal(
        etanEtapaId: 15,
        etanAnimalId: 10,
        etanFechaIni: '2025-01-01T00:00:00.000000Z',
        etanFechaFin: null,
        etapa: etapa,
      );

      final etapaAnimal3 = EtapaAnimal(
        etanEtapaId: 16, // Different ID
        etanAnimalId: 10,
        etanFechaIni: '2025-01-01T00:00:00.000000Z',
        etanFechaFin: null,
        etapa: etapa,
      );

      // Test equality
      expect(etapaAnimal1 == etapaAnimal2, isTrue);
      expect(etapaAnimal1 == etapaAnimal3, isFalse);

      // Test hashCode consistency
      expect(etapaAnimal1.hashCode == etapaAnimal2.hashCode, isTrue);
      expect(etapaAnimal1.hashCode == etapaAnimal3.hashCode, isFalse);
    });

    test('Should handle dropdown value selection correctly', () {
      final tipoAnimal = TipoAnimal(
        tipoAnimalId: 3,
        tipoAnimalNombre: 'Vacuno',
        synced: true,
      );

      final etapa = Etapa(
        etapaId: 15,
        etapaNombre: 'Becerro',
        etapaEdadIni: 0,
        etapaEdadFin: 365,
        etapaFkTipoAnimalId: 3,
        etapaSexo: 'M',
        tipoAnimal: tipoAnimal,
      );

      // Create etapaActual (as it comes from API)
      final etapaActual = EtapaAnimal(
        etanEtapaId: 15,
        etanAnimalId: 10,
        etanFechaIni: '2025-01-01T00:00:00.000000Z',
        etanFechaFin: null,
        etapa: etapa,
      );

      // Create etapaAnimales list (as it comes from API)
      final etapaAnimales = [
        EtapaAnimal(
          etanEtapaId: 15,
          etanAnimalId: 10,
          etanFechaIni: '2025-01-01T00:00:00.000000Z',
          etanFechaFin: null,
          etapa: etapa,
        ),
        EtapaAnimal(
          etanEtapaId: 16,
          etanAnimalId: 10,
          etanFechaIni: '2024-01-01T00:00:00.000000Z',
          etanFechaFin: '2024-12-31T00:00:00.000000Z',
          etapa: etapa,
        ),
      ];

      // Test the fix: find matching item from the list
      final selectedEtapaAnimal = etapaAnimales
          .where((etapa) => etapa == etapaActual)
          .firstOrNull;

      expect(selectedEtapaAnimal, isNotNull);
      expect(selectedEtapaAnimal!.etanEtapaId, equals(15));
      expect(selectedEtapaAnimal.etanAnimalId, equals(10));

      // Verify that the selected item is actually from the list (reference equality)
      expect(identical(selectedEtapaAnimal, etapaAnimales.first), isTrue);
    });

    test('Should handle case when etapaActual is not in etapaAnimales list', () {
      final tipoAnimal = TipoAnimal(
        tipoAnimalId: 3,
        tipoAnimalNombre: 'Vacuno',
        synced: true,
      );

      final etapa = Etapa(
        etapaId: 15,
        etapaNombre: 'Becerro',
        etapaEdadIni: 0,
        etapaEdadFin: 365,
        etapaFkTipoAnimalId: 3,
        etapaSexo: 'M',
        tipoAnimal: tipoAnimal,
      );

      // Create etapaActual with different data
      final etapaActual = EtapaAnimal(
        etanEtapaId: 99, // Different ID
        etanAnimalId: 10,
        etanFechaIni: '2025-01-01T00:00:00.000000Z',
        etanFechaFin: null,
        etapa: etapa,
      );

      // Create etapaAnimales list without matching item
      final etapaAnimales = [
        EtapaAnimal(
          etanEtapaId: 15,
          etanAnimalId: 10,
          etanFechaIni: '2025-01-01T00:00:00.000000Z',
          etanFechaFin: null,
          etapa: etapa,
        ),
        EtapaAnimal(
          etanEtapaId: 16,
          etanAnimalId: 10,
          etanFechaIni: '2024-01-01T00:00:00.000000Z',
          etanFechaFin: '2024-12-31T00:00:00.000000Z',
          etapa: etapa,
        ),
      ];

      // Test the fix: should return null when no match is found
      final selectedEtapaAnimal = etapaAnimales
          .where((etapa) => etapa == etapaActual)
          .firstOrNull;

      expect(selectedEtapaAnimal, isNull);
    });

    test('Should handle null etapaActual gracefully', () {
      final etapaAnimales = <EtapaAnimal>[];
      EtapaAnimal? etapaActual;

      // Test the fix with null etapaActual
      EtapaAnimal? selectedEtapaAnimal;
      if (etapaActual != null) {
        selectedEtapaAnimal = etapaAnimales
            .where((etapa) => etapa == etapaActual)
            .firstOrNull;
      } else {
        selectedEtapaAnimal = null;
      }

      expect(selectedEtapaAnimal, isNull);
    });
  });
}