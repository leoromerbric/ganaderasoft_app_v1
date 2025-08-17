import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/finca.dart';
import '../models/configuration_item.dart';
import 'logging_service.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ganaderasoft.db');
    
    LoggingService.info('Initializing database at: $path', 'DatabaseService');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  static Future<void> _createDatabase(Database db, int version) async {
    LoggingService.info('Creating database tables...', 'DatabaseService');
    
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        type_user TEXT NOT NULL,
        image TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create fincas table
    await db.execute('''
      CREATE TABLE fincas (
        id_finca INTEGER PRIMARY KEY,
        id_propietario INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        explotacion_tipo TEXT NOT NULL,
        archivado INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        propietario_data TEXT,
        local_updated_at INTEGER NOT NULL
      )
    ''');

    // Create configuration_items table
    await db.execute('''
      CREATE TABLE configuration_items (
        id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        activo INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        tipo TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        local_updated_at INTEGER NOT NULL,
        PRIMARY KEY (id, tipo)
      )
    ''');
    
    LoggingService.info('Database tables created successfully', 'DatabaseService');
  }

  // User operations
  static Future<void> saveUserOffline(User user) async {
    try {
      LoggingService.debug('Saving user offline: ${user.email}', 'DatabaseService');
      
      final db = await database;
      await db.insert(
        'users',
        {
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'type_user': user.typeUser,
          'image': user.image,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      LoggingService.info('User saved offline successfully: ${user.email}', 'DatabaseService');
    } catch (e) {
      LoggingService.error('Error saving user offline', 'DatabaseService', e);
      rethrow;
    }
  }

  static Future<User?> getUserOffline() async {
    try {
      LoggingService.debug('Retrieving user from offline storage', 'DatabaseService');
      
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        orderBy: 'updated_at DESC',
        limit: 1,
      );

      if (maps.isEmpty) {
        LoggingService.debug('No offline user data found', 'DatabaseService');
        return null;
      }

      final user = User.fromJson({
        'id': maps.first['id'],
        'name': maps.first['name'],
        'email': maps.first['email'],
        'type_user': maps.first['type_user'],
        'image': maps.first['image'],
      });
      
      LoggingService.info('User retrieved from offline storage: ${user.email}', 'DatabaseService');
      return user;
    } catch (e) {
      LoggingService.error('Error retrieving user from offline storage', 'DatabaseService', e);
      return null;
    }
  }

  static Future<DateTime?> getUserLastUpdated() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        columns: ['updated_at'],
        orderBy: 'updated_at DESC',
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return DateTime.fromMillisecondsSinceEpoch(maps.first['updated_at']);
    } catch (e) {
      LoggingService.error('Error getting user last updated time', 'DatabaseService', e);
      return null;
    }
  }

  // Fincas operations
  static Future<void> saveFincasOffline(List<Finca> fincas) async {
    try {
      LoggingService.debug('Saving ${fincas.length} fincas offline', 'DatabaseService');
      
      final db = await database;
      final batch = db.batch();

      // Clear existing fincas
      batch.delete('fincas');

      // Insert new fincas
      for (final finca in fincas) {
        batch.insert('fincas', {
          'id_finca': finca.idFinca,
          'id_propietario': finca.idPropietario,
          'nombre': finca.nombre,
          'explotacion_tipo': finca.explotacionTipo,
          'archivado': finca.archivado ? 1 : 0,
          'created_at': finca.createdAt,
          'updated_at': finca.updatedAt,
          'propietario_data': finca.propietario != null
              ? jsonEncode({
                  'id': finca.propietario!.id,
                  'id_Personal': finca.propietario!.idPersonal,
                  'Nombre': finca.propietario!.nombre,
                  'Apellido': finca.propietario!.apellido,
                  'Telefono': finca.propietario!.telefono,
                  'archivado': finca.propietario!.archivado,
                })
              : null,
          'local_updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }

      await batch.commit();
      
      LoggingService.info('${fincas.length} fincas saved offline successfully', 'DatabaseService');
    } catch (e) {
      LoggingService.error('Error saving fincas offline', 'DatabaseService', e);
      rethrow;
    }
  }

  static Future<List<Finca>> getFincasOffline() async {
    try {
      LoggingService.debug('Retrieving fincas from offline storage', 'DatabaseService');
      
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'fincas',
        orderBy: 'local_updated_at DESC',
      );

      final fincas = maps.map((map) {
        Propietario? propietario;
        if (map['propietario_data'] != null) {
          final propData = jsonDecode(map['propietario_data']);
          propietario = Propietario.fromJson(propData);
        }

        return Finca(
          idFinca: map['id_finca'],
          idPropietario: map['id_propietario'],
          nombre: map['nombre'],
          explotacionTipo: map['explotacion_tipo'],
          archivado: map['archivado'] == 1,
          createdAt: map['created_at'],
          updatedAt: map['updated_at'],
          propietario: propietario,
        );
      }).toList();
      
      LoggingService.info('${fincas.length} fincas retrieved from offline storage', 'DatabaseService');
      return fincas;
    } catch (e) {
      LoggingService.error('Error retrieving fincas from offline storage', 'DatabaseService', e);
      return [];
    }
  }

  static Future<DateTime?> getFincasLastUpdated() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'fincas',
        columns: ['local_updated_at'],
        orderBy: 'local_updated_at DESC',
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return DateTime.fromMillisecondsSinceEpoch(maps.first['local_updated_at']);
    } catch (e) {
      LoggingService.error('Error getting fincas last updated time', 'DatabaseService', e);
      return null;
    }
  }

  // Clear all data
  static Future<void> clearAllData() async {
    try {
      LoggingService.info('Clearing all offline data', 'DatabaseService');
      
      final db = await database;
      await db.delete('users');
      await db.delete('fincas');
      await db.delete('configuration_items');
      
      LoggingService.info('All offline data cleared successfully', 'DatabaseService');
    } catch (e) {
      LoggingService.error('Error clearing offline data', 'DatabaseService', e);
      rethrow;
    }
  }

  // Configuration operations
  static Future<void> saveConfigurationItemsOffline(List<ConfigurationItem> items, String tipo) async {
    try {
      LoggingService.debug('Saving ${items.length} configuration items of type $tipo offline', 'DatabaseService');
      
      final db = await database;
      final batch = db.batch();

      // Delete existing items of this type
      batch.delete('configuration_items', where: 'tipo = ?', whereArgs: [tipo]);

      // Insert new items
      for (final item in items) {
        batch.insert(
          'configuration_items',
          item.toDatabaseMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit();
      
      LoggingService.info('${items.length} configuration items of type $tipo saved offline successfully', 'DatabaseService');
    } catch (e) {
      LoggingService.error('Error saving configuration items offline', 'DatabaseService', e);
      rethrow;
    }
  }

  static Future<List<ConfigurationItem>> getConfigurationItemsOffline(String tipo) async {
    try {
      LoggingService.debug('Retrieving configuration items of type $tipo from offline storage', 'DatabaseService');
      
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'configuration_items',
        where: 'tipo = ?',
        whereArgs: [tipo],
        orderBy: 'nombre ASC',
      );

      final items = maps.map((map) => ConfigurationItem.fromDatabase(map)).toList();
      
      LoggingService.info('${items.length} configuration items of type $tipo retrieved from offline storage', 'DatabaseService');
      return items;
    } catch (e) {
      LoggingService.error('Error retrieving configuration items from offline storage', 'DatabaseService', e);
      return [];
    }
  }

  static Future<DateTime?> getConfigurationLastUpdated(String tipo) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'configuration_items',
        columns: ['local_updated_at'],
        where: 'tipo = ?',
        whereArgs: [tipo],
        orderBy: 'local_updated_at DESC',
        limit: 1,
      );

      if (maps.isEmpty) return null;
      
      return DateTime.fromMillisecondsSinceEpoch(maps.first['local_updated_at']);
    } catch (e) {
      LoggingService.error('Error getting configuration last updated time', 'DatabaseService', e);
      return null;
    }
  }

  static Future<Map<String, int>> getConfigurationCounts() async {
    try {
      final db = await database;
      final Map<String, int> counts = {};
      
      for (final tipo in ConfigurationType.all) {
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM configuration_items WHERE tipo = ?',
          [tipo]
        );
        counts[tipo] = result.isNotEmpty ? (result.first['count'] as int?) ?? 0 : 0;
      }
      
      return counts;
    } catch (e) {
      LoggingService.error('Error getting configuration counts', 'DatabaseService', e);
      return {};
    }
  }

  static Future<Map<String, bool>> getConfigurationSyncStatus() async {
    try {
      final db = await database;
      final Map<String, bool> syncStatus = {};
      
      for (final tipo in ConfigurationType.all) {
        final result = await db.rawQuery(
          'SELECT COUNT(*) as total, SUM(is_synced) as synced FROM configuration_items WHERE tipo = ?',
          [tipo]
        );
        
        if (result.isNotEmpty) {
          final total = (result.first['total'] as int?) ?? 0;
          final synced = (result.first['synced'] as int?) ?? 0;
          syncStatus[tipo] = total > 0 && synced == total;
        } else {
          syncStatus[tipo] = false;
        }
      }
      
      return syncStatus;
    } catch (e) {
      LoggingService.error('Error getting configuration sync status', 'DatabaseService', e);
      return {};
    }
  }
}