# Documentación de Sincronización de Datos de Animales

## Resumen Ejecutivo

Este documento describe el proceso paso a paso de sincronización de datos de animales que se ejecuta cuando se reestablece la conexión a internet en la aplicación GanaderaSoft. El proceso incluye tanto la descarga de datos frescos del servidor como la sincronización de cambios locales pendientes.

## Componentes Principales

### Servicios Involucrados

1. **SyncService** (`lib/services/sync_service.dart`)
   - Orquestador principal de la sincronización
   - Coordina todo el proceso de descarga de datos del servidor

2. **PendingSyncScreen** (`lib/screens/pending_sync_screen.dart`)
   - Maneja la sincronización de registros creados/modificados localmente
   - Procesa operaciones CREATE y UPDATE pendientes

3. **DatabaseService** (`lib/services/database_service.dart`)
   - Gestiona todas las operaciones de base de datos local SQLite
   - Provee métodos para guardar, actualizar y consultar datos

4. **AuthService** (`lib/services/auth_service.dart`)
   - Maneja la comunicación con la API del servidor
   - Ejecuta llamadas HTTP para obtener y enviar datos

5. **ConnectivityService** (`lib/services/connectivity_service.dart`)
   - Verifica el estado de conectividad de red
   - Determina si la sincronización puede proceder

## Proceso de Sincronización - Flujo Principal

### Fase 1: Verificación y Preparación

#### 1.1 Detección de Conectividad
```
Ubicación: SyncService.syncData() líneas 30-42
```

1. Se verifica la conectividad usando `ConnectivityService.isConnected()`
2. Si no hay conexión:
   - Se registra warning en logs
   - Se envía mensaje de error al stream de sincronización
   - Se retorna `false` terminando el proceso

#### 1.2 Inicialización del Proceso
```
Ubicación: SyncService.syncData() líneas 44-55
```

1. Se registra en logs que la conexión está disponible
2. Se envía al stream de sincronización:
   - Estado: `SyncStatus.syncing`
   - Mensaje: "Iniciando sincronización..."
   - Progreso: 0.05 (5%)

### Fase 2: Sincronización de Datos Base

#### 2.1 Sincronización de Datos de Usuario
```
Ubicación: SyncService.syncData() líneas 57-84
Progreso: 0.1 (10%)
```

1. Se actualiza el stream: "Sincronizando datos del usuario..."
2. Se ejecuta `_authService.getProfile()` para obtener perfil del servidor
3. Se guarda el usuario en base de datos local: `DatabaseService.saveUserOffline(user)`
4. Se guarda en el servicio de autenticación: `_authService.saveUser(user)`
5. En caso de error:
   - Se registra error en logs
   - Se envía mensaje de error al stream
   - Se termina el proceso retornando `false`

#### 2.2 Sincronización de Fincas
```
Ubicación: SyncService.syncData() líneas 86-116
Progreso: 0.2 (20%)
```

1. Se actualiza el stream: "Sincronizando datos de fincas..."
2. Se ejecuta `_authService.getFincas()` para obtener fincas del servidor
3. Se guardan las fincas: `DatabaseService.saveFincasOffline(fincasResponse.fincas)`
4. Se registra el número de fincas sincronizadas
5. En caso de error se maneja similar al paso anterior

#### 2.3 Sincronización de Rebaños
```
Ubicación: SyncService.syncData() líneas 118-148
Progreso: 0.25 (25%)
```

1. Se actualiza el stream: "Sincronizando datos de rebaños..."
2. Se ejecuta `_authService.getRebanos()` para obtener rebaños del servidor
3. Se guardan los rebaños: `DatabaseService.saveRebanosOffline(rebanosResponse.rebanos)`
4. Se registra el número de rebaños sincronizados
5. En caso de error se maneja similar a los pasos anteriores

### Fase 3: Sincronización de Animales (Proceso Principal)

#### 3.1 Sincronización de Datos Básicos de Animales
```
Ubicación: SyncService.syncData() líneas 150-162
Progreso: 0.3 (30%)
```

1. Se actualiza el stream: "Sincronizando datos de animales..."
2. Se ejecuta `_authService.getAnimales()` para obtener lista de animales del servidor
3. Se guardan los animales: `DatabaseService.saveAnimalesOffline(animalesResponse.animales)`

