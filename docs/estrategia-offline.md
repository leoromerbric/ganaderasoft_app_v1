# Estrategia Offline

## Visión General

GanaderaSoft implementa una estrategia **offline-first** que permite a los usuarios trabajar completamente sin conexión a internet. Todos los datos se almacenan localmente en SQLite y se sincronizan con el servidor cuando hay conectividad disponible.

## Características de la Implementación Offline

### ✅ Funcionalidades Offline Completas
- Autenticación con credenciales almacenadas localmente
- Creación, edición y eliminación de registros
- Consulta de todos los datos desde cache local
- Gestión completa de fincas, animales y personal
- Registros de producción (leche, peso corporal, lactancia)
- Datos de configuración en cache

### ✅ Sincronización Inteligente
- Sincronización manual a través del botón "Sincronizar cambios"
- Detección automática de conflictos
- Preservación de datos modificados offline
- Sincronización por lotes para eficiencia

## Arquitectura de Datos Offline

### Base de Datos SQLite Local

```mermaid
erDiagram
    users ||--o{ fincas : "propietario"
    fincas ||--o{ rebanos : "contiene"
    rebanos ||--o{ animales : "agrupa"
    fincas ||--o{ personal_finca : "emplea"
    animales ||--o{ cambios_animal : "tiene"
    animales ||--o{ peso_corporal : "registra"
    animales ||--o{ lactancia : "produce"
    
    users {
        int id PK
        string name
        string email
        string type_user
        string password_hash
        int modifiedOffline
        int synced
    }
    
    fincas {
        int id_finca PK
        int id_propietario FK
        string nombre
        string explotacion_tipo
        int modifiedOffline
        timestamp local_updated_at
    }
    
    animales {
        int id_animal PK
        int id_rebano FK
        string nombre
        string codigo_animal
        int modifiedOffline
        int is_pending
        string pending_operation
    }
    
    cambios_animal {
        int id_cambio PK
        string fecha_cambio
        real peso
        real altura
        int is_pending
        string pending_operation
    }
    
    peso_corporal {
        int id_peso PK
        real peso
        date fecha_registro
        int is_pending
        string pending_operation
    }
    
    lactancia {
        int lactancia_id PK
        date lactancia_fecha_inicio
        date lactancia_fecha_fin
        int is_pending
        string pending_operation
    }
```

### Columnas de Control Offline

Cada tabla tiene columnas específicas para el manejo offline:

- **`modifiedOffline`**: Indica si el registro fue modificado offline
- **`synced`**: Indica si el registro está sincronizado con el servidor
- **`is_pending`**: Indica si hay operaciones pendientes de sincronización
- **`pending_operation`**: Tipo de operación pendiente (CREATE, UPDATE, DELETE)
- **`local_updated_at`**: Timestamp de última modificación local

## Flujos de Operación Offline

### 1. Autenticación Offline

```mermaid
sequenceDiagram
    participant U as Usuario
    participant LS as Login Screen
    participant AS as Auth Service
    participant DB as SQLite
    participant SP as Shared Preferences
    
    U->>LS: Ingresa credenciales
    LS->>AS: login(email, password)
    AS->>AS: hashPassword(password)
    AS->>DB: Busca usuario con email
    DB-->>AS: Datos de usuario
    AS->>AS: Compara hash de contraseña
    
    alt Credenciales válidas
        AS->>SP: Guarda token offline
        AS->>LS: Usuario autenticado
        LS->>U: Acceso a la aplicación
    else Credenciales inválidas
        AS->>LS: Error de autenticación
        LS->>U: Mensaje de error
    end
```

### 2. Creación de Registros Offline

```mermaid
sequenceDiagram
    participant U as Usuario
    participant CS as Create Screen
    participant DS as Database Service
    participant DB as SQLite
    participant PSS as Pending Sync Service
    
    U->>CS: Completa formulario
    CS->>DS: savePendingXxxOffline(data)
    DS->>DS: Genera ID temporal negativo
    DS->>DB: INSERT con is_pending=1, pending_operation='CREATE'
    DB-->>DS: Registro guardado
    DS->>PSS: Registra operación pendiente
    DS-->>CS: Éxito con ID temporal
    CS->>U: Confirmación de guardado offline
```

### 3. Edición de Registros Offline

```mermaid
sequenceDiagram
    participant U as Usuario
    participant ES as Edit Screen
    participant DS as Database Service
    participant DB as SQLite
    participant PSS as Pending Sync Service
    
    U->>ES: Modifica datos
    ES->>DS: savePendingXxxUpdateOffline(id, data)
    DS->>DB: UPDATE con modifiedOffline=1, is_pending=1
    DS->>DB: SET pending_operation='UPDATE'
    DB-->>DS: Registro actualizado
    DS->>PSS: Registra operación pendiente
    DS-->>ES: Éxito
    ES->>U: Confirmación de edición offline
```

### 4. Consulta de Datos Offline

```mermaid
sequenceDiagram
    participant U as Usuario
    participant LS as List Screen
    participant CS as Configuration Service
    participant CNS as Connectivity Service
    participant DS as Database Service
    participant DB as SQLite
    
    U->>LS: Solicita listado
    LS->>CS: getXxxData()
    CS->>CNS: isConnected()
    CNS-->>CS: false (offline)
    CS->>DS: getXxxOffline()
    DS->>DB: SELECT * FROM xxx
    DB-->>DS: Datos locales
    DS-->>CS: Lista de registros
    CS-->>LS: Datos con indicador offline
    LS->>U: Muestra datos + banner offline
```

