# Configuración y Deployment

## Visión General

Esta guía proporciona información detallada sobre la configuración, instalación y despliegue de GanaderaSoft en diferentes plataformas.

## Requisitos del Sistema

### Desarrollo

#### Flutter SDK
- **Versión**: 3.8.1 o superior
- **Canal**: Stable
- **Dart**: 3.0.0 o superior

#### Herramientas de Desarrollo
- **Android Studio**: 4.0+ (para desarrollo Android)
- **Xcode**: 13.0+ (para desarrollo iOS, solo macOS)
- **VS Code**: Con extensión Flutter (opcional)

#### Dependencias del Sistema
```bash
# Android
- Android SDK 30+
- Android Build Tools 30.0.3+
- Android Emulator o dispositivo físico

# iOS (solo macOS)
- iOS 11.0+
- CocoaPods 1.10.0+

# Desktop
- Windows 10 1903+ (para Windows)
- macOS 10.14+ (para macOS)
- Linux (Ubuntu 18.04+ recomendado)
```

### Producción

#### Servidor Backend
- **URL**: `http://52.53.127.245:8000`
- **API**: REST con endpoints JSON
- **Autenticación**: JWT Bearer tokens

#### Dispositivos Soportados
- **Android**: 5.0 (API 21) o superior
- **iOS**: 11.0 o superior
- **Web**: Navegadores modernos (Chrome, Firefox, Safari, Edge)
- **Desktop**: Windows 10+, macOS 10.14+, Linux Ubuntu 18.04+

## Instalación y Configuración

### 1. Configuración del Entorno de Desarrollo

#### Instalar Flutter
```bash
# Descargar Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verificar instalación
flutter doctor
```

#### Configurar Editor
```bash
# VS Code
code --install-extension Dart-Code.flutter

# Android Studio
# Instalar plugins: Flutter y Dart
```

### 2. Clonar y Configurar Proyecto

```bash
# Clonar repositorio
git clone https://github.com/leoromerbric/ganaderasoft_app_v1.git
cd ganaderasoft_app_v1

# Instalar dependencias
flutter pub get

# Verificar configuración
flutter doctor
flutter devices
```

### 3. Configuración de Base de Datos

#### SQLite Local
```dart
// La base de datos se crea automáticamente en primera ejecución
// Ubicación por defecto:
// Android: /data/data/com.example.ganaderasoft_app_v1/databases/
// iOS: ~/Library/Application Support/ganaderasoft.db
// Desktop: ~/Documents/ganaderasoft.db
```

#### Configuración de Conexión API
```dart
// lib/config/app_config.dart
class AppConfig {
  // Configurar URL del servidor
  static const String _baseUrl = 'http://52.53.127.245:8000';
  
  // Para desarrollo local, cambiar a:
  // static const String _baseUrl = 'http://localhost:8000';
  
  // Para producción, cambiar a:
  // static const String _baseUrl = 'https://api.ganaderasoft.com';
}
```

## Configuración por Plataforma

### Android

#### Configuración en `android/app/build.gradle`
```gradle
android {
    compileSdkVersion 33
    ndkVersion flutter.ndkVersion

    defaultConfig {
        applicationId "com.ganaderasoft.app"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName "0.1.0"
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

#### Permisos en `android/app/src/main/AndroidManifest.xml`
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permisos de red -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- Permisos de almacenamiento -->
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    
    <application
        android:name="${applicationName}"
        android:icon="@mipmap/launcher_icon"
        android:label="GanaderaSoft">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### iOS

#### Configuración en `ios/Runner/Info.plist`
```xml
<dict>
    <key>CFBundleName</key>
    <string>GanaderaSoft</string>
    <key>CFBundleIdentifier</key>
    <string>com.ganaderasoft.app</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    
    <!-- Permisos de red -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
```

### Web

#### Configuración en `web/index.html`
```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>GanaderaSoft</title>
  <link rel="manifest" href="manifest.json">
  <link rel="icon" type="image/png" href="favicon.png"/>
</head>
<body>
  <script src="flutter.js" defer></script>
  <script>
    window.addEventListener('load', function(ev) {
      _flutter.loader.loadEntrypoint({
        serviceWorker: {
          serviceWorkerVersion: null,
        }
      }).then(function(engineInitializer) {
        return engineInitializer.initializeEngine();
      }).then(function(appRunner) {
        return appRunner.runApp();
      });
    });
  </script>
</body>
</html>
```

## Variables de Entorno

### Configuración de API

La configuración de la API se encuentra en `lib/config/app_config.dart`:

```dart
// lib/config/app_config.dart
class AppConfig {
  static const String _baseUrl = 'http://52.53.127.245:8000';
  
  static String get baseUrl => _baseUrl;
  static String get apiUrl => '$_baseUrl/api';
  
  // Para cambiar a servidor de desarrollo, modificar _baseUrl:
  // static const String _baseUrl = 'http://localhost:8000';
  
  // Para producción con HTTPS:
  // static const String _baseUrl = 'https://api.ganaderasoft.com';
}
```

**Nota**: No hay un sistema de variables de entorno implementado. Para cambiar el servidor, se debe modificar directamente el archivo `app_config.dart`.

## Build y Deployment

### Comandos de Build

#### Debug Build (Desarrollo)
```bash
# Android
flutter build apk --debug
flutter install

# iOS
flutter build ios --debug

# Web
flutter build web --debug

# Desktop
flutter build windows --debug
flutter build macos --debug
flutter build linux --debug
```

#### Release Build (Producción)
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Desktop
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

### Optimizaciones de Build

#### Reducir Tamaño de APK
```bash
# Split APKs por arquitectura
flutter build apk --split-per-abi

