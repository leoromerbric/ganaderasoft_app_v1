# Referencia Técnica - Implementación de Sincronización

## Fragmentos de Código Clave

### 1. Inicialización de Sincronización Principal

```dart
// lib/services/sync_service.dart - líneas 25-55
static Future<bool> syncData() async {
  LoggingService.info('Starting data synchronization...', 'SyncService');

  try {
    // Verificación de conectividad
    if (!await ConnectivityService.isConnected()) {
      LoggingService.warning('No internet connection for sync', 'SyncService');
      _syncController.add(SyncData(
        status: SyncStatus.error,
        message: 'No hay conexión a internet',
      ));
      return false;
    }

    // Notificación de inicio
    _syncController.add(SyncData(
      status: SyncStatus.syncing,
      message: 'Iniciando sincronización...',
      progress: 0.05,
    ));
    
    // ... continúa con fases de sincronización
  } catch (e) {
    LoggingService.error('Unexpected error during synchronization', 'SyncService', e);
    _syncController.add(SyncData(
      status: SyncStatus.error,
      message: 'Error inesperado: ${e.toString()}',
    ));
    return false;
  }
}
```

### 2. Sincronización Intensiva de Detalles de Animales

```dart
// lib/services/sync_service.dart - líneas 164-191
// Sincronización de detalles individuales de animales
LoggingService.debug('Syncing animal details...', 'SyncService');
int totalAnimals = animalesResponse.animales.length;
int syncedAnimals = 0;

for (final animal in animalesResponse.animales) {
  try {
    // Obtener detalle específico del animal
    final animalDetailResponse = await _authService.getAnimalDetail(animal.idAnimal);
    
    // Guardar en base de datos local
    await DatabaseService.saveAnimalDetailOffline(animalDetailResponse.data);
    syncedAnimals++;
    
    // Calcular y reportar progreso incremental
    double detailProgress = 0.3 + (0.2 * syncedAnimals / totalAnimals);
    _syncController.add(SyncData(
      status: SyncStatus.syncing,
      message: 'Sincronizando detalles de animales... ($syncedAnimals/$totalAnimals)',
      progress: detailProgress,
    ));
  } catch (e) {
    LoggingService.warning(
      'Failed to sync detail for animal ${animal.idAnimal}: $e',
      'SyncService',
    );
    // CRÍTICO: Continúa con otros animales aunque uno falle
  }
}
```

### 3. Procesamiento de Animales Pendientes

```dart
// lib/screens/pending_sync_screen.dart - líneas 333-366
// Verificación de duplicados y procesamiento según operación
final isAlreadySynced = await DatabaseService.isAnimalAlreadySynced(tempId);
if (isAlreadySynced) {
  LoggingService.info(
    'Animal ${animalData['nombre']} is already synced, skipping',
    'PendingSyncScreen',
  );
  skippedSyncs++;
  continue;
}

if (operation == 'CREATE') {
  // Crear animal en servidor
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

  // CRÍTICO: Marcar como sincronizado para actualizar ID temporal
  await DatabaseService.markAnimalAsSynced(tempId, animal.idAnimal);
} else if (operation == 'UPDATE') {
  // Actualizar animal existente en servidor
  await _authService.updateAnimal(/* parámetros de actualización */);
  
  // Marcar actualización como sincronizada
  await DatabaseService.markAnimalUpdateAsSynced(tempId);
}
```

### 4. Manejo de Estados de Base de Datos

```dart
// lib/services/database_service.dart - Operación markAnimalAsSynced
static Future<void> markAnimalAsSynced(int tempId, int realId) async {
  final db = await database;
  
  await db.transaction((txn) async {
    final updatedRows = await txn.update(
      'animales',
      {
        'id_animal': realId,           // Reemplazar ID temporal con ID real
        'synced': 1,                   // Marcar como sincronizado
        'is_pending': 0,               // Ya no está pendiente
        'pending_operation': null,     // Limpiar operación pendiente
        'local_updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id_animal = ? AND is_pending = 1 AND synced = 0',
      whereArgs: [tempId],
    );

    // Diagnóstico mejorado para debugging
    if (updatedRows == 0) {
      final existingRecords = await txn.query('animales', 
        where: 'id_animal = ?', 
        whereArgs: [tempId]
      );
      
      if (existingRecords.isEmpty) {
        LoggingService.error('No animal record found with tempId $tempId', 'DatabaseService');
        throw Exception('Animal with tempId $tempId not found');
      } else {
        final record = existingRecords.first;
        LoggingService.error(
          'Animal $tempId exists but is_pending=${record['is_pending']}, synced=${record['synced']}',
          'DatabaseService',
        );
        throw Exception('Animal with tempId $tempId already synced');
      }
    }
  });
}
```