#### 3.2 Sincronización de Detalles de Animales
```
Ubicación: SyncService.syncData() líneas 164-191
Progreso: 0.3 a 0.5 (30% a 50%)
```

**Este es el proceso más intensivo en recursos:**

1. Se obtiene el número total de animales: `animalesResponse.animales.length`
2. Se inicializa contador de animales sincronizados: `syncedAnimals = 0`
3. **Para cada animal** en la lista:
   
   a. **Obtención de Detalle Individual:**
   ```dart
   final animalDetailResponse = await _authService.getAnimalDetail(animal.idAnimal);
   ```
   
   b. **Guardado en Base de Datos Local:**
   ```dart
   await DatabaseService.saveAnimalDetailOffline(animalDetailResponse.data);
   ```
   
   c. **Actualización de Progreso:**
   ```dart
   syncedAnimals++;
   double detailProgress = 0.3 + (0.2 * syncedAnimals / totalAnimals);
   ```
   
   d. **Reporte de Progreso en Tiempo Real:**
   - Estado: `SyncStatus.syncing`
   - Mensaje: "Sincronizando detalles de animales... (X/Y)"
   - Progreso: Se incrementa gradualmente de 30% a 50%

4. **Manejo de Errores por Animal:**
   - Si falla un animal individual, se registra warning en logs
   - El proceso continúa con los siguientes animales
   - No se detiene toda la sincronización

#### 3.3 Finalización de Sincronización de Animales
```
Ubicación: SyncService.syncData() líneas 193-210
```

1. Se registra en logs el resultado:
   - Número total de animales sincronizados
   - Número de detalles de animales sincronizados
2. En caso de error general:
   - Se registra error crítico en logs
   - Se envía mensaje de error al stream
   - Se termina el proceso retornando `false`

### Fase 4: Sincronización de Datos de Gestión de Finca

#### 4.1 Sincronización de Cambios de Animales
```
Ubicación: SyncService._syncFarmManagementData() líneas 507-529
Progreso: 0.52 (52%)
```

1. Se actualiza el stream: "Sincronizando cambios de animales..."
2. Se ejecuta `_authService.getCambiosAnimal()`
3. Se guardan: `DatabaseService.saveCambiosAnimalOffline(cambiosResponse.data)`
4. Se registra el número de registros sincronizados
5. Errores se manejan como warnings (no críticos)

#### 4.2 Sincronización de Peso Corporal
```
Ubicación: SyncService._syncFarmManagementData() líneas 531-553
Progreso: 0.54 (54%)
```

1. Se actualiza el stream: "Sincronizando peso corporal..."
2. Se ejecuta `_authService.getPesoCorporal()`
3. Se guardan: `DatabaseService.savePesoCorporalOffline(pesoResponse.data)`
4. Se registra el número de registros sincronizados

#### 4.3 Sincronización de Personal de Finca
```
Ubicación: SyncService._syncFarmManagementData() líneas 555-577
Progreso: 0.56 (56%)
```

1. Se actualiza el stream: "Sincronizando personal de finca..."
2. Se ejecuta `_authService.getPersonalFinca()`
3. Se guardan: `DatabaseService.savePersonalFincaOffline(personalResponse.data)`
4. Se registra el número de registros sincronizados

#### 4.4 Sincronización de Lactancia
```
Ubicación: SyncService._syncFarmManagementData() líneas 579-601
Progreso: 0.58 (58%)
```

1. Se actualiza el stream: "Sincronizando registros de lactancia..."
2. Se ejecuta `_authService.getLactancia()`
3. Se guardan: `DatabaseService.saveLactanciaOffline(lactanciaResponse.data)`
4. Se registra el número de registros sincronizados

### Fase 5: Sincronización de Datos de Configuración

```
Ubicación: SyncService._syncConfigurationData() líneas 247-270+
Progreso: 0.55+ (55%+)
```

Se sincronizan múltiples tipos de datos de configuración:
- Estados de Salud
- Etapas de Animales
- Estados de Animales
- Composición de Raza
- Configuraciones del Sistema

### Fase 6: Finalización del Proceso Principal

```
Ubicación: SyncService.syncData() líneas 218-229
Progreso: 1.0 (100%)
```

