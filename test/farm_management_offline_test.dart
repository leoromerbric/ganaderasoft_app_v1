import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Farm Management Offline Tests', () {
    test('should save and retrieve pending cambios animal offline', () async {
      // Save a pending cambios animal
      await DatabaseService.savePendingCambiosAnimalOffline(
        fechaCambio: '2024-01-15',
        etapaCambio: 'Adulto',
        peso: 450.5,
        altura: 150.0,
        comentario: 'Test cambio offline',
        cambiosEtapaAnid: 1,
        cambiosEtapaEtid: 2,
      );

      // Retrieve pending cambios animal
      final pendingCambios = await DatabaseService.getPendingCambiosAnimalOffline();
      expect(pendingCambios, isNotEmpty);
      
      final savedCambio = pendingCambios.first;
      expect(savedCambio['fecha_cambio'], equals('2024-01-15'));
      expect(savedCambio['etapa_cambio'], equals('Adulto'));
      expect(savedCambio['peso'], equals(450.5));
      expect(savedCambio['altura'], equals(150.0));
      expect(savedCambio['comentario'], equals('Test cambio offline'));
      expect(savedCambio['cambios_etapa_anid'], equals(1));
      expect(savedCambio['cambios_etapa_etid'], equals(2));
      expect(savedCambio['is_pending'], equals(1));
      expect(savedCambio['pending_operation'], equals('CREATE'));
      expect(savedCambio['synced'], equals(0));
      expect(savedCambio['modifiedOffline'], equals(1));
      
      // Temp ID should be negative
      final tempId = savedCambio['id_cambio'] as int;
      expect(tempId, lessThan(0));
    });

    test('should save and retrieve pending lactancia offline', () async {
      // Save a pending lactancia
      await DatabaseService.savePendingLactanciaOffline(
        lactanciaFechaInicio: '2024-01-10',
        lactanciaFechaFin: '2024-07-10',
        lactanciaSecado: '2024-07-05',
        lactanciaEtapaAnid: 5,
        lactanciaEtapaEtid: 3,
      );

      // Retrieve pending lactancia
      final pendingLactancia = await DatabaseService.getPendingLactanciaOffline();
      expect(pendingLactancia, isNotEmpty);
      
      final savedLactancia = pendingLactancia.first;
      expect(savedLactancia['lactancia_fecha_inicio'], equals('2024-01-10'));
      expect(savedLactancia['lactancia_fecha_fin'], equals('2024-07-10'));
      expect(savedLactancia['lactancia_secado'], equals('2024-07-05'));
      expect(savedLactancia['lactancia_etapa_anid'], equals(5));
      expect(savedLactancia['lactancia_etapa_etid'], equals(3));
      expect(savedLactancia['is_pending'], equals(1));
      expect(savedLactancia['pending_operation'], equals('CREATE'));
      expect(savedLactancia['synced'], equals(0));
      expect(savedLactancia['modifiedOffline'], equals(1));
      
      // Temp ID should be negative
      final tempId = savedLactancia['lactancia_id'] as int;
      expect(tempId, lessThan(0));
    });

    test('should save and retrieve pending peso corporal offline', () async {
      // Save a pending peso corporal
      await DatabaseService.savePendingPesoCorporalOffline(
        fechaPeso: '2024-01-20',
        peso: 320.75,
        comentario: 'Peso corporal offline test',
        pesoEtapaAnid: 8,
        pesoEtapaEtid: 4,
      );

      // Retrieve pending peso corporal
      final pendingPeso = await DatabaseService.getPendingPesoCorporalOffline();
      expect(pendingPeso, isNotEmpty);
      
      final savedPeso = pendingPeso.first;
      expect(savedPeso['fecha_peso'], equals('2024-01-20'));
      expect(savedPeso['peso'], equals(320.75));
      expect(savedPeso['comentario'], equals('Peso corporal offline test'));
      expect(savedPeso['peso_etapa_anid'], equals(8));
      expect(savedPeso['peso_etapa_etid'], equals(4));
      expect(savedPeso['is_pending'], equals(1));
      expect(savedPeso['pending_operation'], equals('CREATE'));
      expect(savedPeso['synced'], equals(0));
      expect(savedPeso['modifiedOffline'], equals(1));
      
      // Temp ID should be negative
      final tempId = savedPeso['id_peso'] as int;
      expect(tempId, lessThan(0));
    });

    test('should mark cambios animal as synced correctly', () async {
      // Save a pending cambios animal
      await DatabaseService.savePendingCambiosAnimalOffline(
        fechaCambio: '2024-02-01',
        etapaCambio: 'Joven',
        peso: 280.0,
        altura: 120.0,
        comentario: 'Sync test cambio',
        cambiosEtapaAnid: 10,
        cambiosEtapaEtid: 5,
      );

      // Get the temp ID
      final pendingCambios = await DatabaseService.getPendingCambiosAnimalOffline();
      expect(pendingCambios, isNotEmpty);
      final tempId = pendingCambios.first['id_cambio'] as int;
      expect(tempId, lessThan(0)); // Should be negative

      // Mark as synced with real ID
      const realId = 1001;
      await DatabaseService.markCambiosAnimalAsSynced(tempId, realId);

      // Verify it's no longer pending
      final stillPending = await DatabaseService.getPendingCambiosAnimalOffline();
      final foundInPending = stillPending.any((c) => c['id_cambio'] == realId);
      expect(foundInPending, isFalse);

      // Verify it's marked as synced in the database
      final db = await DatabaseService.database;
      final syncedRecords = await db.query(
        'cambios_animal',
        where: 'id_cambio = ? AND synced = ?',
        whereArgs: [realId, 1],
      );
      
      expect(syncedRecords, isNotEmpty);
      final syncedRecord = syncedRecords.first;
      expect(syncedRecord['is_pending'], equals(0));
      expect(syncedRecord['synced'], equals(1));
      expect(syncedRecord['modifiedOffline'], equals(0));
    });

    test('should mark lactancia as synced correctly', () async {
      // Save a pending lactancia
      await DatabaseService.savePendingLactanciaOffline(
        lactanciaFechaInicio: '2024-02-15',
        lactanciaEtapaAnid: 12,
        lactanciaEtapaEtid: 6,
      );

      // Get the temp ID
      final pendingLactancia = await DatabaseService.getPendingLactanciaOffline();
      expect(pendingLactancia, isNotEmpty);
      final tempId = pendingLactancia.first['lactancia_id'] as int;
      expect(tempId, lessThan(0)); // Should be negative

      // Mark as synced with real ID
      const realId = 2001;
      await DatabaseService.markLactanciaAsSynced(tempId, realId);

      // Verify it's no longer pending
      final stillPending = await DatabaseService.getPendingLactanciaOffline();
      final foundInPending = stillPending.any((l) => l['lactancia_id'] == realId);
      expect(foundInPending, isFalse);

      // Verify it's marked as synced in the database
      final db = await DatabaseService.database;
      final syncedRecords = await db.query(
        'lactancia',
        where: 'lactancia_id = ? AND synced = ?',
        whereArgs: [realId, 1],
      );
      
      expect(syncedRecords, isNotEmpty);
      final syncedRecord = syncedRecords.first;
      expect(syncedRecord['is_pending'], equals(0));
      expect(syncedRecord['synced'], equals(1));
      expect(syncedRecord['modifiedOffline'], equals(0));
    });

    test('should mark peso corporal as synced correctly', () async {
      // Save a pending peso corporal
      await DatabaseService.savePendingPesoCorporalOffline(
        fechaPeso: '2024-03-01',
        peso: 410.25,
        comentario: 'Final sync test',
        pesoEtapaAnid: 15,
        pesoEtapaEtid: 7,
      );

      // Get the temp ID
      final pendingPeso = await DatabaseService.getPendingPesoCorporalOffline();
      expect(pendingPeso, isNotEmpty);
      final tempId = pendingPeso.first['id_peso'] as int;
      expect(tempId, lessThan(0)); // Should be negative

      // Mark as synced with real ID
      const realId = 3001;
      await DatabaseService.markPesoCorporalAsSynced(tempId, realId);

      // Verify it's no longer pending
      final stillPending = await DatabaseService.getPendingPesoCorporalOffline();
      final foundInPending = stillPending.any((p) => p['id_peso'] == realId);
      expect(foundInPending, isFalse);

      // Verify it's marked as synced in the database
      final db = await DatabaseService.database;
      final syncedRecords = await db.query(
        'peso_corporal',
        where: 'id_peso = ? AND synced = ?',
        whereArgs: [realId, 1],
      );
      
      expect(syncedRecords, isNotEmpty);
      final syncedRecord = syncedRecords.first;
      expect(syncedRecord['is_pending'], equals(0));
      expect(syncedRecord['synced'], equals(1));
      expect(syncedRecord['modifiedOffline'], equals(0));
    });

    test('should generate unique temporary IDs for different farm management records', () async {
      // Save multiple records quickly
      final futures = <Future<void>>[];
      
      // Save cambios animal
      for (int i = 0; i < 3; i++) {
        futures.add(
          DatabaseService.savePendingCambiosAnimalOffline(
            fechaCambio: '2024-01-${10 + i}',
            etapaCambio: 'Test $i',
            peso: 100.0 + i,
            altura: 50.0 + i,
            comentario: 'Test cambio $i',
            cambiosEtapaAnid: i + 1,
            cambiosEtapaEtid: i + 1,
          ),
        );
      }
      
      // Save lactancia
      for (int i = 0; i < 3; i++) {
        futures.add(
          DatabaseService.savePendingLactanciaOffline(
            lactanciaFechaInicio: '2024-02-${10 + i}',
            lactanciaEtapaAnid: i + 5,
            lactanciaEtapaEtid: i + 5,
          ),
        );
      }
      
      // Save peso corporal
      for (int i = 0; i < 3; i++) {
        futures.add(
          DatabaseService.savePendingPesoCorporalOffline(
            fechaPeso: '2024-03-${10 + i}',
            peso: 200.0 + i,
            comentario: 'Test peso $i',
            pesoEtapaAnid: i + 10,
            pesoEtapaEtid: i + 10,
          ),
        );
      }

      await Future.wait(futures);

      // Get all records and check for unique IDs
      final pendingCambios = await DatabaseService.getPendingCambiosAnimalOffline();
      final pendingLactancia = await DatabaseService.getPendingLactanciaOffline();
      final pendingPeso = await DatabaseService.getPendingPesoCorporalOffline();

      expect(pendingCambios.length, greaterThanOrEqualTo(3));
      expect(pendingLactancia.length, greaterThanOrEqualTo(3));
      expect(pendingPeso.length, greaterThanOrEqualTo(3));

      // Check that all have unique negative IDs
      final cambiosIds = pendingCambios.map((c) => c['id_cambio'] as int).toList();
      final lactanciaIds = pendingLactancia.map((l) => l['lactancia_id'] as int).toList();
      final pesoIds = pendingPeso.map((p) => p['id_peso'] as int).toList();
      
      final allIds = [...cambiosIds, ...lactanciaIds, ...pesoIds];
      final uniqueIds = allIds.toSet();
      expect(uniqueIds.length, equals(allIds.length)); // No duplicates
      
      // All should be negative (temporary IDs)
      for (final id in allIds) {
        expect(id, lessThan(0));
      }
    });
  });
}