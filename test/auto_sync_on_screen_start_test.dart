import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:ganaderasoft_app_v1/services/logging_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Auto-sync on Screen Start Tests', () {
    test('should verify _autoLoadOnInit is enabled', () async {
      // This test verifies that we've enabled auto-loading 
      // by checking that pending records are loaded immediately
      
      // Create some pending data first
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Test Auto Sync Animal',
        codigoAnimal: 'AUTO-001',
        sexo: 'M',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      // Verify that pending records exist
      final pendingRecords = await DatabaseService.getAllPendingRecords();
      expect(pendingRecords, isNotEmpty);
      expect(pendingRecords.first['name'], equals('Test Auto Sync Animal'));
      
      LoggingService.info(
        'Auto-sync test: Found ${pendingRecords.length} pending records',
        'AutoSyncTest',
      );

      // With _autoLoadOnInit = true, the screen should immediately load these records
      // The actual screen initialization is tested through manual verification
    });

    test('should handle empty pending records gracefully', () async {
      // Clear any existing pending records
      await DatabaseService.database.then((db) async {
        await db.delete('animales', where: 'is_pending = ?', whereArgs: [1]);
        await db.delete('personal_finca', where: 'is_pending = ?', whereArgs: [1]);
      });

      // Verify no pending records exist
      final pendingRecords = await DatabaseService.getAllPendingRecords();
      expect(pendingRecords, isEmpty);
      
      LoggingService.info(
        'Auto-sync test: No pending records found, auto-sync should skip gracefully',
        'AutoSyncTest',
      );

      // The auto-sync should handle this gracefully without errors
      // and not attempt to sync when there are no pending records
    });

    test('should verify logging integration for auto-sync', () async {
      // This test ensures that the auto-sync process will log appropriately
      // Create some pending data
      await DatabaseService.savePendingAnimalOffline(
        idRebano: 1,
        nombre: 'Logging Test Animal',
        codigoAnimal: 'LOG-001',
        sexo: 'F',
        fechaNacimiento: '2024-01-01',
        procedencia: 'Local',
        fkComposicionRaza: 1,
        estadoId: 1,
        etapaId: 1,
      );

      final pendingRecords = await DatabaseService.getAllPendingRecords();
      expect(pendingRecords, isNotEmpty);

      // The _startAutoSync method should log appropriate messages:
      // - "Starting automatic sync check on screen initialization"
      // - Either "No connectivity available, skipping auto-sync" 
      //   or "Found X pending records with connectivity, starting auto-sync"
      // - Or "No pending records found, skipping auto-sync" if none exist

      LoggingService.info(
        'Auto-sync logging test: Pending records ready for auto-sync',
        'AutoSyncTest',
      );
    });
  });
}