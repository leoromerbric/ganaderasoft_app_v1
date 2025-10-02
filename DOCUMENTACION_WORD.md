# Generación de Documentación en Formato Word

## Descripción

Este proyecto incluye un sistema automatizado para generar un documento Word consolidado que contiene toda la documentación técnica del proyecto GanaderaSoft.

## Ubicación del Documento

El documento Word generado se encuentra en:
```
Word/GanaderaSoft_Documentacion_Consolidada.docx
```

## Características

### Contenido Incluido

El documento consolidado incluye toda la documentación de la carpeta `docs/`:

1. **README.md** - Visión general del proyecto
2. **arquitectura.md** - Arquitectura del sistema
3. **estrategia-offline.md** - Estrategia de funcionalidad offline
4. **modulos.md** - Módulos y funcionalidades
5. **base-datos.md** - Estructura de base de datos
6. **api-servicios.md** - API y servicios
7. **testing.md** - Estrategia de testing
8. **configuracion.md** - Configuración y deployment

### Estructura del Documento

- **Página de título**: Con el nombre del proyecto y descripción
- **Índice de contenidos**: Lista de todas las secciones
- **Contenido completo**: Toda la documentación manteniendo la estructura original
- **Diagramas**: 24 diagramas Mermaid incluidos como bloques de código
- **Código**: 87 bloques de código con sintaxis destacada
- **Formato**: 328 encabezados organizados jerárquicamente

### Características Técnicas

✅ **Preserva la estructura**: Mantiene la jerarquía de encabezados original  
✅ **Incluye diagramas**: Todos los diagramas Mermaid como código  
✅ **Formato de código**: Bloques de código con fuente monoespaciada  
✅ **Estilos consistentes**: Formato profesional para Word  
✅ **Navegación**: Índice de contenidos para fácil navegación  

## Cómo Generar el Documento

### Requisitos Previos

1. Python 3.8 o superior
2. Dependencias de Python:
   ```bash
   pip3 install python-docx markdown2 Pillow
   ```

### Generación

Ejecute el script desde la raíz del proyecto:

```bash
python3 generate_word_doc.py
```

El script:
1. Crea la carpeta `Word/` si no existe
2. Lee todos los archivos markdown de `docs/`
3. Procesa el contenido manteniendo formato
4. Extrae y preserva los diagramas Mermaid
5. Genera el archivo Word consolidado

### Salida

```
============================================================
Generando documento Word consolidado de GanaderaSoft
============================================================

Carpeta Word: /path/to/Word
Creando documento Word...
Agregando página de título...
Agregando índice de contenidos...
Procesando archivos de documentación...
Processing README.md...
Completed README.md
...

✓ Documento generado exitosamente!
✓ Ubicación: Word/GanaderaSoft_Documentacion_Consolidada.docx
============================================================
```

## Estructura de Archivos

```
ganaderasoft_app_v1/
├── docs/                           # Documentación en Markdown
│   ├── README.md
│   ├── arquitectura.md
│   ├── estrategia-offline.md
│   ├── modulos.md
│   ├── base-datos.md
│   ├── api-servicios.md
│   ├── testing.md
│   └── configuracion.md
├── Word/                           # Documentación en Word
│   ├── README.md                   # Información sobre el documento
│   └── GanaderaSoft_Documentacion_Consolidada.docx
└── generate_word_doc.py           # Script de generación
```

## Detalles Técnicos del Script

### `generate_word_doc.py`

El script Python realiza las siguientes operaciones:

1. **Configuración del documento**:
   - Crea un documento Word con propiedades configuradas
   - Establece título, autor y comentarios

2. **Página de título**:
   - Título centrado "GanaderaSoft"
   - Subtítulo "Documentación Técnica Consolidada"
   - Información del proyecto

3. **Índice de contenidos**:
   - Lista numerada de todas las secciones
   - Facilita la navegación

4. **Procesamiento de Markdown**:
   - Extrae diagramas Mermaid
   - Convierte encabezados a estilos de Word
   - Procesa bloques de código con formato
   - Mantiene listas y numeración
   - Aplica formato a texto (negrita, cursiva, código inline)

5. **Manejo de diagramas**:
   - Los diagramas Mermaid se incluyen como bloques de código
   - Cada diagrama está numerado
   - Formato monoespaciado con color distintivo

6. **Formato de código**:
   - Fuente Courier New
   - Tamaño de texto reducido (9pt)
   - Color azul oscuro para mejor legibilidad

## Visualización de Diagramas

Los diagramas Mermaid se incluyen como código en el documento. Para visualizarlos:

1. **Visualizador online**: Copie el código en https://mermaid.live/
2. **VS Code**: Use la extensión "Markdown Preview Mermaid Support"
3. **Herramientas**: Use mermaid-cli para convertir a imágenes localmente

## Mantenimiento

### Actualizar el Documento

Cuando se actualice la documentación en `docs/`, simplemente vuelva a ejecutar:

```bash
python3 generate_word_doc.py
```

El documento se regenerará con el contenido actualizado.

### Modificar el Script

Para personalizar el documento:

1. Edite `generate_word_doc.py`
2. Modifique estilos en la función `create_document()`
3. Ajuste el formato en `process_markdown_content()`
4. Cambie el orden en la constante `DOC_ORDER`

## Resolución de Problemas

### Error: Módulo no encontrado

```bash
pip3 install python-docx markdown2 Pillow
```

### Error: Archivo no encontrado

Verifique que está ejecutando el script desde la raíz del proyecto:
```bash
cd /path/to/ganaderasoft_app_v1
python3 generate_word_doc.py
```

### Documento vacío o incompleto

Verifique que todos los archivos markdown existen en `docs/`:
```bash
ls -la docs/*.md
```

## Estadísticas del Documento Generado

- **Tamaño**: ~65 KB
- **Párrafos**: 1,042
- **Encabezados**: 328
- **Diagramas**: 24
- **Bloques de código**: 87
- **Secciones**: 8 documentos principales

## Referencias

- **python-docx**: https://python-docx.readthedocs.io/
- **markdown2**: https://github.com/trentm/python-markdown2
- **Mermaid**: https://mermaid.js.org/

---

*Documentación generada para GanaderaSoft v0.1.0*
