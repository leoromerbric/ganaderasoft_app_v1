# Metodologías - GanaderaSoft

Este directorio contiene la documentación metodológica completa del proyecto GanaderaSoft, elaborada mediante análisis exhaustivo del código fuente y basada exclusivamente en las tecnologías, frameworks y estructuras realmente implementadas.

## 📚 Contenido

### 1. [Arquitectura 4+1 Vistas](./arquitectura_4+1.md)
**Modelo de Arquitectura de Software de Kruchten**

Documentación completa de la arquitectura del sistema bajo el modelo 4+1 vistas:
- **Vista Lógica**: Clases, modelos de dominio y sus relaciones
- **Vista de Desarrollo**: Estructura de carpetas, módulos y dependencias
- **Vista de Procesos**: Flujos de autenticación, sincronización offline/online y CRUD
- **Vista Física**: Topología de despliegue (Flutter, SQLite, Laravel API, MySQL)
- **Vista de Escenarios**: Casos de uso principales que validan la arquitectura

**Tecnologías Documentadas:**
- Flutter 3.8.1+ (Frontend móvil)
- SQLite 3 (Base de datos local)
- Laravel API REST (Backend)
- MySQL (Base de datos remota)
- HTTP/REST (Comunicación cliente-servidor)

📊 **Diagramas Incluidos:** 15+ diagramas Mermaid (clases, secuencia, flujo, componentes)

---

### 2. [Plan de Pruebas y Evaluación de Calidad](./plan_pruebas_calidad.md)
**Conforme a ISO/IEC 9126-1 y ISO/IEC 25010**

Plan completo de pruebas y evaluación de calidad basado en estándares internacionales:

**Características de Calidad Evaluadas:**
1. **Adecuación Funcional** - Completitud, corrección y pertinencia
2. **Eficiencia de Desempeño** - Tiempos de respuesta, recursos, capacidad
3. **Compatibilidad** - Coexistencia e interoperabilidad
4. **Usabilidad** - Reconocibilidad, aprendizaje, operabilidad, estética
5. **Fiabilidad** - Madurez, disponibilidad, tolerancia a fallos
6. **Seguridad** - Confidencialidad, integridad, autenticidad
7. **Mantenibilidad** - Modularidad, reusabilidad, analizabilidad
8. **Portabilidad** - Adaptabilidad, instalabilidad, reemplazabilidad

**Métricas y KPIs:**
- Tabla de pruebas funcionales (14 pruebas principales)
- Métricas de tiempo de respuesta
- Análisis de utilización de recursos
- Evaluación de 50+ archivos de test identificados

📈 **Calificación General:** 76/100 (Bueno, con áreas críticas de mejora)

---

### 3. [Metodología Mobile-D](./metodologia_mobile_d.md)
**Mobile Software Development Methodology**

Análisis del desarrollo de GanaderaSoft bajo el marco de Mobile-D:

**Fases Documentadas:**
1. **Exploración** - Definición del proyecto y establecimiento de requisitos
2. **Inicialización** - Configuración del ambiente y línea base técnica
3. **Producción** - 6 iteraciones identificadas de desarrollo incremental
4. **Estabilización** - Testing exhaustivo y corrección de bugs
5. **Pruebas del Sistema** - Validación final y scripts de verificación

**Iteraciones de Desarrollo:**
- Iteración 1: Core (Autenticación y Gestión Básica)
- Iteración 2: Farm Management (Animales y Rebaños)
- Iteración 3: Producción (Lactancia y Registros)
- Iteración 4: Offline (Funcionalidad Offline Completa)
- Iteración 5: Sync (Sincronización Bidireccional)
- Iteración 6: Refinamiento (Corrección de Issues)

📊 **Cumplimiento de Mobile-D:** 89% (Excelente)

---

### 4. [Topología de Despliegue](./topologia_despliegue.md)
**Arquitectura de Despliegue y Nodos del Sistema**

Documentación detallada de la topología de despliegue:

**Nodos del Sistema:**
- **Nodo Cliente**: Dispositivos móviles (Android/iOS) con Flutter y SQLite local
- **Nodo Servidor**: AWS EC2 con Laravel API (52.53.127.245:8000)
- **Capa de Datos**: MySQL Database remota
- **Canales de Comunicación**: HTTP/REST (⚠️ sin SSL)

**Escenarios de Despliegue:**
1. Operación Totalmente Online
2. Operación Parcialmente Offline (Conectividad intermitente)
3. Operación Totalmente Offline (Días/semanas sin conexión)
4. Sincronización Post-Offline

**Análisis Incluido:**
- Especificaciones de hardware y software
- 30+ endpoints REST documentados
- Estructura de SQLite (12 tablas)
- Flujos de comunicación y sincronización
- Recomendaciones de seguridad y escalabilidad

---

## 🎯 Características Generales

### Metodología de Elaboración

Todos los documentos fueron elaborados mediante:
✅ Análisis exhaustivo del código fuente del repositorio  
✅ Identificación de tecnologías realmente implementadas  
✅ Trazabilidad con archivos específicos del código  
✅ Exclusión de tecnologías no presentes (PostgreSQL, Redis, Firebase, etc.)  
✅ Formato Markdown académico-técnico en español  
✅ Diagramas en formato Mermaid

