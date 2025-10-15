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

### Configuración de Desarrollo
```dart
// lib/config/environment.dart
class Environment {
  static const bool isDevelopment = true;
  static const bool enableLogging = true;
  static const Duration httpTimeout = Duration(seconds: 30);
  
  static String get apiUrl => isDevelopment 
    ? 'http://localhost:8000/api'
    : 'http://52.53.127.245:8000/api';
}
```

### Configuración de Producción
```dart
class Environment {
  static const bool isDevelopment = false;
  static const bool enableLogging = false;
  static const Duration httpTimeout = Duration(seconds: 10);
  
  static String get apiUrl => 'https://api.ganaderasoft.com/api';
}
```

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

### GitHub Actions

#### Workflow para Testing
```yaml
# .github/workflows/test.yml
name: Test Suite

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.8.1'
        channel: 'stable'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Analyze code
      run: flutter analyze
    
    - name: Run tests
      run: flutter test --coverage
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info
```

#### Workflow para Build Android
```yaml
# .github/workflows/build-android.yml
name: Build Android

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Java
      uses: actions/setup-java@v3
      with:
        java-version: '11'
        distribution: 'temurin'
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.8.1'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Build APK
      run: flutter build apk --release
    
    - name: Build App Bundle
      run: flutter build appbundle --release
    
    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: android-builds
        path: |
          build/app/outputs/flutter-apk/app-release.apk
          build/app/outputs/bundle/release/app-release.aab
```

### Firebase App Distribution

#### Configuración
```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Login a Firebase
firebase login

# Configurar proyecto
firebase init hosting
```

#### Deploy Automático
```yaml
# firebase.json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

## Configuración de Base de Datos

### Migración de Esquema

#### Sistema de Versiones
```dart
class DatabaseMigrations {
  static const Map<int, List<String>> migrations = {
    2: [
      'ALTER TABLE animales ADD COLUMN nueva_columna TEXT',
    ],
    3: [
      'CREATE TABLE nueva_tabla (id INTEGER PRIMARY KEY)',
      'UPDATE version SET number = 3',
    ],
  };
  
  static Future<void> runMigrations(Database db, int oldVersion, int newVersion) async {
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      if (migrations.containsKey(version)) {
        for (String sql in migrations[version]!) {
          await db.execute(sql);
        }
      }
    }
  }
}
```

### Backup y Restauración

#### Script de Backup
```dart
class DatabaseBackup {
  static Future<void> exportToJson() async {
    final db = await DatabaseService.database;
    
    final backup = {
      'version': await DatabaseService.getDatabaseVersion(),
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'users': await db.query('users'),
        'fincas': await db.query('fincas'),
        'animales': await db.query('animales'),
        // ... otras tablas
      }
    };
    
    final json = jsonEncode(backup);
    // Guardar en archivo o enviar al servidor
  }
  
  static Future<void> importFromJson(String jsonData) async {
    final data = jsonDecode(jsonData);
    final db = await DatabaseService.database;
    
    // Limpiar datos existentes
    await db.delete('animales');
    await db.delete('fincas');
    // ... otras tablas
    
    // Importar datos
    for (final user in data['data']['users']) {
      await db.insert('users', user);
    }
    // ... importar otras tablas
  }
}
```

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
```bash
# Agregar Firebase Analytics
flutter pub add firebase_analytics
flutter pub add firebase_crashlytics

# Configurar en main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  
  runApp(MyApp());
}
```

## Seguridad

### Configuración de Red
```dart
class SecurityConfig {
  // Configurar certificados SSL
  static void setupSSL() {
    HttpOverrides.global = MyHttpOverrides();
  }
  
  // Validar certificados
  static bool validateCertificate(X509Certificate cert, String host, int port) {
    // Implementar validación personalizada
    return cert.issuer.contains('Let\'s Encrypt') || 
           cert.issuer.contains('DigiCert');
  }
}
```

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