### 5. Sincronización Manual

```mermaid
sequenceDiagram
    participant U as Usuario
    participant PSS as Pending Sync Screen
    participant SS as Sync Service
    participant API as REST API
    participant DS as Database Service
    participant DB as SQLite
    
    U->>PSS: Click "Sincronizar cambios"
    PSS->>SS: syncPendingData()
    SS->>DS: getPendingRecords()
    DS->>DB: SELECT WHERE is_pending=1
    DB-->>DS: Registros pendientes
    DS-->>SS: Lista de operaciones pendientes
    
    loop Para cada operación pendiente
        alt CREATE operation
            SS->>API: POST /api/endpoint
            API-->>SS: Nuevo ID del servidor
            SS->>DS: markAsSynced(tempId, realId)
            DS->>DB: UPDATE con ID real, is_pending=0
        else UPDATE operation
            SS->>API: PUT /api/endpoint/id
            API-->>SS: Confirmación
            SS->>DS: markUpdateAsSynced(id)
            DS->>DB: SET is_pending=0, modifiedOffline=0
        else DELETE operation
            SS->>API: DELETE /api/endpoint/id
            API-->>SS: Confirmación
            SS->>DS: removeRecord(id)
            DS->>DB: DELETE FROM table
        end
    end
    
    SS-->>PSS: Sincronización completa
    PSS->>U: Mensaje de éxito
```

## Gestión de Estados de Conectividad

### Detección de Estado Offline

```mermaid
stateDiagram-v2
    [*] --> Checking
    Checking --> Online : Internet available + Server reachable
    Checking --> Offline : No internet OR Server unreachable
    
    Online --> Offline : Connection lost
    Offline --> Online : Connection restored
    
    Online : App uses server data
    Online : Auto-cache for offline use
    
    Offline : App uses local cache
    Offline : All operations stored locally
    Offline : Sync disabled
```

### Indicadores Visuales de Estado

1. **Banner Offline**: Se muestra en todas las pantallas cuando no hay conectividad
2. **Indicador en AppBar**: Muestra "Offline" en la barra superior
3. **Mensajes Contextuales**: Informan sobre operaciones offline
4. **Pantalla de Registros Pendientes**: Lista todas las operaciones por sincronizar

## Estrategia de Sincronización

### Principios de Sincronización

1. **Manual Only**: No hay sincronización automática
2. **Batch Operations**: Las operaciones se sincronizan en lotes
3. **Conflict Detection**: Se detectan y manejan conflictos
4. **Data Preservation**: Los datos offline nunca se pierden
5. **Atomic Operations**: Cada operación de sync es atómica

### Orden de Sincronización

```mermaid
graph TD
    A[Iniciar Sincronización] --> B[Sincronizar Configuraciones]
    B --> C[Sincronizar Fincas]
    C --> D[Sincronizar Rebaños]
    D --> E[Sincronizar Animales]
    E --> F[Sincronizar Personal]
    F --> G[Sincronizar Registros de Gestión]
    G --> H[Finalizar Sincronización]
    
    style A fill:#e8f5e8
    style H fill:#e8f5e8
    style B,C,D,E,F,G fill:#fff3cd
```

### Manejo de Errores de Sincronización

```mermaid
graph TD
    A[Operación de Sync] --> B{Error de Red?}
    B -->|Sí| C[Reintentar después]
    B -->|No| D{Error del Servidor?}
    D -->|Sí| E[Marcar como fallido]
    D -->|No| F{Conflicto de Datos?}
    F -->|Sí| G[Resolver conflicto]
    F -->|No| H[Marcar como sincronizado]
    
    C --> I[Mantener en cola]
    E --> I
    G --> I
    H --> J[Remover de cola]
    
    style A fill:#e8f5e8
    style J fill:#e8f5e8
    style I fill:#ffebee
```

## Funcionalidades Offline Soportadas

### ✅ Completamente Offline
- **Autenticación**: Login con credenciales hash locales
- **Gestión de Fincas**: CRUD completo
- **Gestión de Rebaños**: CRUD completo
- **Gestión de Animales**: CRUD completo
- **Personal de Finca**: CRUD completo
- **Cambios de Animales**: Creación y consulta
- **Peso Corporal**: Creación y consulta
- **Lactancia**: Creación y consulta
- **Registros de Leche**: Consulta de datos en cache

### ⚠️ Requiere Sincronización
- **Configuraciones del Sistema**: Actualización desde servidor
- **Datos de Nuevos Usuarios**: Registro de nuevos usuarios
- **Reportes Globales**: Análisis que requieren datos del servidor

## Beneficios de la Estrategia Offline

1. **Disponibilidad Total**: La aplicación funciona sin conexión
2. **Experiencia Fluida**: No hay interrupciones por problemas de red
3. **Productividad**: Los usuarios pueden trabajar en cualquier lugar
4. **Confiabilidad**: Los datos nunca se pierden
5. **Flexibilidad**: Sincronización cuando es conveniente para el usuario

---

*Siguiente: [Módulos y Funcionalidades](./modulos.md)*