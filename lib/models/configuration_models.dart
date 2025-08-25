// Configuration Models for GanaderaSoft
// These models represent the various configuration data types used throughout the application

// Simple codigo/nombre pattern models
class FuenteAgua {
  final String codigo;
  final String nombre;
  final bool? synced; // For offline sync status

  FuenteAgua({required this.codigo, required this.nombre, this.synced = false});

  factory FuenteAgua.fromJson(Map<String, dynamic> json) {
    return FuenteAgua(
      codigo: json['codigo'],
      nombre: json['nombre'],
      synced: json['synced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'codigo': codigo, 'nombre': nombre, 'synced': synced};
  }
}

class Sexo {
  final String codigo;
  final String nombre;
  final bool? synced;

  Sexo({required this.codigo, required this.nombre, this.synced = false});

  factory Sexo.fromJson(Map<String, dynamic> json) {
    return Sexo(
      codigo: json['codigo'],
      nombre: json['nombre'],
      synced: json['synced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'codigo': codigo, 'nombre': nombre, 'synced': synced};
  }
}

class MetodoRiego {
  final String codigo;
  final String nombre;
  final bool? synced;

  MetodoRiego({
    required this.codigo,
    required this.nombre,
    this.synced = false,
  });

  factory MetodoRiego.fromJson(Map<String, dynamic> json) {
    return MetodoRiego(
      codigo: json['codigo'],
      nombre: json['nombre'],
      synced: json['synced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'codigo': codigo, 'nombre': nombre, 'synced': synced};
  }
}

class TexturaSuelo {
  final String codigo;
  final String nombre;
  final bool? synced;

  TexturaSuelo({
    required this.codigo,
    required this.nombre,
    this.synced = false,
  });

  factory TexturaSuelo.fromJson(Map<String, dynamic> json) {
    return TexturaSuelo(
      codigo: json['codigo'],
      nombre: json['nombre'],
      synced: json['synced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'codigo': codigo, 'nombre': nombre, 'synced': synced};
  }
}

class TipoExplotacion {
  final String codigo;
  final String nombre;
  final bool? synced;

  TipoExplotacion({
    required this.codigo,
    required this.nombre,
    this.synced = false,
  });

  factory TipoExplotacion.fromJson(Map<String, dynamic> json) {
    return TipoExplotacion(
      codigo: json['codigo'],
      nombre: json['nombre'],
      synced: json['synced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'codigo': codigo, 'nombre': nombre, 'synced': synced};
  }
}

// codigo/nombre/descripcion pattern
class PhSuelo {
  final String codigo;
  final String nombre;
  final String descripcion;
  final bool? synced;

  PhSuelo({
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    this.synced = false,
  });

  factory PhSuelo.fromJson(Map<String, dynamic> json) {
    return PhSuelo(
      codigo: json['codigo'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      synced: json['synced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'synced': synced,
    };
  }
}

// id/valor/descripcion pattern
class TipoRelieve {
  final int id;
  final String valor;
  final String descripcion;
  final bool? synced;

  TipoRelieve({
    required this.id,
    required this.valor,
    required this.descripcion,
    this.synced = false,
  });

  factory TipoRelieve.fromJson(Map<String, dynamic> json) {
    return TipoRelieve(
      id: json['id'],
      valor: json['valor'],
      descripcion: json['descripcion'],
      synced: json['synced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'valor': valor,
      'descripcion': descripcion,
      'synced': synced,
    };
  }
}

// Paginated models
class EstadoSalud {
  final int estadoId;
  final String estadoNombre;
  final bool? synced;

  EstadoSalud({
    required this.estadoId,
    required this.estadoNombre,
    this.synced = false,
  });

  factory EstadoSalud.fromJson(Map<String, dynamic> json) {
    return EstadoSalud(
      estadoId: json['estado_id'],
      estadoNombre: json['estado_nombre'],
      synced: json['synced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estado_id': estadoId,
      'estado_nombre': estadoNombre,
      'synced': synced,
    };
  }
}

class TipoAnimal {
  final int tipoAnimalId;
  final String tipoAnimalNombre;
  final bool? synced;

  TipoAnimal({
    required this.tipoAnimalId,
    required this.tipoAnimalNombre,
    this.synced = false,
  });

  factory TipoAnimal.fromJson(Map<String, dynamic> json) {
    return TipoAnimal(
      tipoAnimalId: json['tipo_animal_id'] ?? 0,
      tipoAnimalNombre: json['tipo_animal_nombre'] ?? '',
      synced: json['synced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo_animal_id': tipoAnimalId,
      'tipo_animal_nombre': tipoAnimalNombre,
      'synced': synced,
    };
  }
}

// Complex Etapa model with nested TipoAnimal
class Etapa {
  final int etapaId;
  final String etapaNombre;
  final int etapaEdadIni;
  final int? etapaEdadFin;
  final int etapaFkTipoAnimalId;
  final String etapaSexo;
  final TipoAnimal tipoAnimal;
  final bool? synced;

  Etapa({
    required this.etapaId,
    required this.etapaNombre,
    required this.etapaEdadIni,
    this.etapaEdadFin,
    required this.etapaFkTipoAnimalId,
    required this.etapaSexo,
    required this.tipoAnimal,
    this.synced = false,
  });

  factory Etapa.fromJson(Map<String, dynamic> json) {
    return Etapa(
      etapaId: json['etapa_id'] ?? 0,
      etapaNombre: json['etapa_nombre'] ?? '',
      etapaEdadIni: json['etapa_edad_ini'] ?? 0,
      etapaEdadFin: json['etapa_edad_fin'],
      etapaFkTipoAnimalId: json['etapa_fk_tipo_animal_id'] ?? 0,
      etapaSexo: json['etapa_sexo'] ?? '',
      tipoAnimal: TipoAnimal.fromJson(json['tipo_animal'] ?? {}),
      synced: json['synced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'etapa_id': etapaId,
      'etapa_nombre': etapaNombre,
      'etapa_edad_ini': etapaEdadIni,
      'etapa_edad_fin': etapaEdadFin,
      'etapa_fk_tipo_animal_id': etapaFkTipoAnimalId,
      'etapa_sexo': etapaSexo,
      'tipo_animal': tipoAnimal.toJson(),
      'synced': synced,
    };
  }
}

// Response wrapper classes for paginated APIs
class EstadoSaludResponse {
  final bool success;
  final String message;
  final PaginatedData<EstadoSalud> data;

  EstadoSaludResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory EstadoSaludResponse.fromJson(Map<String, dynamic> json) {
    return EstadoSaludResponse(
      success: json['success'],
      message: json['message'],
      data: PaginatedData.fromJson(
        json['data'],
        (item) => EstadoSalud.fromJson(item),
      ),
    );
  }
}

class TipoAnimalResponse {
  final bool success;
  final String message;
  final PaginatedData<TipoAnimal> data;

  TipoAnimalResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory TipoAnimalResponse.fromJson(Map<String, dynamic> json) {
    return TipoAnimalResponse(
      success: json['success'],
      message: json['message'],
      data: PaginatedData.fromJson(
        json['data'],
        (item) => TipoAnimal.fromJson(item),
      ),
    );
  }
}

// Generic paginated response wrapper
class PaginatedData<T> {
  final int currentPage;
  final List<T> data;
  final int total;
  final int perPage;

  PaginatedData({
    required this.currentPage,
    required this.data,
    required this.total,
    required this.perPage,
  });

  factory PaginatedData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedData<T>(
      currentPage: json['current_page'],
      data: (json['data'] as List).map((item) => fromJsonT(item)).toList(),
      total: json['total'],
      perPage: json['per_page'],
    );
  }
}

// ComposicionRaza model for breed composition data
class ComposicionRaza {
  final int idComposicion;
  final String nombre;
  final String siglas;
  final String pelaje;
  final String proposito;
  final String tipoRaza;
  final String origen;
  final String caracteristicaEspecial;
  final String proporcionRaza;
  final String? createdAt;
  final String? updatedAt;
  final int? fkIdFinca;
  final int? fkTipoAnimalId;
  final bool? synced;

  ComposicionRaza({
    required this.idComposicion,
    required this.nombre,
    required this.siglas,
    required this.pelaje,
    required this.proposito,
    required this.tipoRaza,
    required this.origen,
    required this.caracteristicaEspecial,
    required this.proporcionRaza,
    this.createdAt,
    this.updatedAt,
    this.fkIdFinca,
    this.fkTipoAnimalId,
    this.synced = false,
  });

  factory ComposicionRaza.fromJson(Map<String, dynamic> json) {
    return ComposicionRaza(
      idComposicion: json['id_Composicion'],
      nombre: json['Nombre'],
      siglas: json['Siglas'],
      pelaje: json['Pelaje'],
      proposito: json['Proposito'],
      tipoRaza: json['Tipo_Raza'],
      origen: json['Origen'],
      caracteristicaEspecial: json['Caracteristica_Especial'],
      proporcionRaza: json['Proporcion_Raza'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      fkIdFinca: json['fk_id_Finca'],
      fkTipoAnimalId: json['fk_tipo_animal_id'],
      synced: json['synced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_Composicion': idComposicion,
      'Nombre': nombre,
      'Siglas': siglas,
      'Pelaje': pelaje,
      'Proposito': proposito,
      'Tipo_Raza': tipoRaza,
      'Origen': origen,
      'Caracteristica_Especial': caracteristicaEspecial,
      'Proporcion_Raza': proporcionRaza,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'fk_id_Finca': fkIdFinca,
      'fk_tipo_animal_id': fkTipoAnimalId,
      'synced': synced,
    };
  }
}

// Response wrapper for ComposicionRaza
class ComposicionRazaResponse {
  final bool success;
  final String message;
  final PaginatedData<ComposicionRaza> data;

  ComposicionRazaResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ComposicionRazaResponse.fromJson(Map<String, dynamic> json) {
    return ComposicionRazaResponse(
      success: json['success'],
      message: json['message'],
      data: _createPaginatedDataFromComposicionRazaResponse(json),
    );
  }

  // Helper method to handle the specific structure of composicion-raza API
  static PaginatedData<ComposicionRaza>
  _createPaginatedDataFromComposicionRazaResponse(Map<String, dynamic> json) {
    // Check if data is a List (composicion-raza API format) or Map (standard format)
    if (json['data'] is List) {
      // Handle composicion-raza specific format with separate pagination object
      final dataList = json['data'] as List;
      final pagination = json['pagination'] as Map<String, dynamic>?;

      return PaginatedData<ComposicionRaza>(
        currentPage: pagination?['current_page'] ?? 1,
        data: dataList.map((item) => ComposicionRaza.fromJson(item)).toList(),
        total: pagination?['total'] ?? dataList.length,
        perPage: pagination?['per_page'] ?? dataList.length,
      );
    } else {
      // Handle standard paginated format
      return PaginatedData.fromJson(
        json['data'],
        (item) => ComposicionRaza.fromJson(item),
      );
    }
  }
}

// Simple response wrapper for non-paginated APIs
class SimpleConfigurationResponse<T> {
  final bool success;
  final String message;
  final List<T> data;

  SimpleConfigurationResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SimpleConfigurationResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return SimpleConfigurationResponse<T>(
      success: json['success'],
      message: json['message'],
      data: (json['data'] as List).map((item) => fromJsonT(item)).toList(),
    );
  }
}
