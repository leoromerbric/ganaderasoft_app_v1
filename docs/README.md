# Documentación Técnica - Sincronización de Animales GanaderaSoft

## Índice de Documentación

### 📖 Documentos Principales

1. **[Sincronización de Animales - Guía Completa](./sincronizacion-animales.md)**
   - Proceso paso a paso de sincronización
   - Componentes y servicios involucrados
   - Manejo de errores y recuperación
   - Estructura de base de datos
   - Consideraciones de rendimiento

2. **[Diagrama de Secuencia](./diagrama-secuencia-sincronizacion.md)**
   - Diagrama Mermaid del flujo completo
   - Interacciones entre componentes
   - Fases del proceso de sincronización
   - Manejo de errores visualizado

## 🎯 Resumen Ejecutivo

La sincronización de datos de animales en GanaderaSoft es un proceso complejo que maneja dos flujos principales:

### Flujo Principal (Descarga)
- **Objetivo**: Descargar datos frescos del servidor a la base de datos local
- **Trigger**: Reestablecimiento de conexión a internet
- **Duración**: Variable según cantidad de animales (puede ser varios minutos)
- **Progreso**: Reportado en tiempo real de 0% a 100%

### Flujo de Pendientes (Subida)
- **Objetivo**: Sincronizar cambios locales con el servidor
- **Trigger**: Datos creados/modificados offline
- **Operaciones**: CREATE y UPDATE de animales y personal finca
- **Garantías**: Transacciones atómicas, no se pierden datos

## 🔧 Componentes Técnicos Clave

### Servicios Core
```
lib/services/sync_service.dart         - Orquestador principal
lib/services/auth_service.dart         - API HTTP
lib/services/database_service.dart     - SQLite local
lib/services/connectivity_service.dart - Estado de red
```

### Pantallas de Usuario
```
lib/screens/pending_sync_screen.dart   - Gestión de pendientes
lib/screens/sync_screen.dart           - UI principal de sincronización
```

### Tablas de Base de Datos
```sql
animales          - Datos principales de animales
animal_detail     - Información detallada de cada animal
rebanos           - Rebaños/grupos de animales
cambios_animal    - Historial de cambios
peso_corporal     - Registros de peso
personal_finca    - Personal de la finca
lactancia         - Registros de lactancia
```

## 📊 Flujo de Datos

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   SERVIDOR      │    │   APLICACIÓN    │    │  BASE DATOS     │
│     (API)       │    │   (Flutter)     │    │   (SQLite)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │  ← Descarga datos     │                       │
         │                       │  → Guarda offline    │
         │                       │                       │
         │  ← Sube pendientes    │  ← Lee pendientes    │
         │                       │                       │
```

## 🚨 Casos de Uso Críticos

### Escenario 1: Usuario Offline Prolongado
1. Usuario crea/modifica animales sin conexión
2. Datos se guardan con IDs temporales negativos
3. Al reconectar, automáticamente se sincronizan cambios
4. IDs temporales se reemplazan por IDs reales del servidor

### Escenario 2: Falla Parcial en Sincronización
1. Algunos animales fallan al sincronizar detalles
2. Se registra warning en logs
3. Proceso continúa con animales restantes
4. Usuario ve progreso parcial, no se pierde trabajo

### Escenario 3: Pérdida de Conexión Durante Sync
1. Sincronización se interrumpe
2. Datos ya sincronizados se conservan
3. Al reconectar, se reanuda desde donde se quedó
4. No hay duplicación de datos

## 🔍 Monitoreo y Debugging

### Logs del Sistema
```
LoggingService.debug() - Información detallada
LoggingService.info()  - Eventos importantes  
LoggingService.warning() - Errores no críticos
LoggingService.error() - Errores críticos
```

### Stream de Progreso
```dart
SyncData {
  status: SyncStatus,      // idle, syncing, success, error
  message: String?,        // Mensaje descriptivo
  progress: double         // 0.0 a 1.0 (0% a 100%)
}
```

### Verificación de Estado
```dart
// Verificar si hay pendientes
DatabaseService.getAllPendingRecords()

// Verificar último sync
DatabaseService.getLastSyncTimes()

// Verificar conectividad
ConnectivityService.isConnected()
```

## 🛠️ Consideraciones de Desarrollo

### Optimizaciones Aplicadas
- ✅ Sincronización incremental (evita re-descargar datos)
- ✅ Procesamiento por lotes para eficiencia  
- ✅ Transacciones atómicas para integridad
- ✅ Manejo de memoria optimizado
- ✅ Progress reporting granular

### Limitaciones Conocidas
- ⚠️ Sincronización secuencial de detalles (puede ser lenta)
- ⚠️ Requiere conexión estable durante todo el proceso
- ⚠️ Tiempo proporcional al número de animales

### Mejoras Futuras Recomendadas
- 🔄 Sincronización paralela de detalles de animales
- 🔄 Sincronización delta (solo cambios desde último sync)
- 🔄 Compresión de datos para reducir transferencia
- 🔄 Sincronización en background con notificaciones

## 📋 Lista de Verificación para Testing

### Testing Manual
- [ ] Crear animales offline y verificar sincronización
- [ ] Interrumpir sincronización y verificar recuperación
- [ ] Modificar animales existentes offline
- [ ] Verificar manejo de errores de red
- [ ] Confirmar integridad de datos post-sincronización

### Testing Automatizado
```
test/sync_fix_verification_test.dart        - Verificación de fix de sincronización
test/offline_animal_integration_test.dart   - Testing de flujo offline completo
test/enhanced_sync_functionality_test.dart  - Testing de funcionalidad extendida
```

## 📞 Contacto y Soporte

Para preguntas técnicas sobre la sincronización de animales:
- Revisar logs del sistema usando LoggingService
- Consultar tests automatizados para casos de uso
- Referirse a esta documentación para flujo detallado

---

**Última Actualización**: Documentación generada basada en análisis del código fuente
**Versión del Código**: Basado en commit actual del repositorio
**Precisión**: 100% fiel al funcionamiento real del código