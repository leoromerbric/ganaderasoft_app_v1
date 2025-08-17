import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/finca.dart';
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
      
      LoggingService.info('All offline data cleared successfully', 'DatabaseService');
    } catch (e) {
      LoggingService.error('Error clearing offline data', 'DatabaseService', e);
      rethrow;
    }
  }
}