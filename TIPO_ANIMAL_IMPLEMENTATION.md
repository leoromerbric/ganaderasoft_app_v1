# TipoAnimal-Etapa Integration Implementation

## Overview
This implementation adds TipoAnimal (Animal Type) selection to the animal creation flow, with proper filtering of Etapas (Stages) based on both sex and animal type.

## UI Flow Enhancement

### Before (Original Flow)
1. Sex selection (M/F)
2. Stage selection (filtered only by sex)

### After (Enhanced Flow)
1. **Sex selection (M/F)** - Enables tipo animal dropdown
2. **Animal Type selection** - Shows available animal types (Vacuno, Bufala, etc.)
3. **Stage selection** - Filtered by both sex AND animal type

## Key Features Implemented

### 1. Sex-dependent TipoAnimal dropdown
- Dropdown is disabled until sex is selected
- Resets when sex changes
- Shows all available animal types from API

### 2. Enhanced Etapa filtering
- Requires both sex AND tipo animal selection
- Converts F (Female) to H (Hembra) for API compatibility
- Filters by `etapa.etapaSexo == sexoForFiltering && etapa.etapaFkTipoAnimalId == selectedTipoAnimal.tipoAnimalId`

### 3. State management
- Proper cascade resets: Sex change → Reset tipo animal and etapa
- Tipo animal change → Reset etapa only
- Validation for all required fields

## Data Flow

```
API Response (Etapas) →
[
  {
    "etapa_id": 15,
    "etapa_nombre": "Becerro",
    "etapa_sexo": "M",
    "etapa_fk_tipo_animal_id": 3,
    "tipo_animal": {
      "tipo_animal_id": 3,
      "tipo_animal_nombre": "Vacuno"
    }
  },
  {
    "etapa_id": 16,
    "etapa_nombre": "Becerra", 
    "etapa_sexo": "H",
    "etapa_fk_tipo_animal_id": 3,
    "tipo_animal": {
      "tipo_animal_id": 3,
      "tipo_animal_nombre": "Vacuno"
    }
  }
]

User Selection:
- Sex: "F" → Converted to "H" for filtering
- Tipo Animal: Vacuno (ID: 3)

Filtered Result:
- Shows only etapas where etapa_sexo == "H" AND etapa_fk_tipo_animal_id == 3
```

## UI Mockup Structure

```
┌─────────────────────────────────────┐
│ Create Animal Form                  │
├─────────────────────────────────────┤
│ Rebaño: [Dropdown]                 │
│ Nombre: [Text Input]                │
│ Código: [Text Input]                │
│                                     │
│ Sexo *: [M/F Dropdown] ← Step 1    │
│                                     │
│ Tipo de Animal *: [Dropdown] ← 2   │
│ └─ Enabled only when sex selected   │
│ └─ Shows: Vacuno, Bufala, etc.      │
│                                     │
│ Fecha Nacimiento: [Date Picker]    │
│                                     │
│ Etapa *: [Dropdown] ← Step 3       │
│ └─ Filtered by sex + tipo animal    │
│ └─ Shows: Becerro, Toro, etc.       │
│                                     │
│ [Other fields...]                   │
│                                     │
│ [Crear Animal Button]               │
└─────────────────────────────────────┘
```

## Example Filtering Scenarios

### Scenario 1: Male Vacuno
- User selects: Sex = "M", Tipo Animal = "Vacuno" 
- Available etapas: "Becerro", "Toro", etc. (only male Vacuno stages)

### Scenario 2: Female Bufala  
- User selects: Sex = "F", Tipo Animal = "Bufala"
- Sex converted to "H" for filtering
- Available etapas: "Añoja", "Bufala", etc. (only female Bufala stages)

## Technical Implementation Details

### New State Variables
```dart
TipoAnimal? _selectedTipoAnimal;
List<TipoAnimal> _tiposAnimal = [];
```

### Enhanced Filtering Logic
```dart
List<Etapa> _getFilteredEtapas() {
  if (_selectedSexo == null || _selectedTipoAnimal == null) return [];
  
  String sexoForFiltering = _selectedSexo == 'F' ? 'H' : _selectedSexo!;
  
  return _etapas.where((etapa) => 
    etapa.etapaSexo == sexoForFiltering && 
    etapa.etapaFkTipoAnimalId == _selectedTipoAnimal!.tipoAnimalId
  ).toList();
}
```

### Data Loading
```dart
Future<void> _loadTiposAnimal() async {
  // Online/offline support similar to other configuration data
  if (_isOffline) {
    final tiposAnimal = await DatabaseService.getTiposAnimalOffline();
    setState(() => _tiposAnimal = tiposAnimal);
  } else {
    final response = await ConfigurationService.getTiposAnimal();
    setState(() => _tiposAnimal = response.data.data);
  }
}
```

This implementation ensures proper cascading selection and filtering while maintaining compatibility with the existing API structure and offline functionality.