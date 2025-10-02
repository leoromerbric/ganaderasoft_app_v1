# GanaderaSoft - Documentación

Sistema de gestión integral para fincas ganaderas desarrollado en Flutter.

## Índice de Documentación

### 1. [Arquitectura de la Aplicación](./arquitectura.md)
Descripción detallada de la arquitectura del sistema, módulos principales y su interacción.

### 2. [Estrategia Offline](./estrategia-offline.md)
Documentación completa de la implementación offline, incluyendo diagramas de secuencia y funcionalidades soportadas.

### 3. [Módulos y Funcionalidades](./modulos.md)
Detalle de cada módulo de la aplicación y sus funcionalidades específicas.

### 4. [Base de Datos](./base-datos.md)
Estructura de la base de datos local SQLite, migraciones y modelos.

### 5. [API y Servicios](./api-servicios.md)
Documentación de endpoints de API y servicios de conectividad.

### 6. [Testing](./testing.md)
Estrategia de testing y documentación de pruebas implementadas.

### 7. [Configuración y Deployment](./configuracion.md)
Guías de configuración y despliegue de la aplicación.

## Información General

**Nombre:** GanaderaSoft  
**Versión:** 0.1.0  
**Framework:** Flutter 3.8.1+  
**Plataformas:** Android, iOS, Web, Linux, macOS, Windows  
**Arquitectura:** Cliente-Servidor con soporte offline completo  

## Características Principales

- ✅ **Gestión Integral de Fincas**: Administración completa de fincas ganaderas
- ✅ **Soporte Offline Completo**: Funcionalidad completa sin conexión a internet
- ✅ **Sincronización Inteligente**: Sincronización manual de datos con el servidor
- ✅ **Gestión de Animales**: Registro, seguimiento y administración de ganado
- ✅ **Gestión de Personal**: Administración del personal de la finca
- ✅ **Registros de Producción**: Seguimiento de producción lechera y cambios corporales
- ✅ **Configuración Flexible**: Sistema de configuración adaptable a diferentes tipos de explotación

## Tecnologías Utilizadas

- **Flutter SDK**: ^3.8.1
- **Dart**: Lenguaje de programación principal
- **SQLite**: Base de datos local para soporte offline
- **HTTP**: Comunicación con API REST
- **Shared Preferences**: Almacenamiento de configuración local
- **Connectivity Plus**: Monitoreo de conectividad
- **Provider**: Gestión de estado
- **Crypto**: Seguridad y hash de contraseñas

## Estructura del Proyecto

```
lib/
├── config/                 # Configuración de la aplicación
├── constants/             # Constantes globales
├── models/               # Modelos de datos
├── screens/              # Interfaces de usuario
├── services/             # Servicios y lógica de negocio
├── theme/               # Configuración de temas
└── main.dart           # Punto de entrada de la aplicación

docs/                    # Documentación
├── README.md           # Este archivo
├── arquitectura.md     # Documentación de arquitectura
├── estrategia-offline.md # Documentación offline
├── modulos.md         # Documentación de módulos
├── base-datos.md      # Documentación de base de datos
├── api-servicios.md   # Documentación de API
├── testing.md         # Documentación de testing
└── configuracion.md   # Documentación de configuración
```

## Documentación en Formato Word

Para mayor comodidad, toda la documentación también está disponible en formato Word consolidado en la carpeta `Word/`. Este documento incluye:

- Toda la documentación en un solo archivo
- Estructura y jerarquía preservadas
- Diagramas incluidos como código
- Formato profesional para distribución

Para regenerar el documento Word:
```bash
python3 generate_word_doc.py
```

## Inicio Rápido

Para más información sobre instalación, configuración y uso, consulte la documentación específica en cada sección.

---

*Última actualización: $(date '+%Y-%m-%d')*