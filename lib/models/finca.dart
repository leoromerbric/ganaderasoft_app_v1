class Propietario {
  final int id;
  final int idPersonal;
  final String nombre;
  final String apellido;
  final String telefono;
  final bool archivado;

  Propietario({
    required this.id,
    required this.idPersonal,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.archivado,
  });

  factory Propietario.fromJson(Map<String, dynamic> json) {
    return Propietario(
      id: json['id'],
      idPersonal: json['id_Personal'],
      nombre: json['Nombre'],
      apellido: json['Apellido'],
      telefono: json['Telefono'],
      archivado: json['archivado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_Personal': idPersonal,
      'Nombre': nombre,
      'Apellido': apellido,
      'Telefono': telefono,
      'archivado': archivado,
    };
  }
}

class Finca {
  final int idFinca;
  final int idPropietario;
  final String nombre;
  final String explotacionTipo;
  final bool archivado;
  final String createdAt;
  final String updatedAt;
  final Propietario? propietario;

  Finca({
    required this.idFinca,
    required this.idPropietario,
    required this.nombre,
    required this.explotacionTipo,
    required this.archivado,
    required this.createdAt,
    required this.updatedAt,
    this.propietario,
  });

  factory Finca.fromJson(Map<String, dynamic> json) {
    return Finca(
      idFinca: json['id_Finca'],
      idPropietario: json['id_Propietario'],
      nombre: json['Nombre'],
      explotacionTipo: json['Explotacion_Tipo'],
      archivado: json['archivado'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      propietario: json['propietario'] != null 
          ? Propietario.fromJson(json['propietario']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_Finca': idFinca,
      'id_Propietario': idPropietario,
      'Nombre': nombre,
      'Explotacion_Tipo': explotacionTipo,
      'archivado': archivado,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'propietario': propietario?.toJson(),
    };
  }
}

class FincasResponse {
  final bool success;
  final String message;
  final List<Finca> fincas;

  FincasResponse({
    required this.success,
    required this.message,
    required this.fincas,
  });

  factory FincasResponse.fromJson(Map<String, dynamic> json) {
    var fincasData = json['data']['data'] as List;
    List<Finca> fincasList = fincasData.map((i) => Finca.fromJson(i)).toList();
    
    return FincasResponse(
      success: json['success'],
      message: json['message'],
      fincas: fincasList,
    );
  }
}