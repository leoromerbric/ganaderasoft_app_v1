# Offline Animal Creation Feature

## Overview

This feature enables users to create animal records when the application is offline. The animals are stored locally and automatically synchronized with the server when connectivity is restored.

## Key Features

### 1. Offline Animal Creation
- When offline, the "Create Animal" screen shows an orange warning banner
- All form fields work normally in offline mode
- Animals are saved locally with a temporary negative ID
- Success message indicates the animal will be synced when online

### 2. Pending Records Management
- New "Registros Pendientes" (Pending Records) screen accessible from:
  - Home screen quick access grid
  - Drawer menu
- Shows all unsynced records including:
  - Pending animals
  - Other pending farm management records
- Real-time sync status and progress

### 3. Automatic Synchronization
- "Sincronizar mis cambios" button validates connectivity
- Shows real-time progress during sync
- Handles errors gracefully
- Updates local records with server IDs after successful sync

## Technical Implementation

### Database Changes
- Added sync columns to `animales` table:
  - `synced`: Boolean flag (1 = synced, 0 = pending)
  - `is_pending`: Boolean flag for pending records
  - `pending_operation`: Type of operation (CREATE, UPDATE, DELETE)
  - `estado_id` and `etapa_id`: Store initial state and stage

### New Components
1. **PendingSyncModels**: Data models for handling sync operations
2. **PendingSyncScreen**: UI for managing pending records
3. **Enhanced DatabaseService**: Methods for offline operations
4. **Updated CreateAnimalScreen**: Offline creation logic

### Code Structure
```
lib/
├── models/pending_sync_models.dart    # Sync-related models
├── screens/pending_sync_screen.dart   # Pending records UI
├── screens/create_animal_screen.dart  # Updated with offline support
├── screens/home_screen.dart           # Navigation to pending screen
└── services/database_service.dart     # Enhanced with sync methods
```

## Usage Instructions

### Creating Animals Offline
1. Navigate to "Crear Animal" from any farm/herd
2. If offline, an orange banner appears with notification
3. Fill out the form normally
4. Submit - animal saves locally with success message
5. Animal appears in "Registros Pendientes" screen

### Syncing Pending Records
1. Go to "Registros Pendientes" from home screen
2. Review list of pending records
3. Ensure internet connectivity
4. Click "Sincronizar mis cambios"
5. Monitor real-time progress
6. Records disappear from pending list when synced

### Monitoring Sync Status
- Pending records show creation timestamp
- Each record shows entity type and operation
- Sync progress shows percentage and current action
- Success/error messages appear after sync completion

## Error Handling

### Network Issues
- Connectivity validation before sync attempts
- Graceful handling of connection loss during sync
- Individual record error handling (continues with remaining records)

### Data Integrity
- Temporary negative IDs prevent conflicts
- Server IDs update local records after successful sync
- Rollback capabilities for failed operations

## Extensibility

The system is designed to be extensible for future entity types:

1. Add new pending record types to `PendingSyncRecord` hierarchy
2. Implement entity-specific sync logic in `PendingSyncScreen`
3. Add sync methods to `DatabaseService`
4. Update `getAllPendingRecords()` to include new entity types

This architecture supports offline operation for any farm management entity with minimal code changes.