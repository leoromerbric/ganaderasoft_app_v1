import 'package:flutter/material.dart';
import 'dart:async';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../services/connectivity_service.dart';
import '../services/auth_service.dart';
import '../services/logging_service.dart';
import '../models/farm_management_models.dart';

/// Screen that displays pending sync records and manages automatic synchronization.
/// 
/// This screen automatically loads pending records and triggers synchronization 
/// when the screen initializes, providing a seamless user experience for 
/// managing offline data that needs to be synced to the server.
/// 
/// **Execution Order:**
/// 1. `initState()` → Initialize screen, load records, subscribe to sync, trigger auto-sync
/// 2. `_loadPendingRecords()` → Load pending records from local database  
/// 3. `_subscribeToSync()` → Set up sync event listener
/// 4. `_startAutoSync()` → Check connectivity and start automatic sync
/// 5. `_syncPendingRecords()` → Main sync coordinator (auto-triggered)
/// 6. `_syncPendingAnimals()` → Sync animals first
/// 7. `_syncPendingPersonalFinca()` → Sync personal finca records second
/// 8. `_loadPendingRecords()` → Refresh list after sync completion
class PendingSyncScreen extends StatefulWidget {
  const PendingSyncScreen({super.key});

  @override
  State<PendingSyncScreen> createState() => _PendingSyncScreenState();
}

class _PendingSyncScreenState extends State<PendingSyncScreen> {
  List<Map<String, dynamic>> _pendingRecords = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  double _syncProgress = 0.0;
  String _syncMessage = '';
  StreamSubscription<SyncData>? _syncSubscription;
  final _authService = AuthService();
  
  /// Flag to enable automatic loading and syncing on screen initialization.
  /// When true, the screen will automatically load pending records and 
  /// trigger synchronization when it starts, providing immediate feedback
  /// to users about their pending changes.
  static const bool _autoLoadOnInit = true;

  /// Initializes the screen state and sets up automatic synchronization.
  /// 
  /// **Execution Order (Method 1):**
  /// 1. Calls parent initState()
  /// 2. If auto-load enabled: calls `_loadPendingRecords()` to load data from local DB
  /// 3. If auto-load disabled: sets empty initial state  
  /// 4. Calls `_subscribeToSync()` to listen for sync status changes
  /// 5. Calls `_startAutoSync()` to begin automatic synchronization
  /// 
  /// This method establishes the foundation for the entire sync process.
  @override
  void initState() {
    super.initState();
    if (_autoLoadOnInit) {
      _loadPendingRecords();
    } else {
      // Set initial state without loading records
      setState(() {
        _isLoading = false;
        _pendingRecords = [];
      });
    }
    _subscribeToSync();
    // Auto-sync disabled per requirements - users must manually click "Sincronizar cambios"
    // _startAutoSync();
  }

