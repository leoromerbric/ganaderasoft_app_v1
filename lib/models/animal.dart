import 'finca.dart';
import 'configuration_models.dart';

class Animal {
  final int idAnimal;
  final int idRebano;
  final String nombre;
  final String codigoAnimal;
  final String sexo;
  final String fechaNacimiento;
  final String procedencia;
  final bool archivado;
  final String createdAt;
  final String updatedAt;
  final int fkComposicionRaza;
  final Rebano? rebano;
  final ComposicionRaza? composicionRaza;

  Animal({
    required this.idAnimal,
    required this.idRebano,
    required this.nombre,
    required this.codigoAnimal,
    required this.sexo,
    required this.fechaNacimiento,
    required this.procedencia,
    required this.archivado,
    required this.createdAt,
    required this.updatedAt,
    required this.fkComposicionRaza,
    this.rebano,
    this.composicionRaza,
  });

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      idAnimal: json['id_Animal'],
      idRebano: json['id_Rebano'],
      nombre: json['Nombre'],
      codigoAnimal: json['codigo_animal'],
      sexo: json['Sexo'],
      fechaNacimiento: json['fecha_nacimiento'],
      procedencia: json['Procedencia'],
      archivado: json['archivado'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      fkComposicionRaza: json['fk_composicion_raza'],
      rebano: json['rebano'] != null ? Rebano.fromJson(json['rebano']) : null,
      composicionRaza: json['composicion_raza'] != null 
          ? ComposicionRaza.fromJson(json['composicion_raza']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_Animal': idAnimal,
      'id_Rebano': idRebano,
      'Nombre': nombre,
      'codigo_animal': codigoAnimal,
      'Sexo': sexo,
      'fecha_nacimiento': fechaNacimiento,
      'Procedencia': procedencia,
      'archivado': archivado,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'fk_composicion_raza': fkComposicionRaza,
      'rebano': rebano?.toJson(),
      'composicion_raza': composicionRaza?.toJson(),
    };
  }
}

class Rebano {
  final int idRebano;
  final int idFinca;
  final String nombre;
  final bool archivado;
  final String createdAt;
  final String updatedAt;
  final Finca? finca;
  final List<Animal>? animales;

  Rebano({
    required this.idRebano,
    required this.idFinca,
    required this.nombre,
    required this.archivado,
    required this.createdAt,
    required this.updatedAt,
    this.finca,
    this.animales,
  });

  factory Rebano.fromJson(Map<String, dynamic> json) {
    List<Animal>? animalesList;
    if (json['animales'] != null) {
      var animalesData = json['animales'] as List;
      animalesList = animalesData.map((i) => Animal.fromJson(i)).toList();
    }

    return Rebano(
      idRebano: json['id_Rebano'],
      idFinca: json['id_Finca'],
      nombre: json['Nombre'],
      archivado: json['archivado'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      finca: json['finca'] != null ? Finca.fromJson(json['finca']) : null,
      animales: animalesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_Rebano': idRebano,
      'id_Finca': idFinca,
      'Nombre': nombre,
      'archivado': archivado,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'finca': finca?.toJson(),
      'animales': animales?.map((e) => e.toJson()).toList(),
    };
  }
}

class AnimalesResponse {
  final bool success;
  final String message;
  final List<Animal> animales;

  AnimalesResponse({
    required this.success,
    required this.message,
    required this.animales,
  });

  factory AnimalesResponse.fromJson(Map<String, dynamic> json) {
    var animalesData = json['data']['data'] as List;
    List<Animal> animalesList = animalesData.map((i) => Animal.fromJson(i)).toList();
    
    return AnimalesResponse(
      success: json['success'],
      message: json['message'],
      animales: animalesList,
    );
  }
}

class RebanosResponse {
  final bool success;
  final String message;
  final List<Rebano> rebanos;

  RebanosResponse({
    required this.success,
    required this.message,
    required this.rebanos,
  });

  factory RebanosResponse.fromJson(Map<String, dynamic> json) {
    var rebanosData = json['data']['data'] as List;
    List<Rebano> rebanosList = rebanosData.map((i) => Rebano.fromJson(i)).toList();
    
    return RebanosResponse(
      success: json['success'],
      message: json['message'],
      rebanos: rebanosList,
    );
  }
}

// EtapaAnimal model for animal-stage relationship
class EtapaAnimal {
  final int etanEtapaId;
  final int etanAnimalId;
  final String etanFechaIni;
  final String? etanFechaFin;
  final Etapa etapa;

  EtapaAnimal({
    required this.etanEtapaId,
    required this.etanAnimalId,
    required this.etanFechaIni,
    this.etanFechaFin,
    required this.etapa,
  });

