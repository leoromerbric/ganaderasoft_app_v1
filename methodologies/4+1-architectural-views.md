# Modelo de Arquitectura 4+1 Vistas - GanaderaSoft

## Introducción

Este documento presenta la arquitectura de GanaderaSoft utilizando el modelo de arquitectura 4+1 vistas propuesto por Philippe Kruchten. Este modelo organiza la descripción de la arquitectura del software usando cinco vistas concurrentes, cada una abordando un conjunto específico de preocupaciones de los diferentes stakeholders del sistema.

## Índice
1. [Vista Lógica](#1-vista-lógica)
2. [Vista de Procesos](#2-vista-de-procesos)
3. [Vista de Desarrollo](#3-vista-de-desarrollo)
4. [Vista Física](#4-vista-física)
5. [Escenarios (Vista +1)](#5-escenarios-vista-1)

---

## 1. Vista Lógica

### Propósito
La vista lógica describe la funcionalidad que el sistema proporciona a los usuarios finales. Se enfoca en la estructura de clases, paquetes y sus relaciones.

### Diagrama de Paquetes Principales

```mermaid
graph TB
    subgraph "Capa de Presentación"
        UI[Screens/UI Components]
        THEME[Theme Configuration]
        CONST[Constants & Config]
    end
    
    subgraph "Capa de Lógica de Negocio"
        AUTH[Authentication Service]
        DB[Database Service]
        SYNC[Sync Service]
        CONFIG[Configuration Service]
        CONN[Connectivity Service]
        OFFLINE[Offline Manager]
        LOG[Logging Service]
    end
    
    subgraph "Capa de Datos"
        MODELS[Data Models]
        SQLITE[(SQLite Database)]
        PREFS[(Shared Preferences)]
    end
    
    subgraph "Servicios Externos"
        API[REST API Backend]
        NET[Network Layer]
    end
    
    UI --> AUTH
    UI --> DB
    UI --> SYNC
    UI --> CONFIG
    UI --> THEME
    UI --> CONST
    
    AUTH --> MODELS
    AUTH --> PREFS
    AUTH --> API
    
    DB --> MODELS
    DB --> SQLITE
    
    SYNC --> DB
    SYNC --> API
    SYNC --> AUTH
    
    CONFIG --> PREFS
    CONFIG --> API
    CONFIG --> DB
    
    OFFLINE --> CONN
    OFFLINE --> SYNC
    
    CONN --> NET
    
    LOG -.-> AUTH
    LOG -.-> DB
    LOG -.-> SYNC
    
    style UI fill:#e1f5fe
    style AUTH fill:#f3e5f5
    style DB fill:#e8f5e9
    style SYNC fill:#fff3e0
    style MODELS fill:#fce4ec
    style API fill:#ffebee
```

### Diagrama de Clases Principales

```mermaid
classDiagram
    class User {
        +int id
        +String name
        +String email
        +String typeUser
        +String? phone
        +toJson()
        +fromJson()
    }
    
    class Finca {
        +int idFinca
        +String nombreFinca
        +String nombrePropietario
        +String tipoExplotacion
        +String? ubicacion
        +toJson()
        +fromJson()
    }
    
    class Animal {
        +int idAnimal
        +int idRebano
        +String nombre
        +String codigoAnimal
        +String sexo
        +String fechaNacimiento
        +String procedencia
        +int fkComposicionRaza
        +int estadoId
        +int etapaId
        +toJson()
        +fromJson()
    }
    
    class Rebano {
        +int idRebano
        +int idFinca
        +String nombre
        +String proposito
        +int cantidadAnimales
        +toJson()
        +fromJson()
    }
    
    class AuthService {
        -String? _token
        -User? _currentUser
        +login(email, password)
        +logout()
        +getCurrentUser()
        +isAuthenticated()
        +getFincas()
        +getAnimales()
    }
    
    class DatabaseService {
        -Database? _database
        +database
        +savePendingAnimalOffline()
        +getAnimalesOffline()
        +markAsSynced()
        +getAllPendingRecords()
    }
    
    class SyncService {
        +syncPendingAnimals()
        +syncPendingPersonal()
        +syncAllPending()
        +getSyncStatus()
    }
    
    class ConfigurationService {
        -Map cache
        +getEstadosSalud()
        +getEtapas()
        +getComposicionRaza()
        +getTiposExplotacion()
        +refreshConfiguration()
    }
    
    Finca "1" --> "*" Rebano : contiene
    Rebano "1" --> "*" Animal : contiene
    User "1" --> "*" Finca : administra
    
    AuthService --> User : gestiona
    AuthService --> Finca : maneja
    DatabaseService --> Animal : almacena
    DatabaseService --> Rebano : almacena
    SyncService --> DatabaseService : usa
    SyncService --> AuthService : usa
```

### Módulos Funcionales

```mermaid
graph LR
    subgraph "Módulo Autenticación"
        AUTH_M[Gestión de Usuarios]
        LOGIN[Login/Logout]
        PROFILE[Perfil Usuario]
    end
    
    subgraph "Módulo Gestión Fincas"
        FINCA_M[Administración Fincas]
        OWNER[Propietarios]
    end
    
    subgraph "Módulo Gestión Ganado"
        ANIMAL_M[Gestión Animales]
        REBANO_M[Gestión Rebaños]
        RACE[Composición Racial]
    end
    
    subgraph "Módulo Personal"
        PERSONAL_M[Gestión Personal]
        WORKER[Trabajadores]
    end
    
    subgraph "Módulo Producción"
        WEIGHT[Peso Corporal]
        MILK[Registro Leche]
        LACT[Lactancia]
        CHANGES[Cambios Animal]
    end
    
    subgraph "Módulo Sincronización"
        SYNC_M[Sincronización]
        PENDING[Pendientes]
        CONFLICT[Conflictos]
    end
    
    AUTH_M --> FINCA_M
    FINCA_M --> ANIMAL_M
    FINCA_M --> PERSONAL_M
    ANIMAL_M --> REBANO_M
    ANIMAL_M --> RACE
    ANIMAL_M --> WEIGHT
    ANIMAL_M --> MILK
    ANIMAL_M --> LACT
    ANIMAL_M --> CHANGES
    
    SYNC_M --> FINCA_M
    SYNC_M --> ANIMAL_M
    SYNC_M --> PERSONAL_M
    SYNC_M --> PENDING
    
    style AUTH_M fill:#e3f2fd
    style FINCA_M fill:#f3e5f5
    style ANIMAL_M fill:#e8f5e9
    style PERSONAL_M fill:#fff3e0
    style SYNC_M fill:#e0f2f1
```

---

## 2. Vista de Procesos

### Propósito
La vista de procesos aborda los aspectos dinámicos del sistema, incluyendo los procesos y threads, su comunicación e sincronización.

### Flujo de Autenticación Online/Offline

```mermaid
sequenceDiagram
    participant U as Usuario
    participant UI as Login Screen
    participant AS as Auth Service
    participant API as REST API
    participant DB as Database Service
    participant SP as Shared Preferences
    
    U->>UI: Ingresa credenciales
    UI->>AS: login(email, password)
    
    alt Modo Online
        AS->>API: POST /login
        alt Autenticación Exitosa
            API-->>AS: {token, user}
            AS->>SP: Guardar token
            AS->>DB: Guardar usuario offline
            AS->>DB: Guardar hash contraseña
            AS-->>UI: Usuario autenticado
            UI-->>U: Navegar a Home
        else Credenciales Inválidas
            API-->>AS: Error 401
            AS-->>UI: Credenciales incorrectas
            UI-->>U: Mostrar error
        end
    else Modo Offline
        AS->>DB: Buscar usuario local
        AS->>DB: Verificar hash contraseña
        alt Credenciales Válidas
            DB-->>AS: Usuario encontrado
            AS-->>UI: Usuario autenticado offline
            UI-->>U: Navegar a Home (modo offline)
        else Credenciales Inválidas
            DB-->>AS: Usuario no encontrado
            AS-->>UI: Credenciales incorrectas
            UI-->>U: Mostrar error
        end
    end
```

### Flujo de Creación de Animal Offline

```mermaid
sequenceDiagram
    participant U as Usuario
    participant UI as Create Animal Screen
    participant AS as Auth Service
    participant DB as Database Service
    participant PS as Pending Sync
    
    U->>UI: Completa formulario animal
    U->>UI: Presiona "Guardar"
    UI->>UI: Validar datos
    
    alt Datos Válidos
        UI->>DB: savePendingAnimalOffline()
        DB->>DB: Generar ID temporal negativo
        DB->>DB: INSERT INTO animales
        DB->>DB: SET is_pending=1
        DB->>DB: SET pending_operation='CREATE'
        DB->>PS: Registrar operación pendiente
        DB-->>UI: Retorna ID temporal
        UI-->>U: "Animal guardado offline"
        UI-->>U: Mostrar badge de sincronización
    else Datos Inválidos
        UI-->>U: Mostrar errores de validación
    end
```

### Proceso de Sincronización

```mermaid
sequenceDiagram
    participant U as Usuario
    participant UI as Sync Screen
    participant SS as Sync Service
    participant DB as Database Service
    participant API as REST API
    participant CONN as Connectivity Service
    
    U->>UI: Presiona "Sincronizar"
    UI->>CONN: Verificar conectividad
    
    alt Sin Conexión
        CONN-->>UI: No hay conexión
        UI-->>U: "Sin conexión a internet"
    else Con Conexión
        CONN-->>UI: Conectado
        UI->>SS: syncAllPending()
        SS->>DB: getAllPendingRecords()
        DB-->>SS: Lista de registros pendientes
        
        loop Para cada registro pendiente
            alt Operación CREATE
                SS->>API: POST /resource
                alt Éxito
                    API-->>SS: {id_real}
                    SS->>DB: markAsSynced(temp_id, real_id)
                    SS->>DB: UPDATE is_pending=0
                    SS-->>UI: Progreso actualizado
                else Error
                    API-->>SS: Error
                    SS->>DB: Mantener como pendiente
                    SS-->>UI: Error en sincronización
                end
            else Operación UPDATE
                SS->>API: PUT /resource/:id
                alt Éxito
                    API-->>SS: Success
                    SS->>DB: markAsSynced(id)
                    SS-->>UI: Progreso actualizado
                else Error
                    API-->>SS: Error
                    SS-->>UI: Error en sincronización
                end
            else Operación DELETE
                SS->>API: DELETE /resource/:id
                alt Éxito
                    API-->>SS: Success
                    SS->>DB: Eliminar registro local
                    SS-->>UI: Progreso actualizado
                else Error
                    API-->>SS: Error
                    SS-->>UI: Error en sincronización
                end
            end
        end
        
        SS-->>UI: Sincronización completa
        UI-->>U: "Sincronización finalizada"
    end
```

### Proceso de Monitoreo de Conectividad

```mermaid
stateDiagram-v2
    [*] --> Monitoring: Iniciar App
    
    Monitoring --> Online: Conexión detectada
    Monitoring --> Offline: Sin conexión
    
    Online --> CheckingServer: Verificar servidor
    CheckingServer --> ServerOnline: Servidor accesible
    CheckingServer --> ServerOffline: Servidor no accesible
    
    ServerOnline --> Operating: Modo Online
    ServerOffline --> Operating: Modo Offline (servidor down)
    Offline --> Operating: Modo Offline (red down)
    
    Operating --> Monitoring: Cambio conectividad
    
    state Operating {
        [*] --> ReadingData
        ReadingData --> WritingData
        WritingData --> SyncingData: Si online
        WritingData --> QueuingChanges: Si offline
        SyncingData --> ReadingData
        QueuingChanges --> ReadingData
    }
    
    note right of ServerOnline
        Todas las operaciones
        con servidor
    end note
    
    note right of ServerOffline
        Operaciones locales
        + sincronización pendiente
    end note
    
    note right of Offline
        Solo operaciones locales
        + sincronización pendiente
    end note
```

### Concurrencia y Threads

```mermaid
graph TB
    subgraph "Main Thread"
        UI[UI Rendering]
        EVENTS[Event Handling]
    end
    
    subgraph "Background Threads"
        DB_OPS[Database Operations]
        NETWORK[Network Requests]
        SYNC_OPS[Sync Operations]
        FILE_OPS[File Operations]
    end
    
    subgraph "Monitoring Thread"
        CONN_MON[Connectivity Monitor]
        AUTO_SYNC[Auto Sync Trigger]
    end
    
    UI -.-> DB_OPS: Future/async
    UI -.-> NETWORK: Future/async
    EVENTS -.-> SYNC_OPS: Future/async
    
    CONN_MON --> AUTO_SYNC
    AUTO_SYNC -.-> SYNC_OPS
    
    DB_OPS -.-> UI: Callbacks
    NETWORK -.-> UI: Callbacks
    SYNC_OPS -.-> UI: Callbacks
    
    style UI fill:#e1f5fe
    style DB_OPS fill:#e8f5e9
    style NETWORK fill:#fff3e0
    style CONN_MON fill:#f3e5f5
```

---

## 3. Vista de Desarrollo

### Propósito
La vista de desarrollo describe la organización estática del software en su entorno de desarrollo, incluyendo la estructura de módulos, librerías y componentes.

### Estructura de Directorios

```mermaid
graph TB
    ROOT[ganaderasoft_app_v1/]
    
    ROOT --> LIB[lib/]
    ROOT --> TEST[test/]
    ROOT --> DOCS[docs/]
    ROOT --> METHOD[methodologies/]
    ROOT --> ASSETS[assets/]
    ROOT --> PLATFORM[Platforms]
    
    LIB --> CONFIG[config/]
    LIB --> CONSTANTS[constants/]
    LIB --> MODELS[models/]
    LIB --> SCREENS[screens/]
    LIB --> SERVICES[services/]
    LIB --> THEME[theme/]
    LIB --> MAIN[main.dart]
    
    MODELS --> USER_M[user.dart]
    MODELS --> FINCA_M[finca.dart]
    MODELS --> ANIMAL_M[animal.dart]
    MODELS --> CONFIG_M[configuration_models.dart]
    MODELS --> FARM_M[farm_management_models.dart]
    MODELS --> PENDING_M[pending_sync_models.dart]
    
    SERVICES --> AUTH_S[auth_service.dart]
    SERVICES --> DB_S[database_service.dart]
    SERVICES --> SYNC_S[sync_service.dart]
    SERVICES --> CONFIG_S[configuration_service.dart]
    SERVICES --> CONN_S[connectivity_service.dart]
    SERVICES --> OFFLINE_S[offline_manager.dart]
    SERVICES --> LOG_S[logging_service.dart]
    
    SCREENS --> LOGIN_SC[login_screen.dart]
    SCREENS --> HOME_SC[home_screen.dart]
    SCREENS --> FINCA_SC[finca_*_screen.dart]
    SCREENS --> ANIMAL_SC[animales_*_screen.dart]
    SCREENS --> PERSONAL_SC[personal_*_screen.dart]
    SCREENS --> PROD_SC[production_*_screen.dart]
    SCREENS --> SYNC_SC[sync_screen.dart]
    
    PLATFORM --> ANDROID[android/]
    PLATFORM --> IOS[ios/]
    PLATFORM --> WEB[web/]
    PLATFORM --> LINUX[linux/]
    PLATFORM --> MACOS[macos/]
    PLATFORM --> WINDOWS[windows/]
    
    style LIB fill:#e1f5fe
    style MODELS fill:#e8f5e9
    style SERVICES fill:#fff3e0
    style SCREENS fill:#f3e5f5
```

### Diagrama de Componentes

```mermaid
graph TB
    subgraph "Application Layer"
        MAIN[Main Application]
        SPLASH[Splash Screen]
        ROUTER[Navigation Router]
    end
    
    subgraph "UI Components"
        SCREENS_C[Screen Components]
        WIDGETS[Custom Widgets]
        FORMS[Form Components]
        LISTS[List Components]
    end
    
    subgraph "Business Logic Layer"
        AUTH_C[Authentication Component]
        DATA_C[Data Management Component]
        SYNC_C[Synchronization Component]
        CONFIG_C[Configuration Component]
    end
    
    subgraph "Data Access Layer"
        DB_C[Database Access Component]
        API_C[API Client Component]
        CACHE_C[Cache Component]
    end
    
    subgraph "Infrastructure Layer"
        CONN_C[Connectivity Component]
        STORAGE_C[Storage Component]
        LOG_C[Logging Component]
        SECURITY_C[Security Component]
    end
    
    MAIN --> SPLASH
    SPLASH --> ROUTER
    ROUTER --> SCREENS_C
    
    SCREENS_C --> WIDGETS
    SCREENS_C --> FORMS
    SCREENS_C --> LISTS
    
    SCREENS_C --> AUTH_C
    SCREENS_C --> DATA_C
    SCREENS_C --> SYNC_C
    SCREENS_C --> CONFIG_C
    
    AUTH_C --> API_C
    AUTH_C --> DB_C
    AUTH_C --> STORAGE_C
    AUTH_C --> SECURITY_C
    
    DATA_C --> DB_C
    DATA_C --> API_C
    DATA_C --> CACHE_C
    
    SYNC_C --> DB_C
    SYNC_C --> API_C
    SYNC_C --> CONN_C
    
    CONFIG_C --> CACHE_C
    CONFIG_C --> API_C
    CONFIG_C --> STORAGE_C
    
    DB_C --> STORAGE_C
    API_C --> CONN_C
    
    LOG_C -.-> AUTH_C
    LOG_C -.-> DATA_C
    LOG_C -.-> SYNC_C
    
    style MAIN fill:#e3f2fd
    style SCREENS_C fill:#f3e5f5
    style AUTH_C fill:#e8f5e9
    style DB_C fill:#fff3e0
```

### Capas y Dependencias

```mermaid
graph TB
    subgraph "Presentation Layer"
        SCREENS[Screens & UI]
        THEME_L[Theming]
    end
    
    subgraph "Application Layer"
        USE_CASES[Use Cases / Business Rules]
    end
    
    subgraph "Domain Layer"
        ENTITIES[Domain Entities]
        REPOSITORIES[Repository Interfaces]
    end
    
    subgraph "Infrastructure Layer"
        REPO_IMPL[Repository Implementations]
        DB_IMPL[Database Implementation]
        API_IMPL[API Implementation]
    end
    
    subgraph "Cross-Cutting Concerns"
        LOGGING[Logging]
        SECURITY[Security]
        CONFIG_CC[Configuration]
    end
    
    SCREENS --> USE_CASES
    USE_CASES --> REPOSITORIES
    REPOSITORIES --> REPO_IMPL
    REPO_IMPL --> DB_IMPL
    REPO_IMPL --> API_IMPL
    
    USE_CASES --> ENTITIES
    REPO_IMPL --> ENTITIES
    
    LOGGING -.-> SCREENS
    LOGGING -.-> USE_CASES
    LOGGING -.-> REPO_IMPL
    
    SECURITY -.-> USE_CASES
    SECURITY -.-> REPO_IMPL
    
    CONFIG_CC -.-> SCREENS
    CONFIG_CC -.-> USE_CASES
    
    style SCREENS fill:#e1f5fe
    style USE_CASES fill:#f3e5f5
    style ENTITIES fill:#e8f5e9
    style REPO_IMPL fill:#fff3e0
```

### Gestión de Dependencias

```yaml
# pubspec.yaml - Dependencias principales
dependencies:
  flutter: sdk
  
  # State Management
  provider: ^6.0.5
  
  # Networking
  http: ^1.1.0
  connectivity_plus: ^5.0.2
  
  # Local Storage
  sqflite: ^2.3.0
  shared_preferences: ^2.2.2
  path: ^1.8.3
  
  # Security
  crypto: ^3.0.3

dev_dependencies:
  flutter_test: sdk
  flutter_lints: ^6.0.0
  sqflite_common_ffi: ^2.3.0
  flutter_launcher_icons: ^0.13.1
```

---

## 4. Vista Física

### Propósito
La vista física describe el mapeo del software en el hardware y refleja los aspectos distribuidos del sistema.

### Topología de Despliegue

```mermaid
graph TB
    subgraph "Client Devices"
        subgraph "Android Devices"
            ANDROID_PHONE[Android Phone]
            ANDROID_TABLET[Android Tablet]
        end
        
        subgraph "iOS Devices"
            IPHONE[iPhone]
            IPAD[iPad]
        end
        
        subgraph "Desktop"
            WINDOWS[Windows PC]
            MACOS[macOS]
            LINUX[Linux Desktop]
        end
        
        subgraph "Web"
            BROWSER[Web Browser]
        end
    end
    
    subgraph "Local Storage Layer"
        SQLITE_LOCAL[(SQLite Database)]
        SHARED_PREFS[(Shared Preferences)]
        FILE_SYSTEM[(File System)]
    end
    
    subgraph "Network Layer"
        MOBILE_NET[Mobile Network<br/>4G/5G]
        WIFI[WiFi Network]
        ETHERNET[Ethernet]
    end
    
    subgraph "Backend Infrastructure"
        subgraph "Application Server"
            API_SERVER[REST API Server<br/>Node.js/Express]
            AUTH_SERVER[Authentication Service]
        end
        
        subgraph "Database Server"
            POSTGRES[(PostgreSQL Database)]
            REDIS[(Redis Cache)]
        end
        
        subgraph "File Storage"
            FILE_SERVER[File Storage Service]
        end
    end
    
    ANDROID_PHONE --> SQLITE_LOCAL
    ANDROID_TABLET --> SQLITE_LOCAL
    IPHONE --> SQLITE_LOCAL
    IPAD --> SQLITE_LOCAL
    WINDOWS --> SQLITE_LOCAL
    MACOS --> SQLITE_LOCAL
    LINUX --> SQLITE_LOCAL
    BROWSER --> SQLITE_LOCAL
    
    ANDROID_PHONE --> SHARED_PREFS
    ANDROID_TABLET --> SHARED_PREFS
    IPHONE --> SHARED_PREFS
    IPAD --> SHARED_PREFS
    
    ANDROID_PHONE --> MOBILE_NET
    ANDROID_TABLET --> MOBILE_NET
    IPHONE --> MOBILE_NET
    IPAD --> MOBILE_NET
    WINDOWS --> ETHERNET
    MACOS --> WIFI
    LINUX --> ETHERNET
    BROWSER --> WIFI
    
    MOBILE_NET --> API_SERVER
    WIFI --> API_SERVER
    ETHERNET --> API_SERVER
    
    API_SERVER --> POSTGRES
    API_SERVER --> REDIS
    API_SERVER --> FILE_SERVER
    API_SERVER --> AUTH_SERVER
    
    style ANDROID_PHONE fill:#a5d6a7
    style IPHONE fill:#90caf9
    style WINDOWS fill:#ffcc80
    style API_SERVER fill:#ef9a9a
    style POSTGRES fill:#ce93d8
```

### Arquitectura de Despliegue Detallada

```mermaid
graph TB
    subgraph "Mobile/Desktop Client"
        APP[GanaderaSoft App]
        LOCAL_DB[(Local SQLite)]
        LOCAL_CACHE[Local Cache]
    end
    
    subgraph "Network Infrastructure"
        INTERNET[Internet]
        FIREWALL[Firewall]
        LOAD_BALANCER[Load Balancer]
    end
    
    subgraph "Application Tier"
        API_1[API Server 1]
        API_2[API Server 2]
        API_N[API Server N]
    end
    
    subgraph "Data Tier"
        DB_PRIMARY[(Primary Database)]
        DB_REPLICA[(Read Replica)]
        CACHE_CLUSTER[(Cache Cluster)]
    end
    
    subgraph "Storage Tier"
        OBJECT_STORAGE[Object Storage<br/>Images/Files]
    end
    
    APP --> LOCAL_DB
    APP --> LOCAL_CACHE
    APP --> INTERNET
    
    INTERNET --> FIREWALL
    FIREWALL --> LOAD_BALANCER
    
    LOAD_BALANCER --> API_1
    LOAD_BALANCER --> API_2
    LOAD_BALANCER --> API_N
    
    API_1 --> DB_PRIMARY
    API_2 --> DB_PRIMARY
    API_N --> DB_PRIMARY
    
    API_1 --> DB_REPLICA
    API_2 --> DB_REPLICA
    API_N --> DB_REPLICA
    
    API_1 --> CACHE_CLUSTER
    API_2 --> CACHE_CLUSTER
    API_N --> CACHE_CLUSTER
    
    API_1 --> OBJECT_STORAGE
    API_2 --> OBJECT_STORAGE
    API_N --> OBJECT_STORAGE
    
    DB_PRIMARY -.Replication.-> DB_REPLICA
    
    style APP fill:#81c784
    style LOCAL_DB fill:#fff59d
    style API_1 fill:#ef9a9a
    style DB_PRIMARY fill:#ce93d8
```

### Flujo de Comunicación

```mermaid
sequenceDiagram
    participant Client as Mobile/Desktop Client
    participant LocalDB as Local SQLite
    participant Network as Network Layer
    participant LB as Load Balancer
    participant API as API Server
    participant Cache as Redis Cache
    participant DB as PostgreSQL DB
    
    Note over Client,LocalDB: Operación Offline
    Client->>LocalDB: Query/Write Data
    LocalDB-->>Client: Return Local Data
    
    Note over Client,DB: Operación Online
    Client->>Network: HTTP Request
    Network->>LB: Forward Request
    LB->>API: Route to Server
    
    alt Cache Hit
        API->>Cache: Check Cache
        Cache-->>API: Return Cached Data
        API-->>Client: Response (cached)
    else Cache Miss
        API->>Cache: Check Cache
        Cache-->>API: Cache Miss
        API->>DB: Query Database
        DB-->>API: Return Data
        API->>Cache: Update Cache
        API-->>Client: Response (from DB)
    end
    
    Note over Client,LocalDB: Update Local Cache
    Client->>LocalDB: Update Local Data
```

### Distribución Geográfica

```mermaid
graph TB
    subgraph "Region: América Latina"
        subgraph "Colombia"
            USERS_CO[Usuarios Colombia]
            LOCAL_DB_CO[(Local SQLite)]
        end
        
        subgraph "Venezuela"
            USERS_VE[Usuarios Venezuela]
            LOCAL_DB_VE[(Local SQLite)]
        end
        
        subgraph "Ecuador"
            USERS_EC[Usuarios Ecuador]
            LOCAL_DB_EC[(Local SQLite)]
        end
    end
    
    subgraph "Cloud Infrastructure"
        CDN[Content Delivery Network]
        
        subgraph "Primary Region"
            API_PRIMARY[API Server<br/>Primary]
            DB_PRIMARY[(Database Primary)]
        end
        
        subgraph "Backup Region"
            API_BACKUP[API Server<br/>Backup]
            DB_BACKUP[(Database Backup)]
        end
    end
    
    USERS_CO --> LOCAL_DB_CO
    USERS_VE --> LOCAL_DB_VE
    USERS_EC --> LOCAL_DB_EC
    
    USERS_CO --> CDN
    USERS_VE --> CDN
    USERS_EC --> CDN
    
    CDN --> API_PRIMARY
    CDN --> API_BACKUP
    
    API_PRIMARY --> DB_PRIMARY
    API_BACKUP --> DB_BACKUP
    
    DB_PRIMARY -.Sync.-> DB_BACKUP
    
    style USERS_CO fill:#c5e1a5
    style USERS_VE fill:#fff59d
    style USERS_EC fill:#ffcc80
    style API_PRIMARY fill:#ef9a9a
```

---

## 5. Escenarios (Vista +1)

### Propósito
Los escenarios ilustran la arquitectura con casos de uso importantes y sirven como validación de las otras cuatro vistas.

### Escenario 1: Autenticación y Primer Acceso

**Descripción**: Usuario se autentica por primera vez en la aplicación y configura su perfil.

```mermaid
sequenceDiagram
    actor User as Usuario
    participant App as Aplicación
    participant Auth as Auth Service
    participant API as Backend API
    participant LocalDB as SQLite Local
    participant Cache as Local Cache
    
    User->>App: Abre aplicación
    App->>App: Muestra SplashScreen
    App->>Cache: Verificar sesión guardada
    Cache-->>App: No hay sesión
    App->>User: Mostrar LoginScreen
    
    User->>App: Ingresa email y password
    App->>Auth: login(email, password)
    Auth->>API: POST /api/login
    API-->>Auth: {token, user, fincas}
    
    Auth->>Cache: Guardar token
    Auth->>LocalDB: Guardar usuario
    Auth->>LocalDB: Guardar hash password
    Auth->>LocalDB: Guardar fincas
    
    Auth-->>App: Usuario autenticado
    App->>App: Navegar a HomeScreen
    App->>User: Mostrar dashboard
    
    App->>API: Obtener configuraciones
    API-->>App: Datos configuración
    App->>LocalDB: Cache configuraciones
    
    Note over User,LocalDB: Usuario listo para trabajar<br/>online y offline
```

**Componentes Involucrados**:
- Vista Lógica: AuthService, DatabaseService, ConfigurationService
- Vista de Procesos: Thread principal (UI), threads background (API calls)
- Vista de Desarrollo: lib/services/auth_service.dart, lib/screens/login_screen.dart
- Vista Física: Dispositivo móvil, servidor API, base de datos

### Escenario 2: Creación de Animal en Modo Offline

**Descripción**: Usuario crea un nuevo animal sin conexión a internet.

```mermaid
sequenceDiagram
    actor User as Usuario
    participant App as Aplicación
    participant UI as Create Animal Screen
    participant Conn as Connectivity Service
    participant DB as Database Service
    participant Pending as Pending Sync
    
    User->>App: Selecciona "Crear Animal"
    App->>Conn: Verificar conectividad
    Conn-->>App: Offline
    App->>UI: Mostrar formulario<br/>(banner offline visible)
    
    User->>UI: Completa formulario
    User->>UI: Selecciona "Guardar"
    
    UI->>UI: Validar datos
    alt Datos válidos
        UI->>DB: savePendingAnimalOffline()
        DB->>DB: Generar ID temporal (-1)
        DB->>DB: INSERT animal with is_pending=1
        DB->>Pending: Crear registro pendiente
        DB-->>UI: Animal guardado (ID: -1)
        UI->>User: "Animal guardado offline"<br/>Mostrar badge pendiente
        UI->>App: Navegar a lista
    else Datos inválidos
        UI->>User: Mostrar errores
    end
    
    Note over User,Pending: Animal queda pendiente<br/>de sincronización
```

**Componentes Involucrados**:
- Vista Lógica: DatabaseService, Animal Model, PendingSyncModels
- Vista de Procesos: Operaciones locales, sin comunicación con servidor
- Vista de Desarrollo: lib/screens/create_animal_screen.dart, lib/services/database_service.dart
- Vista Física: Solo dispositivo local y SQLite local

### Escenario 3: Sincronización de Cambios Pendientes

**Descripción**: Usuario sincroniza cambios realizados offline cuando recupera conectividad.

```mermaid
sequenceDiagram
    actor User as Usuario
    participant App as Aplicación
    participant Sync as Sync Screen
    participant SyncSvc as Sync Service
    participant DB as Database Service
    participant API as Backend API
    participant Conn as Connectivity Service
    
    App->>Conn: Monitorear conectividad
    Conn-->>App: Conexión restaurada
    App->>User: Notificación "Conexión disponible"
    
    User->>App: Navega a "Sincronización"
    App->>Sync: Mostrar pantalla
    Sync->>DB: getPendingRecordsCount()
    DB-->>Sync: 5 registros pendientes
    Sync->>User: "Tienes 5 cambios pendientes"
    
    User->>Sync: Presiona "Sincronizar Todo"
    Sync->>SyncSvc: syncAllPending()
    
    SyncSvc->>DB: getAllPendingRecords()
    DB-->>SyncSvc: [Animal(-1), Personal(-2), ...]
    
    loop Para cada registro
        SyncSvc->>API: POST /api/animales
        alt Éxito
            API-->>SyncSvc: {id_animal: 123}
            SyncSvc->>DB: markAsSynced(-1, 123)
            SyncSvc->>Sync: Actualizar progreso (1/5)
        else Error
            API-->>SyncSvc: Error 500
            SyncSvc->>DB: Mantener como pendiente
            SyncSvc->>Sync: Marcar con error
        end
    end
    
    SyncSvc-->>Sync: Sincronización completa
    Sync->>User: "4 de 5 sincronizados"<br/>"1 con error"
    
    Note over User,API: Datos sincronizados<br/>IDs temporales reemplazados
```

**Componentes Involucrados**:
- Vista Lógica: SyncService, DatabaseService, AuthService
- Vista de Procesos: Sincronización asíncrona, múltiples requests concurrentes
- Vista de Desarrollo: lib/services/sync_service.dart, lib/screens/sync_screen.dart
- Vista Física: Dispositivo cliente, red, servidor API, base de datos remota

### Escenario 4: Consulta de Registros de Producción

**Descripción**: Usuario consulta registros de producción lechera de un animal específico.

```mermaid
sequenceDiagram
    actor User as Usuario
    participant App as Aplicación
    participant List as Lista Registros Screen
    participant DB as Database Service
    participant API as Backend API
    participant Conn as Connectivity Service
    
    User->>App: Selecciona animal
    User->>App: "Ver registros leche"
    App->>List: Mostrar pantalla
    
    List->>Conn: Verificar conectividad
    
    alt Modo Online
        Conn-->>List: Online
        List->>API: GET /api/registros-leche?animal_id=123
        API-->>List: [Registro1, Registro2, ...]
        List->>DB: Actualizar cache local
        List->>User: Mostrar registros (online)
    else Modo Offline
        Conn-->>List: Offline
        List->>DB: getRegistrosLecheOffline(123)
        DB-->>List: [Registro1_cached, ...]
        List->>User: Mostrar registros (offline)<br/>Banner "Datos en cache"
    end
    
    User->>List: Aplicar filtro por fecha
    List->>List: Filtrar datos localmente
    List->>User: Mostrar registros filtrados
    
    User->>List: Exportar a PDF
    List->>List: Generar PDF localmente
    List->>User: Guardar/compartir PDF
```

**Componentes Involucrados**:
- Vista Lógica: DatabaseService, ConfigurationService, Farm Management Models
- Vista de Procesos: Consultas asíncronas, operaciones de filtrado
- Vista de Desarrollo: lib/screens/registros_leche_list_screen.dart
- Vista Física: Dispositivo local o red según disponibilidad

### Escenario 5: Gestión de Conflictos en Sincronización

**Descripción**: Manejo de conflictos cuando el mismo registro fue modificado offline y online.

```mermaid
sequenceDiagram
    actor User as Usuario
    participant App as Aplicación
    participant Sync as Sync Service
    participant DB as Database Service
    participant API as Backend API
    
    Note over User,API: Usuario modificó Animal ID=50<br/>offline (cambió nombre a "Vaca Clara")
    
    User->>App: Iniciar sincronización
    App->>Sync: syncPendingAnimals()
    
    Sync->>DB: getPendingAnimals()
    DB-->>Sync: [Animal(50, nombre="Vaca Clara")]
    
    Sync->>API: PUT /api/animales/50
    Sync->>API: {nombre: "Vaca Clara", ...}
    
    alt Sin conflicto
        API-->>Sync: Success (200)
        Sync->>DB: markAsSynced(50)
        Sync->>App: Sincronizado exitosamente
    else Conflicto detectado
        API-->>Sync: Conflict (409)<br/>{server_version, conflicts}
        
        Sync->>App: Mostrar diálogo conflicto
        App->>User: "Conflicto detectado"<br/>"Local: Vaca Clara"<br/>"Servidor: Vaca María"
        
        alt Usuario elige versión local
            User->>App: Selecciona "Mantener local"
            App->>Sync: Resolver con versión local
            Sync->>API: PUT /api/animales/50 (force)
            API-->>Sync: Success
            Sync->>DB: markAsSynced(50)
        else Usuario elige versión servidor
            User->>App: Selecciona "Usar servidor"
            App->>Sync: Descartar cambios locales
            Sync->>API: GET /api/animales/50
            API-->>Sync: Versión servidor
            Sync->>DB: UPDATE con versión servidor
            Sync->>DB: markAsSynced(50)
        else Usuario quiere fusionar
            User->>App: Selecciona "Editar"
            App->>User: Mostrar editor con ambas versiones
            User->>App: Edita y guarda
            App->>Sync: Enviar versión fusionada
            Sync->>API: PUT /api/animales/50
            API-->>Sync: Success
            Sync->>DB: markAsSynced(50)
        end
    end
```

**Componentes Involucrados**:
- Vista Lógica: SyncService, DatabaseService, PendingSyncModels
- Vista de Procesos: Resolución de conflictos, transacciones
- Vista de Desarrollo: lib/services/sync_service.dart, resolución de conflictos en UI
- Vista Física: Comunicación bidireccional cliente-servidor

### Escenario 6: Trabajo Multi-Finca

**Descripción**: Usuario gestiona múltiples fincas y cambia entre ellas.

```mermaid
sequenceDiagram
    actor User as Usuario
    participant App as Aplicación
    participant Home as Home Screen
    participant FincaList as Finca List Screen
    participant DB as Database Service
    participant Auth as Auth Service
    participant API as Backend API
    
    User->>App: Login exitoso
    Auth->>DB: getFincasOffline(user_id)
    DB-->>Auth: [Finca1, Finca2, Finca3]
    Auth-->>App: Usuario con 3 fincas
    
    App->>Home: Mostrar home
    Home->>User: Mostrar selector fincas
    
    User->>Home: Selecciona "Finca Don Pedro"
    Home->>App: setCurrentFinca(finca_id=1)
    App->>DB: Cargar datos de finca 1
    DB-->>App: Datos cargados
    App->>Home: Actualizar contexto
    Home->>User: Dashboard Finca Don Pedro
    
    User->>Home: "Ver animales"
    App->>DB: getAnimalesOffline(finca_id=1)
    DB-->>App: 50 animales
    App->>User: Mostrar lista
    
    Note over User,DB: Usuario trabaja en Finca 1
    
    User->>Home: Cambiar a "Finca La Esperanza"
    Home->>App: setCurrentFinca(finca_id=2)
    App->>DB: Limpiar cache finca anterior
    App->>DB: Cargar datos finca 2
    
    alt Datos en cache local
        DB-->>App: Datos finca 2 (offline)
        App->>User: Dashboard Finca La Esperanza
    else Necesita datos del servidor
        App->>API: GET /api/fincas/2/dashboard
        API-->>App: Datos completos
        App->>DB: Actualizar cache
        App->>User: Dashboard actualizado
    end
```

**Componentes Involucrados**:
- Vista Lógica: AuthService, DatabaseService, Finca Model
- Vista de Procesos: Cambio de contexto, gestión de cache
- Vista de Desarrollo: lib/screens/home_screen.dart, lib/screens/finca_list_screen.dart
- Vista Física: Datos distribuidos entre múltiples contextos de finca

---

## Resumen de Relaciones entre Vistas

| Vista | Enfoque Principal | Stakeholders |
|-------|------------------|-------------|
| **Lógica** | Funcionalidad y estructura de clases | Usuarios finales, analistas |
| **Procesos** | Concurrencia, rendimiento, escalabilidad | Integradores, testers de rendimiento |
| **Desarrollo** | Organización del código y módulos | Desarrolladores, gestores de configuración |
| **Física** | Topología de hardware y red | Arquitectos de sistemas, administradores de sistemas |
| **Escenarios** | Casos de uso y validación | Todos los stakeholders |

## Conclusiones

El modelo 4+1 vistas proporciona una descripción comprehensiva de la arquitectura de GanaderaSoft:

1. **Vista Lógica**: Muestra una arquitectura en capas clara con separación de responsabilidades entre UI, lógica de negocio y datos.

2. **Vista de Procesos**: Demuestra el manejo robusto de operaciones asíncronas y sincronización offline/online.

3. **Vista de Desarrollo**: Presenta una organización modular del código que facilita el mantenimiento y escalabilidad.

4. **Vista Física**: Ilustra una arquitectura distribuida con soporte para múltiples plataformas y operación offline-first.

5. **Escenarios**: Validan que la arquitectura soporta todos los casos de uso críticos del sistema, especialmente el trabajo en modo offline.

Esta arquitectura garantiza:
- ✅ **Robustez**: Funciona offline y online sin pérdida de funcionalidad
- ✅ **Escalabilidad**: Soporta múltiples dispositivos y plataformas
- ✅ **Mantenibilidad**: Código organizado y modular
- ✅ **Rendimiento**: Operaciones locales rápidas con sincronización eficiente
- ✅ **Usabilidad**: Experiencia consistente independiente de conectividad

---

*Documento creado como parte de la documentación metodológica de GanaderaSoft*
*Fecha: Octubre 2025*
