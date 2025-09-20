import 'dart:convert';

/// Enum for sync audit actions
enum SyncAuditAction {
  syncSuccess,
  syncSkipped,
  conflictResolved,
  localNewer,
  serverNewer,
}

extension SyncAuditActionExtension on SyncAuditAction {
  String get value {
    switch (this) {
      case SyncAuditAction.syncSuccess:
        return 'SYNC_SUCCESS';
      case SyncAuditAction.syncSkipped:
        return 'SYNC_SKIPPED';
      case SyncAuditAction.conflictResolved:
        return 'CONFLICT_RESOLVED';
      case SyncAuditAction.localNewer:
        return 'LOCAL_NEWER';
      case SyncAuditAction.serverNewer:
        return 'SERVER_NEWER';
    }
  }

  static SyncAuditAction fromString(String value) {
    switch (value.toUpperCase()) {
      case 'SYNC_SUCCESS':
        return SyncAuditAction.syncSuccess;
      case 'SYNC_SKIPPED':
        return SyncAuditAction.syncSkipped;
      case 'CONFLICT_RESOLVED':
        return SyncAuditAction.conflictResolved;
      case 'LOCAL_NEWER':
        return SyncAuditAction.localNewer;
      case 'SERVER_NEWER':
        return SyncAuditAction.serverNewer;
      default:
        return SyncAuditAction.syncSuccess;
    }
  }
}

/// Model for sync audit records
class SyncAuditRecord {
  final int? id;
  final String entityType;
  final int? entityId;
  final String entityName;
  final SyncAuditAction action;
  final DateTime syncTimestamp;
  final DateTime? localTimestamp;
  final DateTime? serverTimestamp;
  final String? conflictReason;
  final Map<String, dynamic>? conflictData;
  final String? resolution;

  SyncAuditRecord({
    this.id,
    required this.entityType,
    this.entityId,
    required this.entityName,
    required this.action,
    required this.syncTimestamp,
    this.localTimestamp,
    this.serverTimestamp,
    this.conflictReason,
    this.conflictData,
    this.resolution,
  });

  factory SyncAuditRecord.fromJson(Map<String, dynamic> json) {
    return SyncAuditRecord(
      id: json['id'],
      entityType: json['entity_type'],
      entityId: json['entity_id'],
      entityName: json['entity_name'],
      action: SyncAuditActionExtension.fromString(json['action']),
      syncTimestamp: DateTime.fromMillisecondsSinceEpoch(json['sync_timestamp']),
      localTimestamp: json['local_timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['local_timestamp'])
          : null,
      serverTimestamp: json['server_timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['server_timestamp'])
          : null,
      conflictReason: json['conflict_reason'],
      conflictData: json['conflict_data'] != null 
          ? jsonDecode(json['conflict_data'])
          : null,
      resolution: json['resolution'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'entity_name': entityName,
      'action': action.value,
      'sync_timestamp': syncTimestamp.millisecondsSinceEpoch,
      'local_timestamp': localTimestamp?.millisecondsSinceEpoch,
      'server_timestamp': serverTimestamp?.millisecondsSinceEpoch,
      'conflict_reason': conflictReason,
      'conflict_data': conflictData != null ? jsonEncode(conflictData) : null,
      'resolution': resolution,
    };
  }

  /// Create an audit record for successful sync
  static SyncAuditRecord syncSuccess({
    required String entityType,
    int? entityId,
    required String entityName,
    DateTime? serverTimestamp,
  }) {
    return SyncAuditRecord(
      entityType: entityType,
      entityId: entityId,
      entityName: entityName,
      action: SyncAuditAction.syncSuccess,
      syncTimestamp: DateTime.now().toUtc(),
      serverTimestamp: serverTimestamp?.toUtc(),
    );
  }

  /// Create an audit record for sync skipped due to newer local data
  static SyncAuditRecord localNewer({
    required String entityType,
    int? entityId,
    required String entityName,
    required DateTime localTimestamp,
    required DateTime serverTimestamp,
    String? reason,
  }) {
    return SyncAuditRecord(
      entityType: entityType,
      entityId: entityId,
      entityName: entityName,
      action: SyncAuditAction.localNewer,
      syncTimestamp: DateTime.now().toUtc(),
      localTimestamp: localTimestamp.toUtc(),
      serverTimestamp: serverTimestamp.toUtc(),
      conflictReason: reason ?? 'Local data is newer than server data',
      resolution: 'Kept local data, skipped server sync',
    );
  }

  /// Create an audit record for server data being newer
  static SyncAuditRecord serverNewer({
    required String entityType,
    int? entityId,
    required String entityName,
    required DateTime localTimestamp,
    required DateTime serverTimestamp,
    String? reason,
  }) {
    return SyncAuditRecord(
      entityType: entityType,
      entityId: entityId,
      entityName: entityName,
      action: SyncAuditAction.serverNewer,
      syncTimestamp: DateTime.now().toUtc(),
      localTimestamp: localTimestamp.toUtc(),
      serverTimestamp: serverTimestamp.toUtc(),
      conflictReason: reason ?? 'Server data is newer than local data',
      resolution: 'Updated local data with server data',
    );
  }
}