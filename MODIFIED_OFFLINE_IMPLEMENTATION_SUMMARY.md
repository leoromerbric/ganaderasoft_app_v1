# Modified Offline Implementation - Issue #93

## Overview
This implementation adds a `modifiedOffline` column to all database tables to prevent server data from overwriting local modifications made while offline. The system ensures that:

1. Records modified offline are not overwritten during synchronization
2. Only manual synchronization is allowed (automatic sync disabled)
3. Offline modifications are properly tracked and protected

## Database Changes

### Schema Version Update
- Database version updated from 9 to 10
- Added `modifiedOffline INTEGER DEFAULT 0` to all 20 tables:
  - users, fincas, estado_salud, tipo_animal, etapa, fuente_agua
  - metodo_riego, ph_suelo, sexo, textura_suelo, tipo_explotacion
  - tipo_relieve, rebanos, animales, composicion_raza, animal_detail
  - cambios_animal, lactancia, peso_corporal, personal_finca

### Migration Logic
- Version 10 migration adds `modifiedOffline` column to all existing tables
- Default value is 0 (not modified offline)
- Existing records are preserved with `modifiedOffline = 0`

## Offline Modification Tracking

### Setting modifiedOffline Flag
When records are created or updated offline, `modifiedOffline` is set to 1:

**Create Operations:**
- `savePendingAnimalOffline()` sets `modifiedOffline = 1`
- `savePendingPersonalFincaOffline()` sets `modifiedOffline = 1`

**Update Operations:**
- `savePendingAnimalUpdateOffline()` sets `modifiedOffline = 1`
- `savePendingPersonalFincaUpdateOffline()` sets `modifiedOffline = 1`

### Resetting modifiedOffline Flag
After successful synchronization, `modifiedOffline` is reset to 0:

**Sync Completion:**
- `markAnimalAsSynced()` sets `modifiedOffline = 0`
- `markAnimalUpdateAsSynced()` sets `modifiedOffline = 0`
- `markPersonalFincaAsSynced()` sets `modifiedOffline = 0`
- `markPersonalFincaUpdateAsSynced()` sets `modifiedOffline = 0`

## Sync Protection Logic

### Data Import Protection
During server data synchronization, records with `modifiedOffline = 1` are skipped:

**Animals (`saveAnimalesOffline()`):**
```dart
// Check if this animal was modified offline
final existingAnimal = await db.query(
  'animales',
  where: 'id_animal = ?',
  whereArgs: [animal.idAnimal],
  limit: 1,
);

// If the animal exists and was modified offline, skip overwriting it
if (existingAnimal.isNotEmpty && existingAnimal.first['modifiedOffline'] == 1) {
  LoggingService.info('Skipping overwrite of animal ${animal.nombre} - modified offline');
  continue;
}
```

**Fincas (`saveFincasOffline()`):**
- Gets list of offline modified fincas first
- Deletes only non-modified records: `WHERE modifiedOffline = 0 OR modifiedOffline IS NULL`
- Skips inserting server data for offline-modified fincas

**Configuration Tables:**
- Similar protection applied to configuration data save methods
- Uses `_saveSimpleConfigOffline()` helper with protection logic

### Automatic Sync Disabled
Per requirements, automatic synchronization is disabled:

**OfflineManager:**
- Commented out `_autoSync()` call when connectivity is restored
- Logs connectivity change but doesn't trigger sync

**PendingSyncScreen:**
- Commented out `_startAutoSync()` call in `initState()`
- Manual sync only via "Sincronizar cambios" button

## Testing

### Test Coverage
Created comprehensive test suites:

1. **`modified_offline_implementation_test.dart`**
   - Database schema validation
   - Offline modification flag setting
   - Basic functionality tests

2. **`modified_offline_sync_protection_test.dart`**
   - Sync protection behavior
   - Mixed scenario handling
   - Flag reset after sync

### Key Test Scenarios
- ✅ Database version 10 with modifiedOffline columns
- ✅ Offline creation sets modifiedOffline = 1
- ✅ Offline updates set modifiedOffline = 1
- ✅ Server sync skips offline-modified records
- ✅ Non-modified records are updated normally
- ✅ Mixed scenarios handle both types correctly
- ✅ Successful sync resets modifiedOffline = 0

## Usage

### For Developers
1. **Offline Operations**: Use existing pending save methods - they automatically set `modifiedOffline = 1`
2. **Sync Operations**: Use existing sync methods - they automatically respect the `modifiedOffline` flag
3. **Manual Sync**: Users must click "Sincronizar cambios" - no automatic sync

### For Users
1. **Creating/Editing Offline**: Works as before, but changes are protected from being overwritten
2. **Synchronization**: Must manually trigger via "Sincronizar cambios" button
3. **Data Protection**: Offline changes are preserved until manually synced

## Files Modified

### Core Database Service
- `lib/services/database_service.dart`
  - Database version updated to 10
  - Added modifiedOffline column to all table schemas
  - Updated offline save methods to set modifiedOffline = 1
  - Updated sync save methods to respect modifiedOffline flag
  - Updated mark-as-synced methods to reset modifiedOffline = 0

### Offline Management
- `lib/services/offline_manager.dart`
  - Disabled automatic sync on connectivity restore

### UI Components
- `lib/screens/pending_sync_screen.dart`
  - Disabled automatic sync on screen initialization

### Tests
- `test/modified_offline_implementation_test.dart` (new)
- `test/modified_offline_sync_protection_test.dart` (new)

## Technical Notes

### Performance Considerations
- Added database queries for modifiedOffline checks during sync
- Impact is minimal as queries are by primary key
- Batch operations maintain efficiency

### Data Integrity
- Uses transactions for atomic operations
- Maintains existing sync logic while adding protection
- Preserves all existing functionality

### Backward Compatibility
- Migration from version 9 to 10 is automatic
- Existing data preserved with modifiedOffline = 0
- No breaking changes to existing API

## Validation

The implementation successfully addresses all requirements from Issue #93:

✅ **Added modifiedOffline column to all tables**
✅ **Set modifiedOffline = 1 when modified offline, 0 otherwise**
✅ **Sync validation: skip overwriting when modifiedOffline = 1**
✅ **Manual sync only: disabled automatic synchronization**
✅ **Preserved application functionality**

The system now provides robust protection for offline modifications while maintaining all existing capabilities.