1. Se registra en logs: "Data synchronization completed successfully"
2. Se envía al stream de sincronización:
   - Estado: `SyncStatus.success`
   - Mensaje: "Sincronización completada exitosamente"
   - Progreso: 1.0 (100%)
3. Se retorna `true` indicando éxito

## Proceso de Sincronización - Registros Pendientes

### Descripción General

Paralelamente al proceso principal, existe un mecanismo para sincronizar cambios locales (animales creados/modificados offline) con el servidor.

### Fase 1: Inicialización de Sincronización de Pendientes

#### 1.1 Detección y Carga de Registros Pendientes
```
Ubicación: PendingSyncScreen._loadPendingRecords()
```

1. Se ejecuta `DatabaseService.getAllPendingRecords()` para obtener todos los registros pendientes
2. Se filtran y organizan por tipo (animales, personal finca, etc.)
3. Se actualiza la interfaz de usuario con la lista de pendientes

#### 1.2 Verificación de Conectividad para Pendientes
```
Ubicación: PendingSyncScreen._syncPendingRecords() líneas 226-237
```

1. Se verifica conectividad con `ConnectivityService.isConnected()`
2. Si no hay conexión:
   - Se muestra mensaje al usuario
   - Se termina el proceso
3. Si hay conexión se procede con la sincronización

### Fase 2: Sincronización de Animales Pendientes

#### 2.1 Obtención de Animales Pendientes
```
Ubicación: PendingSyncScreen._syncPendingAnimals() líneas 289-298
```

1. Se obtienen animales pendientes: `DatabaseService.getPendingAnimalsOffline()`
2. Si no hay animales pendientes:
   - Se actualiza mensaje: "No hay animales pendientes por sincronizar"
   - Se establece progreso al 100%
   - Se retorna terminando esta fase

#### 2.2 Procesamiento de Cada Animal Pendiente
```
Ubicación: PendingSyncScreen._syncPendingAnimals() líneas 307-381
```

**Para cada animal pendiente:**

1. **Verificación de Estado:**
   ```dart
   final isAlreadySynced = await DatabaseService.isAnimalAlreadySynced(tempId);
   ```
   - Si ya está sincronizado, se omite y continúa con el siguiente

2. **Procesamiento según Operación:**

   **a. Operación CREATE:**
   ```dart
   final animal = await _authService.createAnimal(
     idRebano: animalData['id_rebano'] as int,
     nombre: animalData['nombre'] as String,
     // ... otros campos
   );
   ```
   - Se envía el animal al servidor
   - Se obtiene el ID real del servidor
   - Se marca como sincronizado: `DatabaseService.markAnimalAsSynced(tempId, animal.idAnimal)`

   **b. Operación UPDATE:**
   ```dart
   await _authService.updateAnimal(
     idAnimal: animalData['id_animal'] as int,
     // ... campos actualizados
   );
   ```
   - Se envían los cambios al servidor
   - Se marca la actualización como sincronizada: `DatabaseService.markAnimalUpdateAsSynced(tempId)`

3. **Actualización de Progreso:**
   - Progreso: `(i + 1) / pendingAnimals.length * 0.5` (los animales toman 50% del progreso)
   - Mensaje: "Sincronizando animal X de Y..."

4. **Manejo de Errores:**
   - Si falla un animal, se registra el error
   - El proceso continúa con los siguientes animales
   - Se mantiene contador de éxitos y omisiones

### Fase 3: Sincronización de Personal de Finca Pendiente

```
Ubicación: PendingSyncScreen._syncPendingPersonalFinca()
```

Similar al proceso de animales, pero para registros de personal de finca:
- Se procesan operaciones CREATE y UPDATE
- Se utiliza el 50% restante del progreso
- Se mantiene el mismo patrón de manejo de errores

### Fase 4: Finalización de Sincronización de Pendientes

1. Se recargan los registros pendientes para reflejar los cambios
2. Se restablece el estado de sincronización
3. Se limpia el progreso y mensajes de estado

## Estructura de Base de Datos