### Advertencias y Notas

Los documentos incluyen advertencias cuando:
- ⚠️ No se encuentra información en el código fuente
- ⚠️ Se identifica un riesgo de seguridad (ej: HTTP sin SSL)
- ⚠️ Se detecta una carencia en implementación
- ⚠️ Se recomienda una mejora crítica

### Tecnologías Identificadas en el Proyecto

**Frontend/Cliente:**
- Flutter SDK 3.8.1+
- Dart
- Material Design
- SQLite (sqflite 2.3.0)
- SharedPreferences 2.2.2
- Provider 6.0.5 (state management)
- connectivity_plus 5.0.2

**Backend/Servidor:**
- Laravel Framework (10+ inferido)
- PHP 8.0+
- MySQL 5.7+/8.0
- REST API (30+ endpoints)

**Comunicación:**
- HTTP 1.1 (⚠️ sin SSL/TLS)
- JSON como formato de datos
- Bearer Token (JWT) para autenticación

**Infraestructura:**
- AWS EC2 (inferido por IP)
- Servidor en 52.53.127.245:8000

### Tecnologías NO Presentes (Confirmado)

❌ PostgreSQL  
❌ Redis  
❌ Firebase  
❌ MongoDB  
❌ GraphQL  
❌ Docker (no hay configuración)  
❌ CI/CD configurado (no hay workflows)  
❌ WebSockets  
❌ gRPC  

---

## 📊 Estadísticas de Documentación

| Documento | Líneas | Diagramas Mermaid | Tablas | Tamaño |
|-----------|--------|-------------------|--------|--------|
| Arquitectura 4+1 | 1,110 | 15 | 20+ | 33 KB |
| Plan de Pruebas | 777 | 5 | 35+ | 34 KB |
| Metodología Mobile-D | 1,274 | 12 | 30+ | 43 KB |
| Topología de Despliegue | 1,322 | 14 | 40+ | 38 KB |
| **TOTAL** | **4,483** | **46** | **125+** | **148 KB** |

---

## 🎓 Uso Académico

Esta documentación es apropiada para:
- ✅ Tesis de grado en Ingeniería de Software
- ✅ Proyectos de curso de Arquitectura de Software
- ✅ Documentación técnica empresarial
- ✅ Presentaciones de arquitectura de sistemas
- ✅ Auditorías de calidad de software
- ✅ Evaluación de metodologías ágiles

---

## 📖 Cómo Leer Esta Documentación

### Para Arquitectos de Software
1. Comenzar con `arquitectura_4+1.md` para entender la estructura completa
2. Revisar `topologia_despliegue.md` para detalles de infraestructura
3. Consultar `plan_pruebas_calidad.md` para aspectos de calidad

### Para Project Managers
1. Comenzar con `metodologia_mobile_d.md` para entender el proceso de desarrollo
2. Revisar las métricas en `plan_pruebas_calidad.md`
3. Consultar recomendaciones en cada documento

### Para Desarrolladores
1. Revisar Vista de Desarrollo en `arquitectura_4+1.md`
2. Consultar endpoints en `topologia_despliegue.md`
3. Estudiar flujos de proceso en `arquitectura_4+1.md` (Vista de Procesos)

### Para QA/Testers
1. Comenzar con `plan_pruebas_calidad.md` completo
2. Revisar escenarios de la Vista de Escenarios en `arquitectura_4+1.md`
3. Consultar escenarios de despliegue en `topologia_despliegue.md`

---

## 🔍 Referencias Cruzadas

Los documentos están interrelacionados:
- Arquitectura 4+1 referencia los endpoints de Topología de Despliegue
- Plan de Pruebas referencia componentes de la Arquitectura
- Metodología Mobile-D traza las fases con la evolución arquitectónica
- Topología de Despliegue detalla los nodos de la Vista Física

---

## 📝 Mantenimiento de la Documentación

**Actualizar cuando:**
- Se agreguen nuevas funcionalidades mayores
- Se cambien tecnologías core (base de datos, framework, etc.)
- Se modifique la arquitectura de despliegue
- Se implementen mejoras de seguridad críticas
- Se migren versiones mayores de dependencias

**Responsable:** Equipo de arquitectura / Líder técnico

**Periodicidad recomendada:** Revisión trimestral o por release major

---

## 🤝 Contribuciones

Para mantener la calidad y precisión de esta documentación:

1. ✅ Basar toda documentación en código real
2. ✅ Incluir referencias a archivos específicos
3. ✅ Marcar con ⚠️ cuando algo no está en el código
4. ✅ Usar formato Markdown y diagramas Mermaid
5. ✅ Mantener tono técnico-formal en español académico
6. ❌ NO documentar tecnologías no implementadas
7. ❌ NO asumir funcionalidades sin evidencia en código

---

## 📧 Contacto

Para consultas sobre esta documentación metodológica, contactar al equipo de desarrollo de GanaderaSoft.

---

**Elaborado:** Octubre 2025  
**Versión del Código Analizado:** 0.1.0  
**Repositorio:** leoromerbric/ganaderasoft_app_v1  
**Estándares de Referencia:** ISO/IEC 25010, 4+1 Views (Kruchten), Mobile-D