## Configuración de Stream de Progreso

### Definición del Enum y Clase

```dart
// lib/services/sync_service.dart - líneas 8-16
enum SyncStatus { idle, syncing, success, error }

class SyncData {
  final SyncStatus status;
  final String? message;
  final double progress;

  SyncData({required this.status, this.message, this.progress = 0.0});
}
```

### Inicialización del StreamController

```dart
// lib/services/sync_service.dart - líneas 19-23
class SyncService {
  static final StreamController<SyncData> _syncController =
      StreamController<SyncData>.broadcast();
  
  static Stream<SyncData> get syncStream => _syncController.stream;
}
```

### Uso en UI para Mostrar Progreso

```dart
// Ejemplo de uso en widgets
StreamBuilder<SyncData>(
  stream: SyncService.syncStream,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final syncData = snapshot.data!;
      
      switch (syncData.status) {
        case SyncStatus.syncing:
          return LinearProgressIndicator(value: syncData.progress);
        case SyncStatus.success:
          return Text('Sincronización completada');
        case SyncStatus.error:
          return Text('Error: ${syncData.message}');
        default:
          return SizedBox.shrink();
      }
    }
    return SizedBox.shrink();
  },
)
```

## Estructura de Tablas de Base de Datos

### Tabla Principal de Animales

```sql
-- lib/services/database_service.dart - líneas de CREATE TABLE
CREATE TABLE animales (
  id_animal INTEGER PRIMARY KEY,           -- ID único (temp negativo, real positivo)
  id_rebano INTEGER NOT NULL,              -- Referencia al rebaño
  nombre TEXT NOT NULL,                    -- Nombre del animal
  codigo_animal TEXT NOT NULL,             -- Código identificador único
  sexo TEXT NOT NULL,                      -- 'M' o 'F'
  fecha_nacimiento TEXT NOT NULL,          -- Fecha en formato ISO
  procedencia TEXT NOT NULL,               -- Origen del animal
  archivado INTEGER NOT NULL,              -- 0 = activo, 1 = archivado
  created_at TEXT NOT NULL,                -- Timestamp de creación
  updated_at TEXT NOT NULL,                -- Timestamp de última actualización
  fk_composicion_raza INTEGER NOT NULL,    -- Referencia a composición racial
  rebano_data TEXT,                        -- JSON con datos del rebaño
  composicion_raza_data TEXT,              -- JSON con datos de raza
  synced INTEGER DEFAULT 1,                -- 0 = no sincronizado, 1 = sincronizado
  is_pending INTEGER DEFAULT 0,            -- 0 = no pendiente, 1 = pendiente
  pending_operation TEXT,                  -- 'CREATE', 'UPDATE', null
  estado_id INTEGER,                       -- Estado actual del animal
  etapa_id INTEGER,                        -- Etapa de vida actual
  local_updated_at INTEGER NOT NULL        -- Timestamp local de actualización
)
```

### Tabla de Detalles de Animales

```sql
CREATE TABLE animal_detail (
  id_animal INTEGER PRIMARY KEY,           -- Referencia al animal principal
  animal_data TEXT NOT NULL,               -- JSON con datos completos del animal
  etapa_animales_data TEXT NOT NULL,       -- JSON con etapas disponibles
  etapa_actual_data TEXT,                  -- JSON con etapa actual
  estados_data TEXT,                       -- JSON con estados disponibles
  local_updated_at INTEGER NOT NULL        -- Timestamp local de actualización
)
```

## Patrones de Manejo de Errores

### Errores Críticos (Detienen Sincronización)

```dart
try {
  // Operación crítica (usuario, fincas, rebaños, animales principales)
  final result = await _authService.getCriticalData();
  await DatabaseService.saveCriticalData(result);
} catch (e) {
  LoggingService.error('Critical sync failure', 'SyncService', e);
  _syncController.add(SyncData(
    status: SyncStatus.error,
    message: 'Error crítico: ${e.toString()}',
  ));
  return false; // Termina todo el proceso
}
```

