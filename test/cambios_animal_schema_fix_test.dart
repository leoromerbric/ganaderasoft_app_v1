import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Cambios Animal Schema Fix Tests', () {
    test('should create cambios_animal table with all required columns', () async {
      // Get database instance (this will trigger creation)
      final db = await DatabaseService.database;
      
      // Query table info to check if columns exist
      final tableInfo = await db.rawQuery("PRAGMA table_info(cambios_animal)");
      
      // Extract column names
      final columnNames = tableInfo.map((row) => row['name'] as String).toList();
      
      // Verify all required columns exist
      expect(columnNames, contains('id_cambio'));
      expect(columnNames, contains('fecha_cambio'));
      expect(columnNames, contains('synced'));
      expect(columnNames, contains('is_pending'));
      expect(columnNames, contains('pending_operation'));
      expect(columnNames, contains('local_updated_at'));
      expect(columnNames, contains('modifiedOffline'));
    });

    test('should successfully query pending cambios animal records', () async {
      final db = await DatabaseService.database;
      
      // This should not throw an error
      expect(() async {
        await DatabaseService.getAllPendingRecords();
      }, returnsNormally);
      
      // Also test the specific method
      expect(() async {
        await DatabaseService.getPendingCambiosAnimalOffline();
      }, returnsNormally);
    });

    test('should save and retrieve pending cambios animal', () async {
      // Save a pending cambios animal
      await DatabaseService.savePendingCambiosAnimalOffline(
        fechaCambio: '2024-01-01',
        etapaCambio: 'Test Stage',
        peso: 150.5,
        altura: 120.0,
        comentario: 'Test comment',
        cambiosEtapaAnid: 1,
        cambiosEtapaEtid: 2,
      );
      
      // Retrieve pending records
      final pendingRecords = await DatabaseService.getPendingCambiosAnimalOffline();
      
      // Should have at least one record
      expect(pendingRecords.length, greaterThan(0));
      
      // Check the record has correct values
      final record = pendingRecords.first;
      expect(record['fecha_cambio'], equals('2024-01-01'));
      expect(record['is_pending'], equals(1));
      expect(record['pending_operation'], equals('CREATE'));
      expect(record['synced'], equals(0));
    });

    test('should include cambios animal in getAllPendingRecords', () async {
      // Save a pending cambios animal
      await DatabaseService.savePendingCambiosAnimalOffline(
        fechaCambio: '2024-01-02',
        etapaCambio: 'Test Stage 2',
        peso: 160.0,
        altura: 125.0,
        comentario: 'Test comment 2',
        cambiosEtapaAnid: 3,
        cambiosEtapaEtid: 4,
      );
      
      // Get all pending records
      final allPendingRecords = await DatabaseService.getAllPendingRecords();
      
      // Should find our cambios animal record
      final cambiosRecords = allPendingRecords.where((record) => record['type'] == 'CambiosAnimal').toList();
      expect(cambiosRecords.length, greaterThan(0));
      
      // Check the structure
      final record = cambiosRecords.first;
      expect(record['type'], equals('CambiosAnimal'));
      expect(record['id'], isNotNull);
      expect(record['name'], contains('Cambio Animal'));
      expect(record['operation'], equals('CREATE'));
    });
  });
}