class ConfigurationItem {
  final int id;
  final String nombre;
  final String descripcion;
  final bool activo;
  final String createdAt;
  final String updatedAt;
  final String tipo; // To identify which configuration type this belongs to
  final bool isSynced; // To track if this item is synced offline

  ConfigurationItem({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
    required this.tipo,
    this.isSynced = false,
  });

  factory ConfigurationItem.fromJson(Map<String, dynamic> json, String tipo) {
    return ConfigurationItem(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      activo: json['activo'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      tipo: tipo,
      isSynced: true, // Assume synced when coming from API
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'activo': activo,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'tipo': tipo,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory ConfigurationItem.fromDatabase(Map<String, dynamic> map) {
    return ConfigurationItem(
      id: map['id'] ?? 0,
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      activo: (map['activo'] ?? 1) == 1,
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      tipo: map['tipo'] ?? '',
      isSynced: (map['is_synced'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'activo': activo ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'tipo': tipo,
      'is_synced': isSynced ? 1 : 0,
      'local_updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  ConfigurationItem copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    bool? activo,
    String? createdAt,
    String? updatedAt,
    String? tipo,
    bool? isSynced,
  }) {
    return ConfigurationItem(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tipo: tipo ?? this.tipo,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  String toString() {
    return 'ConfigurationItem{id: $id, nombre: $nombre, tipo: $tipo, isSynced: $isSynced}';
  }
}

// Configuration type constants
class ConfigurationType {
  static const String estadoSalud = 'estado_salud';
  static const String etapas = 'etapas';
  static const String fuenteAgua = 'fuente_agua';
  static const String metodoRiego = 'metodo_riego';
  static const String phSuelo = 'ph_suelo';
  static const String sexo = 'sexo';
  static const String texturaSuelo = 'textura_suelo';
  static const String tipoExplotacion = 'tipo_explotacion';
  static const String tipoRelieve = 'tipo_relieve';
  static const String tiposAnimal = 'tipos_animal';

  static const List<String> all = [
    estadoSalud,
    etapas,
    fuenteAgua,
    metodoRiego,
    phSuelo,
    sexo,
    texturaSuelo,
    tipoExplotacion,
    tipoRelieve,
    tiposAnimal,
  ];

  static String getDisplayName(String tipo) {
    switch (tipo) {
      case estadoSalud:
        return 'Estado de Salud';
      case etapas:
        return 'Etapas de Vida';
      case fuenteAgua:
        return 'Fuentes de Agua';
      case metodoRiego:
        return 'Métodos de Riego';
      case phSuelo:
        return 'pH del Suelo';
      case sexo:
        return 'Sexo de Animales';
      case texturaSuelo:
        return 'Textura del Suelo';
      case tipoExplotacion:
        return 'Tipos de Explotación';
      case tipoRelieve:
        return 'Tipos de Relieve';
      case tiposAnimal:
        return 'Tipos de Animal';
      default:
        return tipo;
    }
  }

  static String getApiEndpoint(String tipo) {
    switch (tipo) {
      case estadoSalud:
        return 'estado-salud';
      case etapas:
        return 'etapas';
      case fuenteAgua:
        return 'fuente-agua';
      case metodoRiego:
        return 'metodo-riego';
      case phSuelo:
        return 'ph-suelo';
      case sexo:
        return 'sexo';
      case texturaSuelo:
        return 'textura-suelo';
      case tipoExplotacion:
        return 'tipo-explotacion';
      case tipoRelieve:
        return 'tipo-relieve';
      case tiposAnimal:
        return 'tipos-animal';
      default:
        return tipo;
    }
  }
}