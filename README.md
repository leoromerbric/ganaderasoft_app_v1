# 📱 GanaderaSoft App

**Sistema de gestión integral para fincas ganaderas** - Aplicación móvil para Android con funcionalidad offline completa.

## 📋 Descripción

GanaderaSoft es una aplicación Flutter para la gestión de fincas ganaderas que permite administrar animales, registrar datos productivos, gestionar rebaños y personal desde dispositivos móviles, con capacidad de funcionamiento offline y sincronización manual.

### Características Principales

- ✅ **Gestión de Animales**: Registro, edición y seguimiento de ganado
- ✅ **Registros Productivos**: Producción de leche, peso corporal, lactancia
- ✅ **Gestión de Rebaños**: Organización y administración de grupos
- ✅ **Personal de Finca**: Control de empleados y sus roles
- ✅ **Funcionamiento Offline**: Trabajo sin conexión a internet
- ✅ **Sincronización Manual**: Control total sobre cuándo enviar datos
- ✅ **Autenticación Segura**: Sistema de login con JWT
- ✅ **Filtros y Búsquedas**: Localización rápida de información

---

## 📁 Estructura del Proyecto

```
ganaderasoft_app_v1/
├── android/              # Configuración específica de Android
├── assets/               # Recursos de la aplicación (iconos, imágenes)
├── ios/                  # Configuración específica de iOS
├── lib/                  # Código fuente principal de la aplicación
├── test/                 # Tests unitarios e integración
├── .gitignore           # Archivos excluidos del control de versiones
├── analysis_options.yaml # Configuración de análisis estático Dart
├── pubspec.yaml         # Dependencias y configuración del proyecto
└── README.md            # Este archivo
```

---

## 📂 Directorio lib/ (Código Principal)

### `/lib/main.dart`
**Propósito**: Punto de entrada de la aplicación Flutter.

### `/lib/config/`
**Propósito**: Archivos de configuración de la aplicación.
- Configuraciones del servidor API
- Parámetros de conexión
- Variables de entorno

### `/lib/constants/`
**Propósito**: Constantes utilizadas a lo largo de la aplicación.
- URLs de API
- Valores por defecto
- Claves de configuración

### `/lib/services/`
**Propósito**: Servicios de negocio y lógica de datos.
- `auth_service.dart` - Autenticación y manejo de sesiones
- `database_service.dart` - Gestión de base de datos local (SQLite)
- `connectivity_service.dart` - Monitoreo de conexión a internet
- `sync_service.dart` - Sincronización de datos con servidor
- `offline_manager.dart` - Gestión de operaciones offline
- `configuration_service.dart` - Carga de configuraciones del sistema
- `logging_service.dart` - Registro de eventos y errores

### `/lib/models/`
**Propósito**: Modelos de datos de la aplicación.
- Definición de estructuras de datos
- Clases para representar entidades (Animal, Finca, Rebaño, etc.)
- Métodos de serialización JSON

### `/lib/screens/`
**Propósito**: Pantallas/páginas de la interfaz de usuario.

#### Pantallas Principales:
- `login_screen.dart` - Autenticación de usuarios
- `home_screen.dart` - Menú principal de la aplicación
- `finca_list_screen.dart` - Lista de fincas del usuario
- `finca_administracion_screen.dart` - Gestión de una finca específica

#### Gestión de Animales:
- `animales_list_screen.dart` - Lista de animales
- `create_animal_screen.dart` - Registro de nuevos animales
- `edit_animal_screen.dart` - Edición de animales existentes
- `cambios_animal_list_screen.dart` - Historial de cambios en animales

#### Registros Productivos:
- `registros_leche_list_screen.dart` - Registros de producción láctea
- `create_registro_leche_screen.dart` - Nuevo registro de leche
- `peso_corporal_list_screen.dart` - Control de peso de animales
- `create_peso_corporal_screen.dart` - Registro de peso
- `lactancia_list_screen.dart` - Períodos de lactancia
- `create_lactancia_screen.dart` - Registro de lactancia

