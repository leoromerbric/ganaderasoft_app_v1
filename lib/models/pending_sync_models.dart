import 'animal.dart';
import 'farm_management_models.dart';

// Enum for pending operations
enum PendingOperation {
  create,
  update,
  delete,
}

extension PendingOperationExtension on PendingOperation {
  String get value {
    switch (this) {
      case PendingOperation.create:
        return 'CREATE';
      case PendingOperation.update:
        return 'UPDATE';
      case PendingOperation.delete:
        return 'DELETE';
    }
  }

  static PendingOperation fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CREATE':
        return PendingOperation.create;
      case 'UPDATE':
        return PendingOperation.update;
      case 'DELETE':
        return PendingOperation.delete;
      default:
        return PendingOperation.create;
    }
  }
}

// Enhanced Animal model with sync status
class PendingAnimal extends Animal {
  final bool synced;
  final bool isPending;
  final PendingOperation? pendingOperation;
  final int? estadoId;
  final int? etapaId;

  PendingAnimal({
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
    this.synced = true,
    this.isPending = false,
    this.pendingOperation,
    this.estadoId,
    this.etapaId,
  });

  factory PendingAnimal.fromAnimal(
    Animal animal, {
    bool synced = true,
    bool isPending = false,
    PendingOperation? pendingOperation,
    int? estadoId,
    int? etapaId,
  }) {
    return PendingAnimal(
      idAnimal: animal.idAnimal,
      idRebano: animal.idRebano,
      nombre: animal.nombre,
      codigoAnimal: animal.codigoAnimal,
      sexo: animal.sexo,
      fechaNacimiento: animal.fechaNacimiento,
      procedencia: animal.procedencia,
      archivado: animal.archivado,
      createdAt: animal.createdAt,
      updatedAt: animal.updatedAt,
      fkComposicionRaza: animal.fkComposicionRaza,
      rebano: animal.rebano,
      composicionRaza: animal.composicionRaza,
      synced: synced,
      isPending: isPending,
      pendingOperation: pendingOperation,
      estadoId: estadoId,
      etapaId: etapaId,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'synced': synced,
      'is_pending': isPending,
      'pending_operation': pendingOperation?.value,
      'estado_id': estadoId,
      'etapa_id': etapaId,
    });
    return json;
  }

  // Method to create a regular Animal from PendingAnimal
  Animal toAnimal() {
    return Animal(
      idAnimal: idAnimal,
      idRebano: idRebano,
      nombre: nombre,
      codigoAnimal: codigoAnimal,
      sexo: sexo,
      fechaNacimiento: fechaNacimiento,
      procedencia: procedencia,
      archivado: archivado,
      createdAt: createdAt,
      updatedAt: updatedAt,
      fkComposicionRaza: fkComposicionRaza,
      rebano: rebano,
      composicionRaza: composicionRaza,
    );
  }
}

// Base class for pending sync records
abstract class PendingSyncRecord {
  final String entityType;
  final int? entityId;
  final String entityName;
  final PendingOperation operation;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  PendingSyncRecord({
    required this.entityType,
    this.entityId,
    required this.entityName,
    required this.operation,
    required this.createdAt,
    required this.data,
  });
}

// Pending Animal sync record
class PendingAnimalSync extends PendingSyncRecord {
  final PendingAnimal animal;

  PendingAnimalSync({
    required this.animal,
    required super.operation,
    required super.createdAt,
  }) : super(
          entityType: 'Animal',
          entityId: animal.idAnimal,
          entityName: animal.nombre,
          data: animal.toJson(),
        );
}

// Pending Cambios Animal sync record
class PendingCambiosAnimalSync extends PendingSyncRecord {
  final CambiosAnimal cambiosAnimal;

  PendingCambiosAnimalSync({
    required this.cambiosAnimal,
    required super.operation,
    required super.createdAt,
  }) : super(
          entityType: 'CambiosAnimal',
          entityId: cambiosAnimal.idCambio,
          entityName: 'Cambio Animal ${cambiosAnimal.idCambio}',
          data: cambiosAnimal.toJson(),
        );
}

// Pending Personal Finca sync record
class PendingPersonalFincaSync extends PendingSyncRecord {
  final PersonalFinca personalFinca;

  PendingPersonalFincaSync({
    required this.personalFinca,
    required super.operation,
    required super.createdAt,
  }) : super(
          entityType: 'PersonalFinca',
          entityId: personalFinca.idTecnico,
          entityName: '${personalFinca.nombre} ${personalFinca.apellido}',
          data: personalFinca.toJson(),
        );
}