### Errores No Críticos (Continúan Sincronización)

```dart
try {
  // Operación no crítica (detalle individual, gestión finca)
  final result = await _authService.getNonCriticalData();
  await DatabaseService.saveNonCriticalData(result);
} catch (e) {
  LoggingService.warning('Non-critical sync warning', 'SyncService', e);
  // NO se detiene el proceso, continúa con siguiente elemento
}
```

## Configuraciones de Conectividad

### Verificación de Estado de Red

```dart
// lib/services/connectivity_service.dart
class ConnectivityService {
  static Future<bool> isConnected() async {
    // Implementación específica para verificar conectividad
    // Puede incluir verificación de DNS, ping a servidor, etc.
  }
}
```

### Retry Logic Recomendado

```dart
// Patrón recomendado para reintentos
Future<T> executeWithRetry<T>(Future<T> Function() operation, {
  int maxRetries = 3,
  Duration delay = const Duration(seconds: 2),
}) async {
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (e) {
      if (attempt == maxRetries) rethrow;
      
      LoggingService.warning('Attempt $attempt failed, retrying...', 'SyncService');
      await Future.delayed(delay * attempt); // Backoff exponencial
    }
  }
  throw Exception('Max retries exceeded');
}
```

## Optimizaciones de Rendimiento

### Procesamiento por Lotes

```dart
// Procesamiento eficiente para múltiples registros
static Future<void> saveBatchAnimales(List<Animal> animales) async {
  final db = await database;
  
  await db.transaction((txn) async {
    final batch = txn.batch();
    
    for (final animal in animales) {
      batch.insert('animales', animal.toMap(), 
        conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    await batch.commit(noResult: true); // Más eficiente
  });
}
```

### Gestión de Memoria

```dart
// Procesamiento streaming para datasets grandes
Stream<Animal> getAnimalesStream() async* {
  final animales = await _authService.getAnimales();
  
  for (final animal in animales.animales) {
    yield animal;
    // Permite que garbage collector libere memoria entre animales
  }
}
```

## Testing y Verificación

### Test de Integración Completo

```dart
// test/offline_animal_integration_test.dart
test('complete offline animal creation and sync flow', () async {
  // 1. Crear animal offline
  await DatabaseService.savePendingAnimalOffline(/* datos del animal */);
  
  // 2. Verificar estado pendiente
  final pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
  expect(pendingAnimals.length, equals(1));
  expect(pendingAnimals.first['is_pending'], equals(1));
  
  // 3. Simular sincronización exitosa
  final tempId = pendingAnimals.first['id_animal'] as int;
  await DatabaseService.markAnimalAsSynced(tempId, 100); // ID real
  
  // 4. Verificar estado sincronizado
  final syncedAnimals = await DatabaseService.getPendingAnimalsOffline();
  expect(syncedAnimals.length, equals(0));
});
```

### Verificación Manual

```bash
# manual_verification_sync_fix.sh
echo "=== Verificación Manual de Sincronización ==="
echo "1. Crear animal offline"
echo "2. Verificar en tabla animales: is_pending=1, synced=0"  
echo "3. Ejecutar sincronización"
echo "4. Verificar animal sincronizado: is_pending=0, synced=1"
echo "5. Confirmar ID temporal reemplazado por ID real"
```

## Conclusiones de Implementación

### Principios de Diseño Aplicados

1. **Robustez**: El sistema continúa funcionando aunque fallen componentes individuales
2. **Transparencia**: Progreso y errores se reportan claramente al usuario
3. **Integridad**: Las transacciones atómicas previenen corrupción de datos
4. **Eficiencia**: Se optimiza para minimizar transferencia de datos y uso de memoria
5. **Recuperación**: El sistema puede reanudar desde cualquier punto de falla

### Lecciones Aprendidas

1. **IDs Temporales**: Usar IDs negativos evita conflictos con IDs reales del servidor
2. **Estado de Sincronización**: Campos `synced` e `is_pending` permiten tracking preciso
3. **Manejo de Errores Granular**: Distinguir entre errores críticos y no críticos
4. **Progress Reporting**: Feedback en tiempo real mejora experiencia de usuario
5. **Transacciones**: Operaciones atómicas son esenciales para integridad de datos