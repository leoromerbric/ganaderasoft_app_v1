# Documentación en Formato Word

Esta carpeta contiene la documentación consolidada del proyecto GanaderaSoft en formato Word.

## Contenido

### GanaderaSoft_Documentacion_Consolidada.docx

Documento Word que consolida toda la documentación técnica del proyecto, incluyendo:

1. **Visión General** - Información general del proyecto
2. **Arquitectura** - Diseño y estructura del sistema
3. **Estrategia Offline** - Funcionalidad sin conexión
4. **Módulos y Funcionalidades** - Detalles de cada módulo
5. **Base de Datos** - Esquema y operaciones de BD
6. **API y Servicios** - Endpoints y servicios
7. **Testing** - Estrategia y pruebas
8. **Configuración y Deployment** - Configuración e implementación

## Características del Documento

- ✅ Mantiene la estructura original de la documentación
- ✅ Incluye todos los diagramas Mermaid como bloques de código
- ✅ Preserva el formato de código con sintaxis resaltada
- ✅ Conserva listas, tablas y jerarquía de encabezados
- ✅ Incluye página de título e índice de contenidos

## Generación del Documento

El documento se genera automáticamente usando el script `generate_word_doc.py` ubicado en la raíz del proyecto.

Para regenerar el documento:

```bash
python3 generate_word_doc.py
```

## Requisitos

- Python 3.8+
- python-docx
- markdown2
- Pillow

Para instalar las dependencias:

```bash
pip3 install python-docx markdown2 Pillow
```

## Notas

- Los diagramas Mermaid se incluyen como bloques de código debido a las limitaciones de Word para renderizar diagramas dinámicos.
- Para visualizar los diagramas, puede copiar el código en un visualizador de Mermaid en línea o usar extensiones de VS Code.
- El documento se actualiza con cada ejecución del script, reflejando los cambios más recientes en la documentación.