  /// Cleans up resources when the screen is disposed.
  /// 
  /// Cancels the sync subscription to prevent memory leaks and ensures
  /// proper cleanup of stream listeners.
  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  /// Sets up a subscription to listen for sync status changes.
  /// 
  /// **Execution Order (Method 3):**
  /// This method establishes a persistent listener that reacts to sync events:
  /// - Updates UI state when sync starts/stops (_isSyncing, _syncProgress, _syncMessage)
  /// - On successful sync: refreshes pending records list and shows success message
  /// - On sync error: displays error message to user
  /// 
  /// The subscription remains active throughout the screen's lifecycle and
  /// enables real-time feedback during synchronization operations.
  void _subscribeToSync() {
    _syncSubscription = SyncService.syncStream.listen((syncData) {
      if (mounted) {
        setState(() {
          _isSyncing = syncData.status == SyncStatus.syncing;
          _syncProgress = syncData.progress;
          _syncMessage = syncData.message ?? '';
        });

        if (syncData.status == SyncStatus.success) {
          _loadPendingRecords();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sincronización completada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (syncData.status == SyncStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error en la sincronización: ${syncData.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  /// Loads pending records from the local database.
  /// 
  /// **Execution Order (Method 2 & 8):**
  /// - Called initially in `initState()` to populate the screen with pending data
  /// - Called again after successful sync to refresh the list and show updated state
  /// 
  /// This method:
  /// 1. Retrieves all pending records from DatabaseService
  /// 2. Updates the UI state with the loaded records
  /// 3. Sets loading state to false to display the data
  /// 4. Handles errors gracefully with logging and fallback state
  /// 
  /// The method ensures users always see current pending record information.
  Future<void> _loadPendingRecords() async {
    try {
      final records = await DatabaseService.getAllPendingRecords();
      setState(() {
        _pendingRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      LoggingService.error(
        'Error loading pending records',
        'PendingSyncScreen',
        e,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Starts automatic synchronization when the screen loads.
  /// 
  /// **Execution Order (Method 4):**
  /// Called from `initState()` to begin automatic sync process:
  /// 1. Checks for internet connectivity first
  /// 2. If offline: logs info and exits gracefully (no error shown to user)
  /// 3. If online: calls `_syncPendingRecords()` to start the sync process
  /// 
  /// This method provides seamless automatic sync without overwhelming users
  /// with error messages when they're offline. The sync will naturally happen
  /// when connectivity is restored through the offline manager.
  Future<void> _startAutoSync() async {
    try {
      // Check connectivity before attempting sync
      final isConnected = await ConnectivityService.isConnected();
      if (!isConnected) {
        LoggingService.info(
          'Device is offline, skipping auto-sync',
          'PendingSyncScreen',
        );
        return;
      }

      // Small delay to allow UI to settle before starting sync
      await Future.delayed(const Duration(milliseconds: 500));
      
      LoggingService.info(
        'Starting automatic synchronization',
        'PendingSyncScreen',
      );
      
      await _syncPendingRecords();
    } catch (e) {
      LoggingService.warning(
        'Auto-sync failed, will retry manually: $e',
        'PendingSyncScreen',
      );
      // Don't show error to user for auto-sync failures
      // They can manually trigger sync if needed
    }
  }

  /// Main coordinator method for synchronizing pending records.
  /// 
  /// **Execution Order (Method 5):**
  /// - Can be called automatically from `_startAutoSync()` or manually by user
  /// - Prevents duplicate sync operations by checking _isSyncing flag
  /// - Verifies connectivity before proceeding
  /// - Coordinates the sync of different record types in sequence
  /// - Manages UI state throughout the process
  /// 
  /// **Sync Sequence:**
  /// 1. Validates preconditions (not already syncing, has connectivity)
  /// 2. Sets syncing state and progress indicators
  /// 3. Calls `_syncPendingAnimals()` first
  /// 4. Calls `_syncPendingPersonalFinca()` second  
  /// 5. Calls `_loadPendingRecords()` to refresh the list
  /// 6. Resets syncing state and clears progress indicators
  /// 
  /// This method ensures reliable and user-friendly synchronization.
  Future<void> _syncPendingRecords() async {
    // Prevent multiple sync operations running simultaneously
    if (_isSyncing) {
      LoggingService.warning(
        'Sync already in progress, ignoring duplicate request',
        'PendingSyncScreen',
      );
      return;
    }

    // Check connectivity first
    final isConnected = await ConnectivityService.isConnected();
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sin conexión a internet. Verifica tu conectividad e inténtalo de nuevo.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncProgress = 0.0;
      _syncMessage = 'Iniciando sincronización...';
    });

    try {
      await _syncPendingAnimals();
      await _syncPendingPersonalFinca();
      await _loadPendingRecords(); // Refresh the list
    } catch (e) {
      LoggingService.error(
        'Error syncing pending records',
        'PendingSyncScreen',
        e,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al sincronizar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSyncing = false;
        _syncProgress = 0.0;
        _syncMessage = '';
      });
    }
  }

  /// Synchronizes pending animal records with the server.
  /// 
  /// **Execution Order (Method 6):**
  /// Called from `_syncPendingRecords()` as the first sync operation:
  /// 1. Retrieves pending animals from local database
  /// 2. If no animals: updates progress and returns early
  /// 3. For each animal: processes CREATE or UPDATE operations
  /// 4. Handles duplicate prevention by checking if already synced
  /// 5. Updates server via AuthService and marks as synced locally
  /// 6. Provides progress feedback (animals take 50% of total progress)
  /// 
  /// **Animal Processing Flow:**
  /// - CREATE: sends animal data to server, gets real ID, updates local record
  /// - UPDATE: sends changes to server, marks update as synced
  /// - Continues processing even if individual animals fail
  /// - Logs success/failure for each animal for debugging
  /// 
  /// This method ensures animals are synchronized first as they're often
  /// referenced by other records.
  Future<void> _syncPendingAnimals() async {
    final pendingAnimals = await DatabaseService.getPendingAnimalsOffline();

    if (pendingAnimals.isEmpty) {
      setState(() {
        _syncMessage = 'No hay animales pendientes por sincronizar';
        _syncProgress = 1.0;
      });
      return;
    }

    setState(() {
      _syncMessage = 'Sincronizando ${pendingAnimals.length} animales...';
    });

    int successfulSyncs = 0;
    int skippedSyncs = 0;

    for (int i = 0; i < pendingAnimals.length; i++) {
      final animalData = pendingAnimals[i];

      setState(() {
        _syncProgress = (i + 1) / pendingAnimals.length * 0.5; // Animals take 50% of progress
        _syncMessage =
            'Sincronizando animal ${i + 1} de ${pendingAnimals.length}...';
      });

      try {
        final tempId = animalData['id_animal'] as int;
        final operation = animalData['pending_operation'] as String?;

        // Check if animal is already synced to prevent duplicates
        final isAlreadySynced = await DatabaseService.isAnimalAlreadySynced(
          tempId,
        );
        if (isAlreadySynced) {
          LoggingService.info(
            'Animal ${animalData['nombre']} is already synced, skipping',
            'PendingSyncScreen',
          );
          skippedSyncs++;
          continue;
        }

        if (operation == 'CREATE') {
          // Create the animal on the server
          final animal = await _authService.createAnimal(
            idRebano: animalData['id_rebano'] as int,
            nombre: animalData['nombre'] as String,
            codigoAnimal: animalData['codigo_animal'] as String,
            sexo: animalData['sexo'] as String,
            fechaNacimiento: animalData['fecha_nacimiento'] as String,
            procedencia: animalData['procedencia'] as String,
            fkComposicionRaza: animalData['fk_composicion_raza'] as int,
            estadoId: animalData['estado_id'] as int,
            etapaId: animalData['etapa_id'] as int,
          );

          // Mark as synced in local database
          await DatabaseService.markAnimalAsSynced(tempId, animal.idAnimal);
        } else if (operation == 'UPDATE') {
          // Update the animal on the server
          await _authService.updateAnimal(
            idAnimal: animalData['id_animal'] as int,
            idRebano: animalData['id_rebano'] as int,
            nombre: animalData['nombre'] as String,
            codigoAnimal: animalData['codigo_animal'] as String,
            sexo: animalData['sexo'] as String,
            fechaNacimiento: animalData['fecha_nacimiento'] as String,
            procedencia: animalData['procedencia'] as String,
            fkComposicionRaza: animalData['fk_composicion_raza'] as int,
            estadoId: animalData['estado_id'] as int,
            etapaId: animalData['etapa_id'] as int,
          );

          // Mark as synced in local database (for updates, the ID stays the same)
          await DatabaseService.markAnimalUpdateAsSynced(tempId);
        }

        LoggingService.info(
          'Animal synced successfully: ${animalData['nombre']}',
          'PendingSyncScreen',
        );
        successfulSyncs++;
      } catch (e) {
        LoggingService.error(
          'Error syncing animal: ${animalData['nombre']}',
          'PendingSyncScreen',
          e,
        );
        // Continue with other animals even if one fails
      }
    }

    setState(() {
      _syncMessage =
          'Animales sincronizados: $successfulSyncs exitosos${skippedSyncs > 0 ? ', $skippedSyncs omitidos' : ''}';
    });
  }

  /// Synchronizes pending personal finca (farm staff) records with the server.
  /// 
  /// **Execution Order (Method 7):**
  /// Called from `_syncPendingRecords()` as the second sync operation:
  /// 1. Retrieves pending personal finca records from local database
  /// 2. If no records: updates progress and returns early
  /// 3. For each record: processes CREATE or UPDATE operations
  /// 4. Creates PersonalFinca objects for server communication
  /// 5. Updates server via AuthService and marks as synced locally
  /// 6. Provides progress feedback (personal finca takes remaining 50% of progress)
  /// 
  /// **PersonalFinca Processing Flow:**
  /// - CREATE: sends record to server, gets real ID, updates local record
  /// - UPDATE: sends changes to server, marks update as synced
  /// - Continues processing even if individual records fail
  /// - Logs success/failure for each record for debugging
  /// 
  /// This method runs after animals to ensure proper sequencing of
  /// dependent data synchronization.
  Future<void> _syncPendingPersonalFinca() async {
    final pendingPersonal = await DatabaseService.getPendingPersonalFincaOffline();

    if (pendingPersonal.isEmpty) {
      setState(() {
        _syncMessage = 'No hay personal de finca pendiente por sincronizar';
        _syncProgress = 1.0;
      });
      return;
    }

    setState(() {
      _syncMessage = 'Sincronizando ${pendingPersonal.length} personal de finca...';
    });

    int successfulSyncs = 0;
    int skippedSyncs = 0;

    for (int i = 0; i < pendingPersonal.length; i++) {
      final personalData = pendingPersonal[i];

      setState(() {
        _syncProgress = 0.5 + (i + 1) / pendingPersonal.length * 0.5; // Personal finca takes remaining 50%
        _syncMessage =
            'Sincronizando personal ${i + 1} de ${pendingPersonal.length}...';
      });

      try {
        final tempId = personalData['id_tecnico'] as int;
        final operation = personalData['pending_operation'] as String?;

        if (operation == 'CREATE') {
          // Create the personal finca on the server
          final personalFinca = PersonalFinca(
            idTecnico: 0, // Will be assigned by server
            idFinca: personalData['id_finca'] as int,
            cedula: personalData['cedula'] as int,
            nombre: personalData['nombre'] as String,
            apellido: personalData['apellido'] as String,
            telefono: personalData['telefono'] as String,
            correo: personalData['correo'] as String,
            tipoTrabajador: personalData['tipo_trabajador'] as String,
            createdAt: personalData['created_at'] as String,
            updatedAt: personalData['updated_at'] as String,
          );

          final createdPersonal = await _authService.createPersonalFinca(personalFinca);

          // Mark as synced in local database
          await DatabaseService.markPersonalFincaAsSynced(tempId, createdPersonal.idTecnico);
        } else if (operation == 'UPDATE') {
          // Update the personal finca on the server
          final personalFinca = PersonalFinca(
            idTecnico: personalData['id_tecnico'] as int,
            idFinca: personalData['id_finca'] as int,
            cedula: personalData['cedula'] as int,
            nombre: personalData['nombre'] as String,
            apellido: personalData['apellido'] as String,
            telefono: personalData['telefono'] as String,
            correo: personalData['correo'] as String,
            tipoTrabajador: personalData['tipo_trabajador'] as String,
            createdAt: personalData['created_at'] as String,
            updatedAt: personalData['updated_at'] as String,
          );

          await _authService.updatePersonalFinca(personalFinca);

          // Mark as synced in local database (for updates, the ID stays the same)
          await DatabaseService.markPersonalFincaUpdateAsSynced(tempId);
        }

        LoggingService.info(
          'Personal finca synced successfully: ${personalData['nombre']} ${personalData['apellido']}',
          'PendingSyncScreen',
        );
        successfulSyncs++;
      } catch (e) {
        LoggingService.error(
          'Error syncing personal finca: ${personalData['nombre']} ${personalData['apellido']}',
          'PendingSyncScreen',
          e,
        );
        // Continue with other personal even if one fails
      }
    }

    setState(() {
      _syncMessage =
          'Sincronización completada: $successfulSyncs personal sincronizados${skippedSyncs > 0 ? ', $skippedSyncs omitidos' : ''}';
      _syncProgress = 1.0;
    });
  }

  /// Formats a timestamp into a human-readable relative time string.
  /// 
  /// **Utility Method:**
  /// Converts millisecond timestamps to user-friendly formats:
  /// - Less than 1 minute: "Hace menos de un minuto"
  /// - Less than 60 minutes: "Hace X minutos"
  /// - Less than 24 hours: "Hace X horas"  
  /// - 24+ hours: "Hace X días"
  /// 
  /// Used to display when pending records were created in the UI.
  String _formatDateTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Hace menos de un minuto';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minutos';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} horas';
    } else {
      return 'Hace ${difference.inDays} días';
    }
  }

  /// Builds a card widget to display information about a pending record.
  /// 
  /// **UI Helper Method:**
  /// Creates a card showing:
  /// - Icon and color based on record type (Animal, CambiosAnimal, PersonalFinca)
  /// - Record name and details (type, operation, timestamp)
  /// - "Pendiente" (Pending) status badge
  /// 
  /// **Record Types:**
  /// - Animal: green pets icon for new animal records
  /// - CambiosAnimal: blue update icon for animal modifications
  /// - PersonalFinca: orange person icon for farm staff records
  /// 
  /// Used by the ListView to display each pending record consistently.
  Widget _buildPendingRecordCard(Map<String, dynamic> record) {
    final type = record['type'] as String;
    final name = record['name'] as String;
    final operation = record['operation'] as String;
    final timestamp = record['created_at'] as int;

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'Animal':
        icon = Icons.pets;
        iconColor = Colors.green;
        break;
      case 'CambiosAnimal':
        icon = Icons.update;
        iconColor = Colors.blue;
        break;
      case 'PersonalFinca':
        icon = Icons.person;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.sync;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: $type'),
            Text('Operación: $operation'),
            Text(
              _formatDateTime(timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Pendiente',
            style: TextStyle(
              color: Colors.orange[800],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the main UI for the pending sync screen.
  /// 
  /// **UI Structure:**
  /// 1. AppBar with screen title
  /// 2. Summary card showing sync status (synced/pending count)
  /// 3. Sync progress indicator (visible during active sync)
  /// 4. List of pending records (or empty state message)
  /// 5. Load records button (when auto-load disabled and no records)
  /// 6. Sync button (when there are pending records)
  /// 
  /// **Dynamic UI Elements:**
  /// - Summary card changes color based on sync status
  /// - Progress bar appears during sync operations
  /// - Buttons enable/disable based on sync state
  /// - Empty state vs record list based on data availability
  /// 
  /// The UI provides clear visual feedback about sync status and progress.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros Pendientes'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Summary card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _pendingRecords.isEmpty
                  ? Color.fromARGB(255, 192, 212, 59)
                  : Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _pendingRecords.isEmpty
                    ? Color.fromARGB(255, 192, 212, 59)
                    : Colors.orange[200]!,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _pendingRecords.isEmpty
                          ? Icons.check_circle
                          : Icons.sync_problem,
                      color: _pendingRecords.isEmpty
                          ? Colors.green[800]
                          : Colors.orange[800],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _pendingRecords.isEmpty
                          ? 'Todos los cambios están sincronizados'
                          : '${_pendingRecords.length} registros pendientes por sincronizar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _pendingRecords.isEmpty
                            ? Colors.green[800]
                            : Colors.orange[800],
                      ),
                    ),
                  ],
                ),
                if (_pendingRecords.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Estos registros se crearon sin conexión y se sincronizarán con el servidor cuando presiones "Sincronizar mis cambios".',
                    style: TextStyle(color: Colors.orange[800]),
                  ),
                ],
              ],
            ),
          ),

          // Sync progress (only visible when syncing)
          if (_isSyncing) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _syncMessage,
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _syncProgress,
                    backgroundColor: Colors.blue[100],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue[600]!,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_syncProgress * 100).toInt()}% completado',
                    style: TextStyle(color: Colors.blue[700], fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // List of pending records
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pendingRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_done,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay registros pendientes',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Todos tus cambios están sincronizados',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _pendingRecords.length,
                    itemBuilder: (context, index) {
                      return _buildPendingRecordCard(_pendingRecords[index]);
                    },
                  ),
          ),

          // Load records button (when auto-load is disabled)
          if (!_autoLoadOnInit && _pendingRecords.isEmpty && !_isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _loadPendingRecords,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Cargar Registros Pendientes',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

          // Sync button
          if (_pendingRecords.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isSyncing ? null : _syncPendingRecords,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSyncing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Sincronizando...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      )
                    : const Text(
                        'Sincronizar mis cambios',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