  factory EtapaAnimal.fromJson(Map<String, dynamic> json) {
    return EtapaAnimal(
      etanEtapaId: json['etan_etapa_id'],
      etanAnimalId: json['etan_animal_id'],
      etanFechaIni: json['etan_fecha_ini'],
      etanFechaFin: json['etan_fecha_fin'],
      etapa: Etapa.fromJson(json['etapa'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'etan_etapa_id': etanEtapaId,
      'etan_animal_id': etanAnimalId,
      'etan_fecha_ini': etanFechaIni,
      'etan_fecha_fin': etanFechaFin,
      'etapa': etapa.toJson(),
    };
  }
}

// EstadoAnimal model for animal health status
class EstadoAnimal {
  final int esanId;
  final String esanFechaIni;
  final String? esanFechaFin;
  final int esanFkEstadoId;
  final int esanFkIdAnimal;
  final EstadoSalud estadoSalud;

  EstadoAnimal({
    required this.esanId,
    required this.esanFechaIni,
    this.esanFechaFin,
    required this.esanFkEstadoId,
    required this.esanFkIdAnimal,
    required this.estadoSalud,
  });

  factory EstadoAnimal.fromJson(Map<String, dynamic> json) {
    return EstadoAnimal(
      esanId: json['esan_id'] ?? 0,
      esanFechaIni: json['esan_fecha_ini'] ?? '',
      esanFechaFin: json['esan_fecha_fin'],
      esanFkEstadoId: json['esan_fk_estado_id'] ?? 0,
      esanFkIdAnimal: json['esan_fk_id_animal'] ?? 0,
      estadoSalud: EstadoSalud.fromJson(json['estado_salud'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'esan_id': esanId,
      'esan_fecha_ini': esanFechaIni,
      'esan_fecha_fin': esanFechaFin,
      'esan_fk_estado_id': esanFkEstadoId,
      'esan_fk_id_animal': esanFkIdAnimal,
      'estado_salud': estadoSalud.toJson(),
    };
  }
}

// AnimalDetail model for complete animal information including stages
class AnimalDetail extends Animal {
  final List<EstadoAnimal> estados;
  final List<EtapaAnimal> etapaAnimales;
  final EtapaAnimal? etapaActual;

  AnimalDetail({
    required super.idAnimal,
    required super.idRebano,
    required super.nombre,
    required super.codigoAnimal,
    required super.sexo,
    required super.fechaNacimiento,
    required super.procedencia,
    required super.archivado,
    required super.createdAt,
    required super.updatedAt,
    required super.fkComposicionRaza,
    super.rebano,
    super.composicionRaza,
    required this.estados,
    required this.etapaAnimales,
    this.etapaActual,
  });

  factory AnimalDetail.fromJson(Map<String, dynamic> json) {
    // Parse estados
    List<EstadoAnimal> estadosList = [];
    if (json['estados'] != null) {
      var estadosData = json['estados'] as List;
      estadosList = estadosData.map((i) => EstadoAnimal.fromJson(i)).toList();
    }

    // Parse etapa_animales
    List<EtapaAnimal> etapaAnimalesList = [];
    if (json['etapa_animales'] != null) {
      var etapaAnimalesData = json['etapa_animales'] as List;
      etapaAnimalesList = etapaAnimalesData.map((i) => EtapaAnimal.fromJson(i)).toList();
    }

    // Parse etapa_actual
    EtapaAnimal? etapaActual;
    if (json['etapa_actual'] != null) {
      etapaActual = EtapaAnimal.fromJson(json['etapa_actual']);
    }

    return AnimalDetail(
      idAnimal: json['id_Animal'],
      idRebano: json['id_Rebano'],
      nombre: json['Nombre'],
      codigoAnimal: json['codigo_animal'],
      sexo: json['Sexo'],
      fechaNacimiento: json['fecha_nacimiento'],
      procedencia: json['Procedencia'],
      archivado: json['archivado'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      fkComposicionRaza: json['fk_composicion_raza'],
      rebano: json['rebano'] != null ? Rebano.fromJson(json['rebano']) : null,
      composicionRaza: json['composicion_raza'] != null 
          ? ComposicionRaza.fromJson(json['composicion_raza']) 
          : null,
      estados: estadosList,
      etapaAnimales: etapaAnimalesList,
      etapaActual: etapaActual,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_Animal': idAnimal,
      'id_Rebano': idRebano,
      'Nombre': nombre,
      'codigo_animal': codigoAnimal,
      'Sexo': sexo,
      'fecha_nacimiento': fechaNacimiento,
      'Procedencia': procedencia,
      'archivado': archivado,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'fk_composicion_raza': fkComposicionRaza,
      'rebano': rebano?.toJson(),
      'composicion_raza': composicionRaza?.toJson(),
      'estados': estados.map((e) => e.toJson()).toList(),
      'etapa_animales': etapaAnimales.map((e) => e.toJson()).toList(),
      'etapa_actual': etapaActual?.toJson(),
    };
  }
}

// Response wrapper for animal detail
class AnimalDetailResponse {
  final bool success;
  final String message;
  final AnimalDetail data;

  AnimalDetailResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AnimalDetailResponse.fromJson(Map<String, dynamic> json) {
    return AnimalDetailResponse(
      success: json['success'],
      message: json['message'],
      data: AnimalDetail.fromJson(json['data']),
    );
  }
}