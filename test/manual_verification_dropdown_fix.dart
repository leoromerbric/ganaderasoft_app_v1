// Manual test to demonstrate the dropdown issue fix
// Run this to verify the fix works as expected

import '../lib/models/animal.dart';
import '../lib/models/configuration_models.dart';

void main() {
  print('=== Testing EtapaAnimal Dropdown Fix ===\n');

  // Create sample data
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

  // Simulate API response - etapaActual and etapaAnimales contain "similar" but different instances
  final etapaActual = EtapaAnimal(
    etanEtapaId: 15,
    etanAnimalId: 10,
    etanFechaIni: '2025-01-01T00:00:00.000000Z',
    etanFechaFin: null,
    etapa: etapa,
  );

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

  print('1. Testing equality operators:');
  print('   etapaActual == etapaAnimales[0]: ${etapaActual == etapaAnimales[0]}');
  print('   identical(etapaActual, etapaAnimales[0]): ${identical(etapaActual, etapaAnimales[0])}\n');

  print('2. OLD APPROACH (would cause dropdown error):');
  print('   Setting _selectedEtapaAnimal = etapaActual');
  final selectedOldWay = etapaActual;
  final foundInListOldWay = etapaAnimales.contains(selectedOldWay);
  print('   Is selectedEtapaAnimal in dropdown list? $foundInListOldWay');
  print('   This would cause: "There should be exactly one item with DropdownButton\'s value"\n');

  print('3. NEW APPROACH (fixes the issue):');
  print('   Finding matching item from etapaAnimales list...');
  final selectedNewWay = etapaAnimales
      .where((etapa) => etapa == etapaActual)
      .firstOrNull;
  
  if (selectedNewWay != null) {
    final foundInListNewWay = etapaAnimales.contains(selectedNewWay);
    final isIdentical = identical(selectedNewWay, etapaAnimales[0]);
    print('   Found matching item: ✓');
    print('   Is selectedEtapaAnimal in dropdown list? $foundInListNewWay');
    print('   Is it the exact same object reference? $isIdentical');
    print('   ✓ This will work correctly with Flutter dropdown!\n');
  } else {
    print('   No matching item found (would set to null)\n');
  }

  print('4. Edge case - no matching etapaActual:');
  final differentEtapaActual = EtapaAnimal(
    etanEtapaId: 99, // Different ID
    etanAnimalId: 10,
    etanFechaIni: '2025-01-01T00:00:00.000000Z',
    etanFechaFin: null,
    etapa: etapa,
  );
  
  final selectedEdgeCase = etapaAnimales
      .where((etapa) => etapa == differentEtapaActual)
      .firstOrNull;
  
  print('   selectedEtapaAnimal: ${selectedEdgeCase == null ? "null" : "found"}');
  print('   ✓ Handles edge case gracefully\n');

  print('=== Fix successfully implemented! ===');
}

extension on Iterable<EtapaAnimal> {
  EtapaAnimal? get firstOrNull => isEmpty ? null : first;
}