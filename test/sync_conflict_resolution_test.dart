import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:ganaderasoft_app_v1/services/utc_timestamp_helper.dart';
import 'package:ganaderasoft_app_v1/models/sync_audit_models.dart';
import 'package:ganaderasoft_app_v1/models/animal.dart';
import 'package:ganaderasoft_app_v1/models/farm_management_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Sync Conflict Resolution Tests', () {
    test('UTC timestamp helper works correctly', () {
      // Test current UTC timestamp
      final currentUtc = UtcTimestampHelper.getCurrentUtcTimestamp();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      expect(currentUtc, closeTo(now, 1000)); // Within 1 second

      // Test server timestamp parsing
      final serverTimestamp = '2024-01-15T10:30:00.000Z';
      final parsed = UtcTimestampHelper.parseServerTimestamp(serverTimestamp);
      expect(parsed, isNotNull);
      expect(parsed!.year, equals(2024));
      expect(parsed.month, equals(1));
      expect(parsed.day, equals(15));
      expect(parsed.hour, equals(10));
      expect(parsed.minute, equals(30));

      // Test local timestamp parsing
      final localMs = DateTime.utc(2024, 1, 15, 12, 0, 0).millisecondsSinceEpoch;
      final localParsed = UtcTimestampHelper.parseLocalTimestamp(localMs);
      expect(localParsed, isNotNull);
      expect(localParsed!.hour, equals(12));

      // Test timestamp comparison
      final earlier = DateTime.utc(2024, 1, 15, 10, 0, 0);
      final later = DateTime.utc(2024, 1, 15, 12, 0, 0);
      expect(UtcTimestampHelper.isLocalNewer(later, earlier), isTrue);
      expect(UtcTimestampHelper.isLocalNewer(earlier, later), isFalse);
    });

    test('sync audit records can be saved and retrieved', () async {
      print('=== Testing Sync Audit Records ===');

      // Create a sync audit record
      final auditRecord = SyncAuditRecord.localNewer(
        entityType: 'Animal',
        entityId: 123,
        entityName: 'Test Animal',
        localTimestamp: DateTime.utc(2024, 1, 15, 12, 0, 0),
        serverTimestamp: DateTime.utc(2024, 1, 15, 10, 0, 0),
        reason: 'Local data is newer for testing',
      );

      // Save the record
      await DatabaseService.saveSyncAuditRecord(auditRecord);
      print('   Saved sync audit record: ${auditRecord.entityName}');

      // Retrieve the records
      final records = await DatabaseService.getSyncAuditRecords(limit: 10);
      expect(records.length, greaterThan(0));
      
      final savedRecord = records.first;
      expect(savedRecord.entityType, equals('Animal'));
      expect(savedRecord.entityId, equals(123));
      expect(savedRecord.entityName, equals('Test Animal'));
      expect(savedRecord.action, equals(SyncAuditAction.localNewer));
      expect(savedRecord.conflictReason, contains('Local data is newer'));

      print('   Retrieved ${records.length} audit records successfully');
    });

    test('animal sync with conflict resolution - local newer', () async {
      print('=== Testing Animal Sync Conflict Resolution (Local Newer) ===');

      // Step 1: Create a local animal (simulating offline modification)
      print('Step 1: Creating local animal with recent timestamp...');
      await DatabaseService.savePendingAnimalUpdateOffline(
        idAnimal: 456,
        idRebano: 1,
        nombre: 'Test Animal Conflict',
        codigoAnimal: 'CONFLICT-001',
        sexo: 'M',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      // Step 2: Simulate server animal with older timestamp
      print('Step 2: Simulating server sync with older timestamp...');
      final olderServerTime = DateTime.now().subtract(const Duration(hours: 2));
      final serverAnimal = Animal(
        idAnimal: 456,
        idRebano: 1,
        nombre: 'Server Animal Name',
        codigoAnimal: 'SERVER-001',
        sexo: 'F',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Server',
        archivado: false,
        createdAt: olderServerTime.toIso8601String(),
        updatedAt: olderServerTime.toIso8601String(),
        fkComposicionRaza: 1,
      );

      // Step 3: Try to sync - should skip because local is newer
      await DatabaseService.saveAnimalesOfflineWithConflictResolution([serverAnimal]);
      print('   Sync attempted with conflict resolution');

      // Step 4: Verify local data was preserved
      final db = await DatabaseService.database;
      final results = await db.query(
        'animales',
        where: 'id_animal = ?',
        whereArgs: [456],
      );
      
      expect(results.length, equals(1));
      final preservedAnimal = results.first;
      expect(preservedAnimal['nombre'], equals('Test Animal Conflict')); // Local name preserved
      expect(preservedAnimal['codigo_animal'], equals('CONFLICT-001')); // Local code preserved
      expect(preservedAnimal['sexo'], equals('M')); // Local sex preserved

      print('   ✓ Local data preserved (name: ${preservedAnimal['nombre']})');

      // Step 5: Verify audit record was created
      final auditRecords = await DatabaseService.getSyncAuditRecords(
        entityType: 'Animal',
        limit: 5,
      );
      
      final conflictRecord = auditRecords.firstWhere(
        (r) => r.entityId == 456 && r.action == SyncAuditAction.localNewer,
        orElse: () => throw Exception('Conflict audit record not found'),
      );
      
      expect(conflictRecord.conflictReason, contains('Local animal data is newer'));
      print('   ✓ Conflict audit record created: ${conflictRecord.conflictReason}');
    });

    test('animal sync with conflict resolution - server newer', () async {
      print('=== Testing Animal Sync Conflict Resolution (Server Newer) ===');

      // Step 1: Create a local animal with older timestamp
      print('Step 1: Creating local animal with older timestamp...');
      final oldTime = DateTime.now().subtract(const Duration(hours: 3));
      
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Old Local Animal',
        codigoAnimal: 'OLD-001',
        sexo: 'M',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      // Get the temp ID for the created animal
      final pendingAnimals = await DatabaseService.getPendingAnimalsOffline();
      final tempId = pendingAnimals.first['id_animal'] as int;
      print('   Created animal with temp ID: $tempId');

      // Manually update to have an older timestamp and positive ID
      final db = await DatabaseService.database;
      await db.update(
        'animales',
        {
          'id_animal': 789,
          'local_updated_at': oldTime.millisecondsSinceEpoch,
          'updated_at': oldTime.toIso8601String(),
        },
        where: 'id_animal = ?',
        whereArgs: [tempId],
      );

      // Step 2: Simulate server animal with newer timestamp
      print('Step 2: Simulating server sync with newer timestamp...');
      final newerServerTime = DateTime.now();
      final serverAnimal = Animal(
        idAnimal: 789,
        idRebano: 1,
        nombre: 'Updated Server Animal',
        codigoAnimal: 'SERVER-UPDATED-001',
        sexo: 'F',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Server Updated',
        archivado: false,
        createdAt: newerServerTime.toIso8601String(),
        updatedAt: newerServerTime.toIso8601String(),
        fkComposicionRaza: 1,
      );

      // Step 3: Sync - should accept server data because it's newer
      await DatabaseService.saveAnimalesOfflineWithConflictResolution([serverAnimal]);
      print('   Sync attempted with conflict resolution');

      // Step 4: Verify server data was accepted
      final results = await db.query(
        'animales',
        where: 'id_animal = ?',
        whereArgs: [789],
      );
      
      expect(results.length, equals(1));
      final updatedAnimal = results.first;
      expect(updatedAnimal['nombre'], equals('Updated Server Animal')); // Server name accepted
      expect(updatedAnimal['codigo_animal'], equals('SERVER-UPDATED-001')); // Server code accepted
      expect(updatedAnimal['sexo'], equals('F')); // Server sex accepted

      print('   ✓ Server data accepted (name: ${updatedAnimal['nombre']})');

      // Step 5: Verify audit record was created
      final auditRecords = await DatabaseService.getSyncAuditRecords(
        entityType: 'Animal',
        limit: 5,
      );
      
      final updateRecord = auditRecords.firstWhere(
        (r) => r.entityId == 789 && r.action == SyncAuditAction.serverNewer,
        orElse: () => throw Exception('Server newer audit record not found'),
      );
      
      expect(updateRecord.conflictReason, contains('Server animal data is newer'));
      print('   ✓ Server newer audit record created: ${updateRecord.conflictReason}');
    });

    test('personal finca sync with conflict resolution', () async {
      print('=== Testing Personal Finca Sync Conflict Resolution ===');

      // Step 1: Create a local personal finca (simulating offline modification)
      print('Step 1: Creating local personal finca with recent timestamp...');
      await DatabaseService.savePendingPersonalFincaUpdateOffline(
        idTecnico: 101,
        idFinca: 1,
        cedula: 12345678,
        nombre: 'Juan Local',
        apellido: 'Pérez Local',
        telefono: '555-0001',
        correo: 'juan.local@test.com',
        tipoTrabajador: 'Técnico',
      );

      // Step 2: Simulate server personal finca with older timestamp
      print('Step 2: Simulating server sync with older timestamp...');
      final olderServerTime = DateTime.now().subtract(const Duration(hours: 1));
      final serverPersonal = PersonalFinca(
        idTecnico: 101,
        idFinca: 1,
        cedula: 12345678,
        nombre: 'Juan Server',
        apellido: 'Pérez Server',
        telefono: '555-0002',
        correo: 'juan.server@test.com',
        tipoTrabajador: 'Supervisor',
        createdAt: olderServerTime.toIso8601String(),
        updatedAt: olderServerTime.toIso8601String(),
      );

      // Step 3: Try to sync - should skip because local is newer
      await DatabaseService.savePersonalFincaOfflineWithConflictResolution([serverPersonal]);
      print('   Sync attempted with conflict resolution');

      // Step 4: Verify local data was preserved
      final db = await DatabaseService.database;
      final results = await db.query(
        'personal_finca',
        where: 'id_tecnico = ?',
        whereArgs: [101],
      );
      
      expect(results.length, equals(1));
      final preservedPersonal = results.first;
      expect(preservedPersonal['nombre'], equals('Juan Local')); // Local name preserved
      expect(preservedPersonal['telefono'], equals('555-0001')); // Local phone preserved
      expect(preservedPersonal['correo'], equals('juan.local@test.com')); // Local email preserved

      print('   ✓ Local data preserved (name: ${preservedPersonal['nombre']} ${preservedPersonal['apellido']})');

      // Step 5: Verify audit record was created
      final auditRecords = await DatabaseService.getSyncAuditRecords(
        entityType: 'PersonalFinca',
        limit: 5,
      );
      
      final conflictRecord = auditRecords.firstWhere(
        (r) => r.entityId == 101 && r.action == SyncAuditAction.localNewer,
        orElse: () => throw Exception('PersonalFinca conflict audit record not found'),
      );
      
      expect(conflictRecord.conflictReason, contains('Local personal finca data is newer'));
      print('   ✓ Conflict audit record created: ${conflictRecord.conflictReason}');
    });

    test('cleanup old sync audit records', () async {
      print('=== Testing Sync Audit Cleanup ===');

      // Create some old audit records
      final oldRecord1 = SyncAuditRecord(
        entityType: 'Animal',
        entityId: 999,
        entityName: 'Old Animal 1',
        action: SyncAuditAction.syncSuccess,
        syncTimestamp: DateTime.now().subtract(const Duration(days: 35)), // 35 days old
      );

      final oldRecord2 = SyncAuditRecord(
        entityType: 'Animal',
        entityId: 998,
        entityName: 'Old Animal 2',
        action: SyncAuditAction.syncSuccess,
        syncTimestamp: DateTime.now().subtract(const Duration(days: 40)), // 40 days old
      );

      final recentRecord = SyncAuditRecord(
        entityType: 'Animal',
        entityId: 997,
        entityName: 'Recent Animal',
        action: SyncAuditAction.syncSuccess,
        syncTimestamp: DateTime.now().subtract(const Duration(days: 5)), // 5 days old
      );

      await DatabaseService.saveSyncAuditRecord(oldRecord1);
      await DatabaseService.saveSyncAuditRecord(oldRecord2);
      await DatabaseService.saveSyncAuditRecord(recentRecord);

      print('   Created old and recent audit records');

      // Get count before cleanup
      final beforeCleanup = await DatabaseService.getSyncAuditRecords(limit: 100);
      final beforeCount = beforeCleanup.length;
      print('   Records before cleanup: $beforeCount');

      // Cleanup old records (keeping only last 30 days)
      await DatabaseService.cleanupOldSyncAuditRecords(keepDays: 30);

      // Get count after cleanup
      final afterCleanup = await DatabaseService.getSyncAuditRecords(limit: 100);
      final afterCount = afterCleanup.length;
      print('   Records after cleanup: $afterCount');

      // Verify that old records were removed but recent ones remain
      expect(afterCount, lessThan(beforeCount));
      
      // Verify the recent record is still there
      final recentStillExists = afterCleanup.any((r) => r.entityId == 997);
      expect(recentStillExists, isTrue);

      print('   ✓ Old records cleaned up successfully');
    });

    test('complete sync workflow simulation', () async {
      print('=== Testing Complete Sync Workflow ===');

      // Simulate a complete offline-to-online sync scenario
      print('Step 1: User goes offline and modifies animals...');
      
      // Create two animals offline
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Offline Animal 1',
        codigoAnimal: 'OFF-001',
        sexo: 'M',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Offline Animal 2',
        codigoAnimal: 'OFF-002',
        sexo: 'F',
        fechaNacimiento: '2024-01-02',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      // Modify an existing animal offline
      await DatabaseService.savePendingAnimalUpdateOffline(
        idAnimal: 1001,
        idRebano: 1,
        nombre: 'Modified Offline Animal',
        codigoAnimal: 'MOD-001',
        sexo: 'M',
        fechaNacimiento: '2024-01-03',
        procedencia: 'Modified Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      print('   Created offline animals and modifications');

      // Step 2: Simulate coming back online with server data
      print('Step 2: User comes back online, server has some updates...');
      
      final serverTime = DateTime.now().subtract(const Duration(minutes: 30)); // Server data is older
      final serverAnimals = [
        Animal(
          idAnimal: 1001, // Same as our modified animal
          idRebano: 1,
          nombre: 'Server Modified Animal',
          codigoAnimal: 'SERVER-MOD-001',
          sexo: 'F',
          fechaNacimiento: '2024-01-03',
          procedencia: 'Server Modified',
          archivado: false,
          createdAt: serverTime.toIso8601String(),
          updatedAt: serverTime.toIso8601String(),
          fkComposicionRaza: 1,
        ),
        Animal(
          idAnimal: 2001, // New animal from server
          idRebano: 1,
          nombre: 'New Server Animal',
          codigoAnimal: 'SERVER-NEW-001',
          sexo: 'M',
          fechaNacimiento: '2024-01-04',
          procedencia: 'Server',
          archivado: false,
          createdAt: serverTime.toIso8601String(),
          updatedAt: serverTime.toIso8601String(),
          fkComposicionRaza: 1,
        ),
      ];

      // Step 3: Sync with conflict resolution
      await DatabaseService.saveAnimalesOfflineWithConflictResolution(serverAnimals);
      print('   Sync completed with conflict resolution');

      // Step 4: Verify results
      final db = await DatabaseService.database;
      
      // Check that our local modification was preserved (local newer)
      final modifiedResult = await db.query('animales', where: 'id_animal = ?', whereArgs: [1001]);
      expect(modifiedResult.length, equals(1));
      expect(modifiedResult.first['nombre'], equals('Modified Offline Animal')); // Local name preserved
      
      // Check that new server animal was added
      final newServerResult = await db.query('animales', where: 'id_animal = ?', whereArgs: [2001]);
      expect(newServerResult.length, equals(1));
      expect(newServerResult.first['nombre'], equals('New Server Animal')); // Server animal added

      print('   ✓ Local modifications preserved, new server data accepted');

      // Step 5: Check audit records
      final auditRecords = await DatabaseService.getSyncAuditRecords(limit: 10);
      
      final localNewerRecords = auditRecords.where((r) => r.action == SyncAuditAction.localNewer).toList();
      final syncSuccessRecords = auditRecords.where((r) => r.action == SyncAuditAction.syncSuccess).toList();
      
      expect(localNewerRecords.length, greaterThan(0)); // Should have conflict records
      expect(syncSuccessRecords.length, greaterThan(0)); // Should have success records

      print('   ✓ Audit records created: ${localNewerRecords.length} conflicts, ${syncSuccessRecords.length} successes');
      print('=== Complete sync workflow test passed! ===');
    });
  });
}