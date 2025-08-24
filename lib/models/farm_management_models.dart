// Models for new farm management entities
import 'animal.dart';
import 'finca.dart';

// Cambio Animal Model
class CambioAnimal {
  final int idCambio;
  final String fechaCambio;
  final String etapaCambio;
  final double peso;
  final double altura;
  final String comentario;
  final String createdAt;
  final String updatedAt;
  final int cambiosEtapaAnid;
  final int cambiosEtapaEtid;

  CambioAnimal({
    required this.idCambio,
    required this.fechaCambio,
    required this.etapaCambio,
    required this.peso,
    required this.altura,
    required this.comentario,
    required this.createdAt,
    required this.updatedAt,
    required this.cambiosEtapaAnid,
    required this.cambiosEtapaEtid,
  });

  factory CambioAnimal.fromJson(Map<String, dynamic> json) {
    return CambioAnimal(
      idCambio: json['id_Cambio'],
      fechaCambio: json['Fecha_Cambio'],
      etapaCambio: json['Etapa_Cambio'],
      peso: (json['Peso'] ?? 0.0).toDouble(),
      altura: (json['Altura'] ?? 0.0).toDouble(),
      comentario: json['Comentario'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      cambiosEtapaAnid: json['cambios_etapa_anid'],
      cambiosEtapaEtid: json['cambios_etapa_etid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Fecha_Cambio': fechaCambio,
      'Etapa_Cambio': etapaCambio,
      'Peso': peso,
      'Altura': altura,
      'Comentario': comentario,
      'cambios_etapa_anid': cambiosEtapaAnid,
      'cambios_etapa_etid': cambiosEtapaEtid,
    };
  }
}

// Lactancia Model
class Lactancia {
  final int lactanciaId;
  final String lactanciaFechaInicio;
  final String? lactanciaFechaFin;
  final String? lactanciaSecado;
  final String createdAt;
  final String updatedAt;
  final int lactanciaEtapaAnid;
  final int lactanciaEtapaEtid;

  Lactancia({
    required this.lactanciaId,
    required this.lactanciaFechaInicio,
    this.lactanciaFechaFin,
    this.lactanciaSecado,
    required this.createdAt,
    required this.updatedAt,
    required this.lactanciaEtapaAnid,
    required this.lactanciaEtapaEtid,
  });

  factory Lactancia.fromJson(Map<String, dynamic> json) {
    return Lactancia(
      lactanciaId: json['lactancia_id'],
      lactanciaFechaInicio: json['lactancia_fecha_inicio'],
      lactanciaFechaFin: json['Lactancia_fecha_fin'],
      lactanciaSecado: json['lactancia_secado'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      lactanciaEtapaAnid: json['lactancia_etapa_anid'],
      lactanciaEtapaEtid: json['lactancia_etapa_etid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lactancia_fecha_inicio': lactanciaFechaInicio,
      'Lactancia_fecha_fin': lactanciaFechaFin,
      'lactancia_secado': lactanciaSecado,
      'lactancia_etapa_anid': lactanciaEtapaAnid,
      'lactancia_etapa_etid': lactanciaEtapaEtid,
    };
  }
}

// Registro Lechero Model
class RegistroLechero {
  final int lecheId;
  final String lecheFechaPesaje;
  final String lechePesajeTotal;
  final String createdAt;
  final String updatedAt;
  final int lecheLactanciaId;

  RegistroLechero({
    required this.lecheId,
    required this.lecheFechaPesaje,
    required this.lechePesajeTotal,
    required this.createdAt,
    required this.updatedAt,
    required this.lecheLactanciaId,
  });

  factory RegistroLechero.fromJson(Map<String, dynamic> json) {
    return RegistroLechero(
      lecheId: json['leche_id'],
      lecheFechaPesaje: json['leche_fecha_pesaje'],
      lechePesajeTotal: json['leche_pesaje_Total'].toString(),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      lecheLactanciaId: json['leche_lactancia_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leche_fecha_pesaje': lecheFechaPesaje,
      'leche_pesaje_Total': double.tryParse(lechePesajeTotal) ?? 0.0,
      'leche_lactancia_id': lecheLactanciaId,
    };
  }
}

// Peso Corporal Model
class PesoCorporal {
  final int idPeso;
  final String fechaPeso;
  final double peso;
  final String comentario;
  final String createdAt;
  final String updatedAt;
  final int pesoEtapaAnid;
  final int pesoEtapaEtid;

  PesoCorporal({
    required this.idPeso,
    required this.fechaPeso,
    required this.peso,
    required this.comentario,
    required this.createdAt,
    required this.updatedAt,
    required this.pesoEtapaAnid,
    required this.pesoEtapaEtid,
  });

  factory PesoCorporal.fromJson(Map<String, dynamic> json) {
    return PesoCorporal(
      idPeso: json['id_Peso'],
      fechaPeso: json['Fecha_Peso'],
      peso: (json['Peso'] ?? 0.0).toDouble(),
      comentario: json['Comentario'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      pesoEtapaAnid: json['peso_etapa_anid'],
      pesoEtapaEtid: json['peso_etapa_etid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Fecha_Peso': fechaPeso,
      'Peso': peso,
      'Comentario': comentario,
      'peso_etapa_anid': pesoEtapaAnid,
      'peso_etapa_etid': pesoEtapaEtid,
    };
  }
}

// Medidas Corporales Model
class MedidasCorporales {
  final int idMedida;
  final double alturaHC;
  final double alturaHG;
  final double perimetroPT;
  final double perimetroPCA;
  final double longitudLC;
  final double longitudLG;
  final double anchuraAG;
  final String createdAt;
  final String updatedAt;
  final int medidaEtapaAnid;
  final int medidaEtapaEtid;

  MedidasCorporales({
    required this.idMedida,
    required this.alturaHC,
    required this.alturaHG,
    required this.perimetroPT,
    required this.perimetroPCA,
    required this.longitudLC,
    required this.longitudLG,
    required this.anchuraAG,
    required this.createdAt,
    required this.updatedAt,
    required this.medidaEtapaAnid,
    required this.medidaEtapaEtid,
  });

  factory MedidasCorporales.fromJson(Map<String, dynamic> json) {
    return MedidasCorporales(
      idMedida: json['id_Medida'],
      alturaHC: (json['Altura_HC'] ?? 0.0).toDouble(),
      alturaHG: (json['Altura_HG'] ?? 0.0).toDouble(),
      perimetroPT: (json['Perimetro_PT'] ?? 0.0).toDouble(),
      perimetroPCA: (json['Perimetro_PCA'] ?? 0.0).toDouble(),
      longitudLC: (json['Longitud_LC'] ?? 0.0).toDouble(),
      longitudLG: (json['Longitud_LG'] ?? 0.0).toDouble(),
      anchuraAG: (json['Anchura_AG'] ?? 0.0).toDouble(),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      medidaEtapaAnid: json['medida_etapa_anid'],
      medidaEtapaEtid: json['medida_etapa_etid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Altura_HC': alturaHC,
      'Altura_HG': alturaHG,
      'Perimetro_PT': perimetroPT,
      'Perimetro_PCA': perimetroPCA,
      'Longitud_LC': longitudLC,
      'Longitud_LG': longitudLG,
      'Anchura_AG': anchuraAG,
      'medida_etapa_anid': medidaEtapaAnid,
      'medida_etapa_etid': medidaEtapaEtid,
    };
  }
}

// Personal Finca Model
class PersonalFinca {
  final int idTecnico;
  final int idFinca;
  final int cedula;
  final String nombre;
  final String apellido;
  final String telefono;
  final String correo;
  final String tipoTrabajador;
  final String createdAt;
  final String updatedAt;
  final Finca? finca;

  PersonalFinca({
    required this.idTecnico,
    required this.idFinca,
    required this.cedula,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.correo,
    required this.tipoTrabajador,
    required this.createdAt,
    required this.updatedAt,
    this.finca,
  });

  factory PersonalFinca.fromJson(Map<String, dynamic> json) {
    return PersonalFinca(
      idTecnico: json['id_Tecnico'],
      idFinca: json['id_Finca'],
      cedula: json['Cedula'],
      nombre: json['Nombre'],
      apellido: json['Apellido'],
      telefono: json['Telefono'],
      correo: json['Correo'],
      tipoTrabajador: json['Tipo_Trabajador'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      finca: json['finca'] != null ? Finca.fromJson(json['finca']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_Finca': idFinca,
      'Cedula': cedula,
      'Nombre': nombre,
      'Apellido': apellido,
      'Telefono': telefono,
      'Correo': correo,
      'Tipo_Trabajador': tipoTrabajador,
    };
  }
}

// Response wrapper classes for paginated APIs
class CambioAnimalResponse {
  final bool success;
  final String message;
  final List<CambioAnimal> cambiosAnimal;

  CambioAnimalResponse({
    required this.success,
    required this.message,
    required this.cambiosAnimal,
  });

  factory CambioAnimalResponse.fromJson(Map<String, dynamic> json) {
    var cambiosData = json['data'] as List;
    List<CambioAnimal> cambiosList = cambiosData.map((i) => CambioAnimal.fromJson(i)).toList();
    
    return CambioAnimalResponse(
      success: json['success'],
      message: json['message'],
      cambiosAnimal: cambiosList,
    );
  }
}

class LactanciaResponse {
  final bool success;
  final String message;
  final List<Lactancia> lactancias;

  LactanciaResponse({
    required this.success,
    required this.message,
    required this.lactancias,
  });

  factory LactanciaResponse.fromJson(Map<String, dynamic> json) {
    var lactanciasData = json['data'] as List;
    List<Lactancia> lactanciasList = lactanciasData.map((i) => Lactancia.fromJson(i)).toList();
    
    return LactanciaResponse(
      success: json['success'],
      message: json['message'],
      lactancias: lactanciasList,
    );
  }
}

class RegistroLecheroResponse {
  final bool success;
  final String message;
  final List<RegistroLechero> registrosLecheros;

  RegistroLecheroResponse({
    required this.success,
    required this.message,
    required this.registrosLecheros,
  });

  factory RegistroLecheroResponse.fromJson(Map<String, dynamic> json) {
    var registrosData = json['data'] as List;
    List<RegistroLechero> registrosList = registrosData.map((i) => RegistroLechero.fromJson(i)).toList();
    
    return RegistroLecheroResponse(
      success: json['success'],
      message: json['message'],
      registrosLecheros: registrosList,
    );
  }
}

class PesoCorporalResponse {
  final bool success;
  final String message;
  final List<PesoCorporal> pesosCorporales;

  PesoCorporalResponse({
    required this.success,
    required this.message,
    required this.pesosCorporales,
  });

  factory PesoCorporalResponse.fromJson(Map<String, dynamic> json) {
    var pesosData = json['data'] as List;
    List<PesoCorporal> pesosList = pesosData.map((i) => PesoCorporal.fromJson(i)).toList();
    
    return PesoCorporalResponse(
      success: json['success'],
      message: json['message'],
      pesosCorporales: pesosList,
    );
  }
}

class MedidasCorporalesResponse {
  final bool success;
  final String message;
  final List<MedidasCorporales> medidasCorporales;

  MedidasCorporalesResponse({
    required this.success,
    required this.message,
    required this.medidasCorporales,
  });

  factory MedidasCorporalesResponse.fromJson(Map<String, dynamic> json) {
    var medidasData = json['data'] as List;
    List<MedidasCorporales> medidasList = medidasData.map((i) => MedidasCorporales.fromJson(i)).toList();
    
    return MedidasCorporalesResponse(
      success: json['success'],
      message: json['message'],
      medidasCorporales: medidasList,
    );
  }
}

class PersonalFincaResponse {
  final bool success;
  final String message;
  final List<PersonalFinca> personalFinca;

  PersonalFincaResponse({
    required this.success,
    required this.message,
    required this.personalFinca,
  });

  factory PersonalFincaResponse.fromJson(Map<String, dynamic> json) {
    var personalData = json['data'] as List;
    List<PersonalFinca> personalList = personalData.map((i) => PersonalFinca.fromJson(i)).toList();
    
    return PersonalFincaResponse(
      success: json['success'],
      message: json['message'],
      personalFinca: personalList,
    );
  }
}