# Obfuscación de código
flutter build apk --obfuscate --split-debug-info=build/debug-info/
```

#### Optimizaciones Web
```bash
# Build optimizado para web
flutter build web --release --web-renderer html

# Con tree-shaking
flutter build web --release --tree-shake-icons
```

## Configuración de CI/CD

### Opciones de CI/CD

El proyecto actualmente no tiene pipelines de CI/CD configurados. Las siguientes son opciones recomendadas si se desea implementar en el futuro:

#### GitHub Actions (Ejemplo para consideración futura)
- Crear workflows en `.github/workflows/` para automatizar testing y builds
- Configurar steps para `flutter pub get`, `flutter analyze`, `flutter test`
- Configurar builds para Android/iOS/Web según plataformas objetivo

#### Otras Opciones
- **GitLab CI/CD**: Para proyectos en GitLab
- **Bitbucket Pipelines**: Para proyectos en Bitbucket
- **Jenkins**: Para configuraciones on-premise
- **CircleCI**: Alternativa cloud-based

**Nota**: Actualmente el proyecto no tiene CI/CD configurado. Los builds se realizan manualmente usando los comandos de Flutter.

## Configuración de Base de Datos

### Migración de Esquema

#### Sistema de Versiones

El sistema de migraciones de base de datos está implementado directamente en `DatabaseService`:

```dart
// lib/services/database_service.dart
static const int _databaseVersion = 11;

static Future<Database> _initDatabase() async {
  return await openDatabase(
    path,
    version: _databaseVersion,
    onCreate: _createDatabase,
    onUpgrade: _upgradeDatabase,
  );
}
```

Las migraciones se manejan en el método `_upgradeDatabase` que se ejecuta automáticamente cuando cambia la versión de la base de datos.

### Backup y Restauración

#### Estrategia Actual

La aplicación actualmente no tiene un sistema de backup/restauración implementado. Los datos se mantienen sincronizados con el servidor a través de:

1. **Sincronización automática**: Los datos se guardan en el servidor cuando hay conectividad
2. **Cache local**: SQLite mantiene copia local de todos los datos
3. **Recuperación desde servidor**: Los datos pueden re-descargarse del servidor

**Nota**: Para implementar backup/export en el futuro, se puede considerar exportar datos a JSON o implementar funcionalidad de backup a archivos locales.

## Monitoreo y Logging

### Configuración de Logging
```dart
class LoggingConfig {
  static void setup() {
    if (Environment.isDevelopment) {
      // Logging detallado en desarrollo
      LoggingService.setLevel(LogLevel.debug);
    } else {
      // Logging mínimo en producción
      LoggingService.setLevel(LogLevel.error);
    }
  }
}
```

### Analytics y Crash Reporting

El proyecto actualmente no tiene analytics ni crash reporting configurados. Si se desea implementar en el futuro, considere:

#### Opciones de Analytics
- **Firebase Analytics**: Análisis de uso y comportamiento de usuarios
- **Google Analytics**: Alternativa web-based
- **Mixpanel**: Analytics avanzado con segmentación de usuarios
- **Amplitude**: Analytics enfocado en producto

#### Opciones de Crash Reporting
- **Firebase Crashlytics**: Reporting de crashes en tiempo real
- **Sentry**: Plataforma de monitoring de errores
- **Bugsnag**: Monitoring y reporting de errores

**Nota**: Actualmente el proyecto usa `LoggingService` para logging básico en consola. No hay integración con servicios externos de analytics o crash reporting.

## Seguridad

### Configuración de Red

La aplicación utiliza las configuraciones de seguridad predeterminadas de Flutter/Dart para conexiones HTTP:

- **HTTPS**: Se recomienda usar HTTPS en producción para el servidor API
- **Certificados SSL**: Flutter valida automáticamente certificados SSL estándar
- **Timeouts**: Configurados en las peticiones HTTP para evitar bloqueos

**Nota**: Actualmente no hay validación personalizada de certificados SSL implementada. Se utiliza la validación estándar del framework.

### Obfuscación de Código
```bash
# Build con obfuscación
flutter build apk --obfuscate --split-debug-info=build/debug-info/

# Mantener símbolos específicos
# android/app/proguard-rules.pro
-keep class com.ganaderasoft.** { *; }
-keepattributes *Annotation*
```

## Troubleshooting

### Problemas Comunes

#### Error de Base de Datos
```dart
// Limpiar base de datos corrupta
static Future<void> resetDatabase() async {
  final documentsDirectory = await getApplicationDocumentsDirectory();
  final path = join(documentsDirectory.path, 'ganaderasoft.db');
  
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
  
  // Reinicializar base de datos
  _database = null;
  await database;
}
```

#### Problemas de Conectividad
```dart
// Diagnóstico de red
static Future<void> diagnoseConnectivity() async {
  final hasNetwork = await ConnectivityService.hasNetworkConnection();
  final isServerReachable = await ConnectivityService.isConnected();
  
  print('Network available: $hasNetwork');
  print('Server reachable: $isServerReachable');
  
  if (hasNetwork && !isServerReachable) {
    print('Network available but server unreachable');
    print('Check server URL: ${AppConfig.baseUrl}');
  }
}
```

### Comandos de Debugging
```bash
# Limpiar cache de Flutter
flutter clean
flutter pub get

# Verificar dependencias
flutter pub deps

# Analizar código
flutter analyze

# Ejecutar en modo debug verboso
flutter run --debug --verbose

# Profile performance
flutter run --profile
```

## Documentación de APIs

Toda la documentación detallada de los endpoints de API se encuentra en:
- `apis_docs/`: Documentación de endpoints individuales
- Formato: Archivos `.txt` con ejemplos de request/response
- Cobertura: Todos los endpoints utilizados por la aplicación

---

*Fin de la documentación. Para más información, consulte los archivos específicos en cada sección.*