### Tabla `animales`
```sql
CREATE TABLE animales (
  id_animal INTEGER PRIMARY KEY,
  id_rebano INTEGER NOT NULL,
  nombre TEXT NOT NULL,
  codigo_animal TEXT NOT NULL,
  sexo TEXT NOT NULL,
  fecha_nacimiento TEXT NOT NULL,
  procedencia TEXT NOT NULL,
  archivado INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  fk_composicion_raza INTEGER NOT NULL,
  rebano_data TEXT,
  composicion_raza_data TEXT,
  synced INTEGER DEFAULT 1,
  is_pending INTEGER DEFAULT 0,
  pending_operation TEXT,
  estado_id INTEGER,
  etapa_id INTEGER,
  local_updated_at INTEGER NOT NULL
)
```

### Tabla `animal_detail`
```sql
CREATE TABLE animal_detail (
  id_animal INTEGER PRIMARY KEY,
  animal_data TEXT NOT NULL,
  etapa_animales_data TEXT NOT NULL,
  etapa_actual_data TEXT,
  estados_data TEXT,
  local_updated_at INTEGER NOT NULL
)
```

### Estados de Sincronización

- **synced = 1**: El registro está sincronizado con el servidor
- **synced = 0**: El registro no está sincronizado
- **is_pending = 1**: El registro tiene cambios pendientes por sincronizar
- **is_pending = 0**: El registro no tiene cambios pendientes
- **pending_operation**: Tipo de operación pendiente ('CREATE', 'UPDATE')

## Manejo de Errores y Recuperación

### Errores No Críticos
- Fallos en animales individuales durante sincronización de detalles
- Errores en datos de gestión de finca
- Fallos en registros pendientes individuales

**Comportamiento:**
- Se registra warning en logs
- Se continúa con el siguiente elemento
- No se detiene todo el proceso

### Errores Críticos
- Fallo de conectividad
- Error en sincronización de datos base (usuario, fincas, rebaños, animales principales)

**Comportamiento:**
- Se registra error crítico en logs
- Se envía mensaje de error al stream
- Se detiene todo el proceso de sincronización
- Se retorna `false`

### Mecanismo de Logs

El sistema utiliza `LoggingService` con diferentes niveles:
- **DEBUG**: Información detallada para desarrollo
- **INFO**: Información general del proceso
- **WARNING**: Errores no críticos
- **ERROR**: Errores críticos

### Stream de Progreso

Se utiliza un `StreamController<SyncData>` para comunicar el estado:
- **Estado**: `idle`, `syncing`, `success`, `error`
- **Mensaje**: Descripción textual del proceso actual
- **Progreso**: Valor de 0.0 a 1.0 indicando porcentaje completado

## Consideraciones de Rendimiento

### Optimizaciones Implementadas
1. **Sincronización Incremental**: Se verifica qué registros ya están sincronizados
2. **Procesamiento por Lotes**: Se procesan múltiples registros en secuencia
3. **Manejo de Memoria**: Se procesan animales uno por uno para evitar cargar todo en memoria
4. **Transacciones de Base de Datos**: Se utilizan transacciones para operaciones atómicas

### Limitaciones Conocidas
1. **Sincronización Secuencial**: Los detalles de animales se procesan uno por uno
2. **Dependencia de Red**: Requiere conexión estable durante todo el proceso
3. **Tiempo de Procesamiento**: Puede ser largo para fincas con muchos animales

## Flujo de Estados de la Aplicación

### Estado Offline
- Los usuarios pueden crear/modificar animales
- Los cambios se guardan con IDs temporales negativos
- Los registros se marcan como pendientes (`is_pending=1`, `synced=0`)

### Estado de Reconexión
- Se detecta conectividad disponible
- Se inicia automáticamente el proceso de sincronización
- Se muestra progreso al usuario en tiempo real

### Estado Sincronizado
- Todos los datos están actualizados con el servidor
- Los registros pendientes han sido procesados
- La aplicación puede funcionar normalmente

## Conclusión

El proceso de sincronización de animales es un sistema robusto que maneja tanto la descarga de datos frescos del servidor como la sincronización de cambios locales. El diseño permite recuperación de errores y mantiene la integridad de los datos durante todo el proceso.

La arquitectura modular facilita el mantenimiento y la extensión del sistema, mientras que el sistema de logs y reportes de progreso proporciona visibilidad completa del proceso para usuarios y desarrolladores.