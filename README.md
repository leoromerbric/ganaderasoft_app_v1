# GanaderaSoft

GanaderaSoft es una aplicación móvil Flutter para la gestión integral de fincas ganaderas. Permite administrar información de fincas, animales y propietarios a través de una interfaz moderna y fácil de usar.

## Características

- 🔐 **Autenticación segura** con tokens JWT
- 🎨 **Tema moderno** con soporte para modo claro y oscuro
- 🏠 **Gestión de fincas** - Visualización y administración de fincas ganaderas
- 👤 **Perfil de usuario** - Información detallada del propietario
- 📱 **Interfaz responsive** optimizada para dispositivos móviles
- 🌐 **API REST** integración con backend Laravel

## Funcionalidades Implementadas

### 1. Autenticación
- Login con email y contraseña
- Almacenamiento seguro de tokens de sesión
- Logout con confirmación
- Verificación automática de sesión activa

### 2. Pantallas Principales
- **Splash Screen**: Verificación de estado de autenticación
- **Login**: Formulario de inicio de sesión con validación
- **Home**: Pantalla principal con accesos rápidos
- **Mi Cuenta**: Visualización del perfil del usuario
- **Administrar Fincas**: Lista de fincas del usuario

### 3. Navegación
- Menú lateral (Drawer) con navegación principal
- Navegación entre pantallas con estado preservado
- Manejo de rutas y navegación programática

## Estructura del Proyecto

```
lib/
├── config/
│   └── app_config.dart          # Configuración de URLs del backend
├── models/
│   ├── user.dart                # Modelo de datos del usuario
│   └── finca.dart               # Modelo de datos de fincas
├── screens/
│   ├── splash_screen.dart       # Pantalla de carga inicial
│   ├── login_screen.dart        # Pantalla de login
│   ├── home_screen.dart         # Pantalla principal
│   ├── profile_screen.dart      # Pantalla de perfil
│   └── fincas_screen.dart       # Pantalla de fincas
├── services/
│   └── auth_service.dart        # Servicio de autenticación y API
├── theme/
│   └── app_theme.dart           # Tema de colores y estilos
└── main.dart                    # Punto de entrada de la aplicación
```

## Configuración del Backend

La aplicación está configurada para conectarse a un backend Laravel en `http://localhost:8000`. Para cambiar la URL del backend, modifica el archivo `lib/config/app_config.dart`:

```dart
class AppConfig {
  static const String _baseUrl = 'https://tu-servidor.com';
  // ...
}
```

## APIs Integradas

- `POST /api/auth/login` - Autenticación de usuario
- `POST /api/auth/logout` - Cierre de sesión
- `GET /api/profile` - Obtener perfil del usuario
- `GET /api/fincas` - Listar fincas del usuario

## Tecnologías Utilizadas

- **Flutter 3.24+** - Framework de desarrollo
- **Dart 3.8+** - Lenguaje de programación
- **HTTP** - Cliente para peticiones REST
- **SharedPreferences** - Almacenamiento local de datos
- **Material Design 3** - Sistema de diseño

## Instalación y Ejecución

1. Asegúrate de tener Flutter instalado en tu sistema
2. Clona el repositorio
3. Instala las dependencias:
   ```bash
   flutter pub get
   ```
4. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

## Compilación para Producción

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Próximas Funcionalidades

- Gestión detallada de animales
- Reportes y estadísticas
- Notificaciones push
- Modo offline
- Geolocalización de fincas
- Exportación de datos

## Contribución

Para contribuir al proyecto:

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crea un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.
