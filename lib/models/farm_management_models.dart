// Models for new farm management entities
import 'animal.dart';
import 'finca.dart';

// Cambio Animal Model
class CambioAnimal {
  final int idCambio;
  final int idAnimal;
  final String fechaCambio;
  final String tipoCambio;
  final String valorAnterior;
  final String valorNuevo;
  final String? observaciones;
  final String createdAt;
  final String updatedAt;
  final Animal? animal;

  CambioAnimal({
    required this.idCambio,
    required this.idAnimal,
    required this.fechaCambio,
    required this.tipoCambio,
    required this.valorAnterior,
    required this.valorNuevo,
    this.observaciones,
    required this.createdAt,
    required this.updatedAt,
    this.animal,
  });

  factory CambioAnimal.fromJson(Map<String, dynamic> json) {
    return CambioAnimal(
      idCambio: json['id_cambio'],
      idAnimal: json['id_animal'],
      fechaCambio: json['fecha_cambio'],
      tipoCambio: json['tipo_cambio'],
      valorAnterior: json['valor_anterior'],
      valorNuevo: json['valor_nuevo'],
      observaciones: json['observaciones'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      animal: json['animal'] != null ? Animal.fromJson(json['animal']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_cambio': idCambio,
      'id_animal': idAnimal,
      'fecha_cambio': fechaCambio,
      'tipo_cambio': tipoCambio,
      'valor_anterior': valorAnterior,
      'valor_nuevo': valorNuevo,
      'observaciones': observaciones,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

// Lactancia Model
class Lactancia {
  final int idLactancia;
  final int idAnimal;
  final String fechaInicio;
  final String? fechaFin;
  final int numeroLactancia;
  final int diasLactancia;
  final double produccionDiariaPromedio;
  final String? observaciones;
  final bool activa;
  final String createdAt;
  final String updatedAt;
  final Animal? animal;

  Lactancia({
    required this.idLactancia,
    required this.idAnimal,
    required this.fechaInicio,
    this.fechaFin,
    required this.numeroLactancia,
    required this.diasLactancia,
    required this.produccionDiariaPromedio,
    this.observaciones,
    required this.activa,
    required this.createdAt,
    required this.updatedAt,
    this.animal,
  });

  factory Lactancia.fromJson(Map<String, dynamic> json) {
    return Lactancia(
      idLactancia: json['id_lactancia'],
      idAnimal: json['id_animal'],
      fechaInicio: json['fecha_inicio'],
      fechaFin: json['fecha_fin'],
      numeroLactancia: json['numero_lactancia'],
      diasLactancia: json['dias_lactancia'],
      produccionDiariaPromedio: (json['produccion_diaria_promedio'] ?? 0.0).toDouble(),
      observaciones: json['observaciones'],
      activa: json['activa'] ?? true,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      animal: json['animal'] != null ? Animal.fromJson(json['animal']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_lactancia': idLactancia,
      'id_animal': idAnimal,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      'numero_lactancia': numeroLactancia,
      'dias_lactancia': diasLactancia,
      'produccion_diaria_promedio': produccionDiariaPromedio,
      'observaciones': observaciones,
      'activa': activa,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

// Registro Lechero Model
class RegistroLechero {
  final int idRegistro;
  final int idAnimal;
  final String fechaRegistro;
  final double cantidadManana;
  final double cantidadTarde;
  final double cantidadTotal;
  final String? observaciones;
  final String createdAt;
  final String updatedAt;
  final Animal? animal;

  RegistroLechero({
    required this.idRegistro,
    required this.idAnimal,
    required this.fechaRegistro,
    required this.cantidadManana,
    required this.cantidadTarde,
    required this.cantidadTotal,
    this.observaciones,
    required this.createdAt,
    required this.updatedAt,
    this.animal,
  });

  factory RegistroLechero.fromJson(Map<String, dynamic> json) {
    return RegistroLechero(
      idRegistro: json['id_registro'],
      idAnimal: json['id_animal'],
      fechaRegistro: json['fecha_registro'],
      cantidadManana: (json['cantidad_manana'] ?? 0.0).toDouble(),
      cantidadTarde: (json['cantidad_tarde'] ?? 0.0).toDouble(),
      cantidadTotal: (json['cantidad_total'] ?? 0.0).toDouble(),
      observaciones: json['observaciones'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      animal: json['animal'] != null ? Animal.fromJson(json['animal']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_registro': idRegistro,
      'id_animal': idAnimal,
      'fecha_registro': fechaRegistro,
      'cantidad_manana': cantidadManana,
      'cantidad_tarde': cantidadTarde,
      'cantidad_total': cantidadTotal,
      'observaciones': observaciones,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

// Peso Corporal Model
class PesoCorporal {
  final int idPeso;
  final int idAnimal;
  final String fechaRegistro;
  final double pesoKg;
  final String metodoMedicion;
  final String? observaciones;
  final String createdAt;
  final String updatedAt;
  final Animal? animal;

  PesoCorporal({
    required this.idPeso,
    required this.idAnimal,
    required this.fechaRegistro,
    required this.pesoKg,
    required this.metodoMedicion,
    this.observaciones,
    required this.createdAt,
    required this.updatedAt,
    this.animal,
  });

  factory PesoCorporal.fromJson(Map<String, dynamic> json) {
    return PesoCorporal(
      idPeso: json['id_peso'],
      idAnimal: json['id_animal'],
      fechaRegistro: json['fecha_registro'],
      pesoKg: (json['peso_kg'] ?? 0.0).toDouble(),
      metodoMedicion: json['metodo_medicion'],
      observaciones: json['observaciones'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      animal: json['animal'] != null ? Animal.fromJson(json['animal']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_peso': idPeso,
      'id_animal': idAnimal,
      'fecha_registro': fechaRegistro,
      'peso_kg': pesoKg,
      'metodo_medicion': metodoMedicion,
      'observaciones': observaciones,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

// Medidas Corporales Model
class MedidasCorporales {
  final int idMedida;
  final int idAnimal;
  final String fechaRegistro;
  final double alturaCruzCm;
  final double largoCuerpoCm;
  final double perimetroToracicoCm;
  final double anchoCaderaCm;
  final String? observaciones;
  final String createdAt;
  final String updatedAt;
  final Animal? animal;

  MedidasCorporales({
    required this.idMedida,
    required this.idAnimal,
    required this.fechaRegistro,
    required this.alturaCruzCm,
    required this.largoCuerpoCm,
    required this.perimetroToracicoCm,
    required this.anchoCaderaCm,
    this.observaciones,
    required this.createdAt,
    required this.updatedAt,
    this.animal,
  });

  factory MedidasCorporales.fromJson(Map<String, dynamic> json) {
    return MedidasCorporales(
      idMedida: json['id_medida'],
      idAnimal: json['id_animal'],
      fechaRegistro: json['fecha_registro'],
      alturaCruzCm: (json['altura_cruz_cm'] ?? 0.0).toDouble(),
      largoCuerpoCm: (json['largo_cuerpo_cm'] ?? 0.0).toDouble(),
      perimetroToracicoCm: (json['perimetro_toracico_cm'] ?? 0.0).toDouble(),
      anchoCaderaCm: (json['ancho_cadera_cm'] ?? 0.0).toDouble(),
      observaciones: json['observaciones'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      animal: json['animal'] != null ? Animal.fromJson(json['animal']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_medida': idMedida,
      'id_animal': idAnimal,
      'fecha_registro': fechaRegistro,
      'altura_cruz_cm': alturaCruzCm,
      'largo_cuerpo_cm': largoCuerpoCm,
      'perimetro_toracico_cm': perimetroToracicoCm,
      'ancho_cadera_cm': anchoCaderaCm,
      'observaciones': observaciones,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

// Personal Finca Model
class PersonalFinca {
  final int idPersonal;
  final int idFinca;
  final String nombre;
  final String apellido;
  final String cargo;
  final String telefono;
  final String? email;
  final String fechaIngreso;
  final double salario;
  final bool activo;
  final String? observaciones;
  final String createdAt;
  final String updatedAt;
  final Finca? finca;

  PersonalFinca({
    required this.idPersonal,
    required this.idFinca,
    required this.nombre,
    required this.apellido,
    required this.cargo,
    required this.telefono,
    this.email,
    required this.fechaIngreso,
    required this.salario,
    required this.activo,
    this.observaciones,
    required this.createdAt,
    required this.updatedAt,
    this.finca,
  });

  factory PersonalFinca.fromJson(Map<String, dynamic> json) {
    return PersonalFinca(
      idPersonal: json['id_personal'],
      idFinca: json['id_finca'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      cargo: json['cargo'],
      telefono: json['telefono'],
      email: json['email'],
      fechaIngreso: json['fecha_ingreso'],
      salario: (json['salario'] ?? 0.0).toDouble(),
      activo: json['activo'] ?? true,
      observaciones: json['observaciones'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      finca: json['finca'] != null ? Finca.fromJson(json['finca']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_personal': idPersonal,
      'id_finca': idFinca,
      'nombre': nombre,
      'apellido': apellido,
      'cargo': cargo,
      'telefono': telefono,
      'email': email,
      'fecha_ingreso': fechaIngreso,
      'salario': salario,
      'activo': activo,
      'observaciones': observaciones,
      'created_at': createdAt,
      'updated_at': updatedAt,
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
    var cambiosData = json['data']['data'] as List;
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
    var lactanciasData = json['data']['data'] as List;
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
    var registrosData = json['data']['data'] as List;
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
    var pesosData = json['data']['data'] as List;
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
    var medidasData = json['data']['data'] as List;
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
    var personalData = json['data']['data'] as List;
    List<PersonalFinca> personalList = personalData.map((i) => PersonalFinca.fromJson(i)).toList();
    
    return PersonalFincaResponse(
      success: json['success'],
      message: json['message'],
      personalFinca: personalList,
    );
  }
}