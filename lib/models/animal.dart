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