#### Gestión Administrativa:
- `rebanos_list_screen.dart` - Lista de rebaños
- `create_rebano_screen.dart` - Creación de rebaños
- `personal_finca_list_screen.dart` - Personal de la finca
- `create_personal_finca_screen.dart` - Registro de personal
- `edit_personal_finca_screen.dart` - Edición de personal

#### Sistema y Configuración:
- `splash_screen.dart` - Pantalla de inicio/carga
- `sync_screen.dart` - Pantalla de sincronización manual
- `pending_sync_screen.dart` - Datos pendientes de sincronización
- `profile_screen.dart` - Perfil del usuario
- `configuration_data_screen.dart` - Configuraciones del sistema

### `/lib/theme/`
**Propósito**: Tema visual y estilo de la aplicación.
- Colores de la marca
- Tipografías
- Estilos de componentes

### `/lib/media/`
**Propósito**: Archivos multimedia específicos del código.
- Recursos embebidos en el código
- Datos binarios integrados

---

## 🧪 Directorio test/

**Propósito**: Tests unitarios e integración para asegurar calidad del código.

### Tipos de Tests Incluidos:
- **Tests de Pantallas**: Validación de widgets y UI
- **Tests de Servicios**: Lógica de negocio y servicios
- **Tests de Autenticación**: Flujos de login y seguridad  
- **Tests de Funcionalidad Offline**: Operaciones sin conexión
- **Tests de Filtros**: Búsquedas y filtrado de datos
- **Tests de Integración**: Flujos completos de usuario

---

## 📱 Directorios de Plataformas

### `/android/`
**Propósito**: Configuración específica de Android.
- Configuración de Gradle 
- Permisos de la aplicación Android
- Icono de la aplicación
- Configuraciones de releases y debug

### `/ios/`
**Propósito**: Configuración específica de iOS.
- Configuración de Xcode
- Configuraciones de Info.plist
- Recursos específicos de iOS

---

## 🎨 Directorio assets/

**Propósito**: Recursos estáticos de la aplicación.
- `icon/` - Iconos de la aplicación
- Imágenes utilizadas en la interfaz
- Recursos gráficos

---

## ⚙️ Archivos de Configuración

### `pubspec.yaml`
**Propósito**: Configuración principal del proyecto Flutter.
- Dependencias de paquetes
- Recursos de assets
- Configuración de versiones

### `analysis_options.yaml`  
**Propósito**: Configuración del analizador estático de Dart.
- Reglas de sintaxis y estilo
- Advertencias y errores permitidos

### `.gitignore`
**Propósito**: Archivos excluidos del control de versiones.
- Archivos de build temporales
- Configuraciones locales del IDE

---

## 🚀 Desarrollo

### Requisitos
- Flutter SDK 3.0+
- Dart SDK 2.17+
- Android Studio / VS Code
- Dispositivo Android / Emulador

### Comandos Principales

```bash
# Obtener dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Gerar APK de debug
flutter build apk --debug

# Ejecutar tests
flutter test

# Limpiar proyecto
flutter clean
```

### Arquitectura

**Patrón**: Arquitectura por capas con servicios separados
**Base de Datos**: SQLite para almacenamiento local
**API**: REST con autenticación JWT
**Estado**: Provider/StatefulWidget para gestión de estado
**Conectividad**: Monitoreo automático de conexión

---

## 📂 Flujo de Datos

1. **Autenticación** → `auth_service.dart` → JWT Token
2. **Datos Offline** → `database_service.dart` → SQLite Local  
3. **Sincronización** → `sync_service.dart` → API REST
4. **UI** → `screens/` → `services/` → `models/`

---

## 📄 Licencia

GanaderaSoft © 2026 - Sistema de Gestión de Ganaderías