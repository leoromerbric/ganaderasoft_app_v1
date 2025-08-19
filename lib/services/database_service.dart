import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/finca.dart';
import '../models/animal.dart';
import '../models/configuration_models.dart';
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
      version: 4,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
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

    // Configuration tables
    await db.execute('''
      CREATE TABLE estado_salud (
        estado_id INTEGER PRIMARY KEY,
        estado_nombre TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tipo_animal (
        tipo_animal_id INTEGER PRIMARY KEY,
        tipo_animal_nombre TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE etapa (
        etapa_id INTEGER PRIMARY KEY,
        etapa_nombre TEXT NOT NULL,
        etapa_edad_ini INTEGER NOT NULL,
        etapa_edad_fin INTEGER,
        etapa_fk_tipo_animal_id INTEGER NOT NULL,
        etapa_sexo TEXT NOT NULL,
        tipo_animal_data TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE fuente_agua (
        codigo TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE metodo_riego (
        codigo TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ph_suelo (
        codigo TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sexo (
        codigo TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE textura_suelo (
        codigo TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tipo_explotacion (
        codigo TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tipo_relieve (
        id INTEGER PRIMARY KEY,
        valor TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE composicion_raza (
        id_composicion INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        siglas TEXT NOT NULL,
        pelaje TEXT NOT NULL,
        proposito TEXT NOT NULL,
        tipo_raza TEXT NOT NULL,
        origen TEXT NOT NULL,
        caracteristica_especial TEXT NOT NULL,
        proporcion_raza TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT,
        fk_id_finca INTEGER,
        fk_tipo_animal_id INTEGER,
        synced INTEGER DEFAULT 0,
        local_updated_at INTEGER NOT NULL
      )
    ''');
    
    LoggingService.info('Database tables created successfully', 'DatabaseService');
  }

  static Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    LoggingService.info('Upgrading database from version $oldVersion to $newVersion', 'DatabaseService');
    
    if (oldVersion < 2) {
      // Add configuration tables for version 2
      await db.execute('''
        CREATE TABLE estado_salud (
          estado_id INTEGER PRIMARY KEY,
          estado_nombre TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          updated_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE tipo_animal (
          tipo_animal_id INTEGER PRIMARY KEY,
          tipo_animal_nombre TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          updated_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE etapa (
          etapa_id INTEGER PRIMARY KEY,
          etapa_nombre TEXT NOT NULL,
          etapa_edad_ini INTEGER NOT NULL,
          etapa_edad_fin INTEGER,
          etapa_fk_tipo_animal_id INTEGER NOT NULL,
          etapa_sexo TEXT NOT NULL,
          tipo_animal_data TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          updated_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE fuente_agua (
          codigo TEXT PRIMARY KEY,
          nombre TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          updated_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE metodo_riego (
          codigo TEXT PRIMARY KEY,
          nombre TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          updated_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE ph_suelo (
          codigo TEXT PRIMARY KEY,
          nombre TEXT NOT NULL,
          descripcion TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          updated_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE sexo (
          codigo TEXT PRIMARY KEY,
          nombre TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          updated_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE textura_suelo (
          codigo TEXT PRIMARY KEY,
          nombre TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          updated_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE tipo_explotacion (
          codigo TEXT PRIMARY KEY,
          nombre TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          updated_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE tipo_relieve (
          id INTEGER PRIMARY KEY,
          valor TEXT NOT NULL,
          descripcion TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          updated_at INTEGER NOT NULL
        )
      ''');
      
      LoggingService.info('Configuration tables added successfully', 'DatabaseService');
    }

    if (oldVersion < 3) {
      // Add animals and rebanos tables for version 3
      await db.execute('''
        CREATE TABLE rebanos (
          id_rebano INTEGER PRIMARY KEY,
          id_finca INTEGER NOT NULL,
          nombre TEXT NOT NULL,
          archivado INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          finca_data TEXT,
          local_updated_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE animales (
          id_animal INTEGER PRIMARY KEY,
          id_rebano INTEGER NOT NULL,
          nombre TEXT NOT NULL,
          codigo_animal TEXT NOT NULL,
          sexo TEXT NOT NULL,
          fecha_nacimiento TEXT NOT NULL,
          procedencia TEXT NOT NULL,
          archivado INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          fk_composicion_raza INTEGER NOT NULL,
          rebano_data TEXT,
          composicion_raza_data TEXT,
          local_updated_at INTEGER NOT NULL
        )
      ''');
      
      LoggingService.info('Animals and rebanos tables added successfully', 'DatabaseService');
    }

    if (oldVersion < 4) {
      // Add composicion_raza table for version 4
      await db.execute('''
        CREATE TABLE composicion_raza (
          id_composicion INTEGER PRIMARY KEY,
          nombre TEXT NOT NULL,
          siglas TEXT NOT NULL,
          pelaje TEXT NOT NULL,
          proposito TEXT NOT NULL,
          tipo_raza TEXT NOT NULL,
          origen TEXT NOT NULL,
          caracteristica_especial TEXT NOT NULL,
          proporcion_raza TEXT NOT NULL,
          created_at TEXT,
          updated_at TEXT,
          fk_id_finca INTEGER,
          fk_tipo_animal_id INTEGER,
          synced INTEGER DEFAULT 0,
          local_updated_at INTEGER NOT NULL
        )
      ''');
      
      LoggingService.info('Composicion raza table added successfully', 'DatabaseService');
    }
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
      
      // Clear configuration tables
      await db.delete('estado_salud');
      await db.delete('tipo_animal');
      await db.delete('etapa');
      await db.delete('fuente_agua');
      await db.delete('metodo_riego');
      await db.delete('ph_suelo');
      await db.delete('sexo');
      await db.delete('textura_suelo');
      await db.delete('tipo_explotacion');
      await db.delete('tipo_relieve');
      
      LoggingService.info('All offline data cleared successfully', 'DatabaseService');
    } catch (e) {
      LoggingService.error('Error clearing offline data', 'DatabaseService', e);
      rethrow;
    }
  }

  // Configuration data operations
  
  // Estados de Salud
  static Future<void> saveEstadosSaludOffline(List<EstadoSalud> estados) async {
    try {
      LoggingService.debug('Saving ${estados.length} estados de salud offline', 'DatabaseService');
      
      final db = await database;
      final batch = db.batch();

      batch.delete('estado_salud');

      for (final estado in estados) {
        batch.insert('estado_salud', {
          'estado_id': estado.estadoId,
          'estado_nombre': estado.estadoNombre,
          'synced': estado.synced == true ? 1 : 0,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }

      await batch.commit();
      LoggingService.info('${estados.length} estados de salud saved offline successfully', 'DatabaseService');
    } catch (e) {
      LoggingService.error('Error saving estados de salud offline', 'DatabaseService', e);
      rethrow;
    }
  }

  static Future<List<EstadoSalud>> getEstadosSaludOffline() async {
    try {
      LoggingService.debug('Retrieving estados de salud from offline storage', 'DatabaseService');
      
      final db = await database;
      final maps = await db.query('estado_salud', orderBy: 'estado_nombre');

      final estados = maps.map((map) => EstadoSalud(
        estadoId: map['estado_id'] as int,
        estadoNombre: map['estado_nombre'] as String,
        synced: (map['synced'] as int) == 1,
      )).toList();
      
      LoggingService.info('${estados.length} estados de salud retrieved from offline storage', 'DatabaseService');
      return estados;
    } catch (e) {
      LoggingService.error('Error retrieving estados de salud from offline storage', 'DatabaseService', e);
      return [];
    }
  }

  // Tipos de Animal
  static Future<void> saveTiposAnimalOffline(List<TipoAnimal> tipos) async {
    try {
      LoggingService.debug('Saving ${tipos.length} tipos de animal offline', 'DatabaseService');
      
      final db = await database;
      final batch = db.batch();

      batch.delete('tipo_animal');

      for (final tipo in tipos) {
        batch.insert('tipo_animal', {
          'tipo_animal_id': tipo.tipoAnimalId,
          'tipo_animal_nombre': tipo.tipoAnimalNombre,
          'synced': tipo.synced == true ? 1 : 0,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }

      await batch.commit();
      LoggingService.info('${tipos.length} tipos de animal saved offline successfully', 'DatabaseService');
    } catch (e) {
      LoggingService.error('Error saving tipos de animal offline', 'DatabaseService', e);
      rethrow;
    }
  }

  static Future<List<TipoAnimal>> getTiposAnimalOffline() async {
    try {
      LoggingService.debug('Retrieving tipos de animal from offline storage', 'DatabaseService');
      
      final db = await database;
      final maps = await db.query('tipo_animal', orderBy: 'tipo_animal_nombre');

      final tipos = maps.map((map) => TipoAnimal(
        tipoAnimalId: map['tipo_animal_id'] as int,
        tipoAnimalNombre: map['tipo_animal_nombre'] as String,
        synced: (map['synced'] as int) == 1,
      )).toList();
      
      LoggingService.info('${tipos.length} tipos de animal retrieved from offline storage', 'DatabaseService');
      return tipos;
    } catch (e) {
      LoggingService.error('Error retrieving tipos de animal from offline storage', 'DatabaseService', e);
      return [];
    }
  }

  // Etapas
  static Future<void> saveEtapasOffline(List<Etapa> etapas) async {
    try {
      LoggingService.debug('Saving ${etapas.length} etapas offline', 'DatabaseService');
      
      final db = await database;
      final batch = db.batch();

      batch.delete('etapa');

      for (final etapa in etapas) {
        batch.insert('etapa', {
          'etapa_id': etapa.etapaId,
          'etapa_nombre': etapa.etapaNombre,
          'etapa_edad_ini': etapa.etapaEdadIni,
          'etapa_edad_fin': etapa.etapaEdadFin,
          'etapa_fk_tipo_animal_id': etapa.etapaFkTipoAnimalId,
          'etapa_sexo': etapa.etapaSexo,
          'tipo_animal_data': jsonEncode(etapa.tipoAnimal.toJson()),
          'synced': etapa.synced == true ? 1 : 0,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }

      await batch.commit();
      LoggingService.info('${etapas.length} etapas saved offline successfully', 'DatabaseService');
    } catch (e) {
      LoggingService.error('Error saving etapas offline', 'DatabaseService', e);
      rethrow;
    }
  }

  static Future<List<Etapa>> getEtapasOffline() async {
    try {
      LoggingService.debug('Retrieving etapas from offline storage', 'DatabaseService');
      
      final db = await database;
      final maps = await db.query('etapa', orderBy: 'etapa_nombre');

      final etapas = maps.map((map) {
        final tipoAnimalData = jsonDecode(map['tipo_animal_data'] as String);
        return Etapa(
          etapaId: map['etapa_id'] as int,
          etapaNombre: map['etapa_nombre'] as String,
          etapaEdadIni: map['etapa_edad_ini'] as int,
          etapaEdadFin: map['etapa_edad_fin'] as int?,
          etapaFkTipoAnimalId: map['etapa_fk_tipo_animal_id'] as int,
          etapaSexo: map['etapa_sexo'] as String,
          tipoAnimal: TipoAnimal.fromJson(tipoAnimalData),
          synced: (map['synced'] as int) == 1,
        );
      }).toList();
      
      LoggingService.info('${etapas.length} etapas retrieved from offline storage', 'DatabaseService');
      return etapas;
    } catch (e) {
      LoggingService.error('Error retrieving etapas from offline storage', 'DatabaseService', e);
      return [];
    }
  }

  // Generic methods for simple codigo/nombre models
  static Future<void> _saveSimpleConfigOffline<T>(
    String tableName,
    List<T> items,
    Map<String, dynamic> Function(T) toMap,
  ) async {
    try {
      LoggingService.debug('Saving ${items.length} $tableName offline', 'DatabaseService');
      
      final db = await database;
      final batch = db.batch();

      batch.delete(tableName);

      for (final item in items) {
        final map = toMap(item);
        map['updated_at'] = DateTime.now().millisecondsSinceEpoch;
        batch.insert(tableName, map);
      }

      await batch.commit();
      LoggingService.info('${items.length} $tableName saved offline successfully', 'DatabaseService');
    } catch (e) {
      LoggingService.error('Error saving $tableName offline', 'DatabaseService', e);
      rethrow;
    }
  }

  static Future<List<T>> _getSimpleConfigOffline<T>(
    String tableName,
    T Function(Map<String, dynamic>) fromMap,
    String orderBy,
  ) async {
    try {
      LoggingService.debug('Retrieving $tableName from offline storage', 'DatabaseService');
      
      final db = await database;
      final maps = await db.query(tableName, orderBy: orderBy);

      final items = maps.map((map) => fromMap(map)).toList();
      
      LoggingService.info('${items.length} $tableName retrieved from offline storage', 'DatabaseService');
      return items;
    } catch (e) {
      LoggingService.error('Error retrieving $tableName from offline storage', 'DatabaseService', e);
      return [];
    }
  }

  // Fuente Agua
  static Future<void> saveFuenteAguaOffline(List<FuenteAgua> items) async {
    await _saveSimpleConfigOffline(
      'fuente_agua',
      items,
      (item) => {
        'codigo': item.codigo,
        'nombre': item.nombre,
        'synced': item.synced == true ? 1 : 0,
      },
    );
  }

  static Future<List<FuenteAgua>> getFuenteAguaOffline() async {
    return await _getSimpleConfigOffline(
      'fuente_agua',
      (map) => FuenteAgua(
        codigo: map['codigo'] as String,
        nombre: map['nombre'] as String,
        synced: (map['synced'] as int) == 1,
      ),
      'nombre',
    );
  }

  // Método Riego
  static Future<void> saveMetodoRiegoOffline(List<MetodoRiego> items) async {
    await _saveSimpleConfigOffline(
      'metodo_riego',
      items,
      (item) => {
        'codigo': item.codigo,
        'nombre': item.nombre,
        'synced': item.synced == true ? 1 : 0,
      },
    );
  }

  static Future<List<MetodoRiego>> getMetodoRiegoOffline() async {
    return await _getSimpleConfigOffline(
      'metodo_riego',
      (map) => MetodoRiego(
        codigo: map['codigo'] as String,
        nombre: map['nombre'] as String,
        synced: (map['synced'] as int) == 1,
      ),
      'nombre',
    );
  }

  // pH Suelo
  static Future<void> savePhSueloOffline(List<PhSuelo> items) async {
    await _saveSimpleConfigOffline(
      'ph_suelo',
      items,
      (item) => {
        'codigo': item.codigo,
        'nombre': item.nombre,
        'descripcion': item.descripcion,
        'synced': item.synced == true ? 1 : 0,
      },
    );
  }

  static Future<List<PhSuelo>> getPhSueloOffline() async {
    return await _getSimpleConfigOffline(
      'ph_suelo',
      (map) => PhSuelo(
        codigo: map['codigo'] as String,
        nombre: map['nombre'] as String,
        descripcion: map['descripcion'] as String,
        synced: (map['synced'] as int) == 1,
      ),
      'nombre',
    );
  }

  // Sexo
  static Future<void> saveSexoOffline(List<Sexo> items) async {
    await _saveSimpleConfigOffline(
      'sexo',
      items,
      (item) => {
        'codigo': item.codigo,
        'nombre': item.nombre,
        'synced': item.synced == true ? 1 : 0,
      },
    );
  }

  static Future<List<Sexo>> getSexoOffline() async {
    return await _getSimpleConfigOffline(
      'sexo',
      (map) => Sexo(
        codigo: map['codigo'] as String,
        nombre: map['nombre'] as String,
        synced: (map['synced'] as int) == 1,
      ),
      'nombre',
    );
  }

  // Textura Suelo
  static Future<void> saveTexturaSueloOffline(List<TexturaSuelo> items) async {
    await _saveSimpleConfigOffline(
      'textura_suelo',
      items,
      (item) => {
        'codigo': item.codigo,
        'nombre': item.nombre,
        'synced': item.synced == true ? 1 : 0,
      },
    );
  }

  static Future<List<TexturaSuelo>> getTexturaSueloOffline() async {
    return await _getSimpleConfigOffline(
      'textura_suelo',
      (map) => TexturaSuelo(
        codigo: map['codigo'] as String,
        nombre: map['nombre'] as String,
        synced: (map['synced'] as int) == 1,
      ),
      'nombre',
    );
  }

  // Tipo Explotación
  static Future<void> saveTipoExplotacionOffline(List<TipoExplotacion> items) async {
    await _saveSimpleConfigOffline(
      'tipo_explotacion',
      items,
      (item) => {
        'codigo': item.codigo,
        'nombre': item.nombre,
        'synced': item.synced == true ? 1 : 0,
      },
    );
  }

  static Future<List<TipoExplotacion>> getTipoExplotacionOffline() async {
    return await _getSimpleConfigOffline(
      'tipo_explotacion',
      (map) => TipoExplotacion(
        codigo: map['codigo'] as String,
        nombre: map['nombre'] as String,
        synced: (map['synced'] as int) == 1,
      ),
      'nombre',
    );
  }

  // Tipo Relieve
  static Future<void> saveTipoRelieveOffline(List<TipoRelieve> items) async {
    await _saveSimpleConfigOffline(
      'tipo_relieve',
      items,
      (item) => {
        'id': item.id,
        'valor': item.valor,
        'descripcion': item.descripcion,
        'synced': item.synced == true ? 1 : 0,
      },
    );
  }

  static Future<List<TipoRelieve>> getTipoRelieveOffline() async {
    return await _getSimpleConfigOffline(
      'tipo_relieve',
      (map) => TipoRelieve(
        id: map['id'] as int,
        valor: map['valor'] as String,
        descripcion: map['descripcion'] as String,
        synced: (map['synced'] as int) == 1,
      ),
      'valor',
    );
  }

  // ComposicionRaza
  static Future<void> saveComposicionRazaOffline(List<ComposicionRaza> items) async {
    try {
      LoggingService.debug('Saving ${items.length} composicion raza offline', 'DatabaseService');
      
      final db = await database;
      final batch = db.batch();
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      batch.delete('composicion_raza');

      for (final item in items) {
        batch.insert('composicion_raza', {
          'id_composicion': item.idComposicion,
          'nombre': item.nombre,
          'siglas': item.siglas,
          'pelaje': item.pelaje,
          'proposito': item.proposito,
          'tipo_raza': item.tipoRaza,
          'origen': item.origen,
          'caracteristica_especial': item.caracteristicaEspecial,
          'proporcion_raza': item.proporcionRaza,
          'created_at': item.createdAt,
          'updated_at': item.updatedAt,
          'fk_id_finca': item.fkIdFinca,
          'fk_tipo_animal_id': item.fkTipoAnimalId,
          'synced': item.synced == true ? 1 : 0,
          'local_updated_at': currentTime,
        });
      }

      await batch.commit();
      LoggingService.info('${items.length} composicion raza saved offline successfully', 'DatabaseService');
    } catch (e) {
      LoggingService.error('Error saving composicion raza offline', 'DatabaseService', e);
      rethrow;
    }
  }

  static Future<List<ComposicionRaza>> getComposicionRazaOffline() async {
    try {
      LoggingService.debug('Retrieving composicion raza from offline storage', 'DatabaseService');
      
      final db = await database;
      final maps = await db.query('composicion_raza', orderBy: 'nombre');

      final items = maps.map((map) => ComposicionRaza(
        idComposicion: map['id_composicion'] as int,
        nombre: map['nombre'] as String,
        siglas: map['siglas'] as String,
        pelaje: map['pelaje'] as String,
        proposito: map['proposito'] as String,
        tipoRaza: map['tipo_raza'] as String,
        origen: map['origen'] as String,
        caracteristicaEspecial: map['caracteristica_especial'] as String,
        proporcionRaza: map['proporcion_raza'] as String,
        createdAt: map['created_at'] as String?,
        updatedAt: map['updated_at'] as String?,
        fkIdFinca: map['fk_id_finca'] as int?,
        fkTipoAnimalId: map['fk_tipo_animal_id'] as int?,
        synced: (map['synced'] as int) == 1,
      )).toList();
      
      LoggingService.info('${items.length} composicion raza retrieved from offline storage', 'DatabaseService');
      return items;
    } catch (e) {
      LoggingService.error('Error retrieving composicion raza from offline storage', 'DatabaseService', e);
      return [];
    }
  }

  // Configuration last update times
  static Future<DateTime?> getConfigurationLastUpdated(String tableName) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        columns: ['updated_at'],
        orderBy: 'updated_at DESC',
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return DateTime.fromMillisecondsSinceEpoch(maps.first['updated_at']);
    } catch (e) {
      LoggingService.error('Error getting $tableName last updated time', 'DatabaseService', e);
      return null;
    }
  }

  // Rebanos operations
  static Future<void> saveRebanosOffline(List<Rebano> rebanos) async {
    try {
      LoggingService.debug('Saving ${rebanos.length} rebanos offline', 'DatabaseService');
      
      final db = await database;
      final batch = db.batch();
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      for (final rebano in rebanos) {
        batch.insert(
          'rebanos',
          {
            'id_rebano': rebano.idRebano,
            'id_finca': rebano.idFinca,
            'nombre': rebano.nombre,
            'archivado': rebano.archivado ? 1 : 0,
            'created_at': rebano.createdAt,
            'updated_at': rebano.updatedAt,
            'finca_data': rebano.finca != null ? jsonEncode({
              'id_Finca': rebano.finca!.idFinca,
              'id_Propietario': rebano.finca!.idPropietario,
              'Nombre': rebano.finca!.nombre,
              'Explotacion_Tipo': rebano.finca!.explotacionTipo,
              'archivado': rebano.finca!.archivado,
              'created_at': rebano.finca!.createdAt,
              'updated_at': rebano.finca!.updatedAt,
              'propietario': rebano.finca!.propietario != null ? {
                'id': rebano.finca!.propietario!.id,
                'id_Personal': rebano.finca!.propietario!.idPersonal,
                'Nombre': rebano.finca!.propietario!.nombre,
                'Apellido': rebano.finca!.propietario!.apellido,
                'Telefono': rebano.finca!.propietario!.telefono,
                'archivado': rebano.finca!.propietario!.archivado,
              } : null,
            }) : null,
            'local_updated_at': currentTime,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit();
      LoggingService.info('${rebanos.length} rebanos saved offline successfully', 'DatabaseService');
    } catch (e) {
      LoggingService.error('Error saving rebanos offline', 'DatabaseService', e);
      rethrow;
    }
  }

  static Future<List<Rebano>> getRebanosOffline({int? idFinca}) async {
    try {
      LoggingService.debug('Retrieving rebanos from offline storage${idFinca != null ? ' for finca $idFinca' : ''}', 'DatabaseService');
      
      final db = await database;
      String whereClause = '';
      List<dynamic> whereArgs = [];
      
      if (idFinca != null) {
        whereClause = 'id_finca = ?';
        whereArgs = [idFinca];
      }
      
      final List<Map<String, dynamic>> maps = await db.query(
        'rebanos',
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'local_updated_at DESC',
      );

      final rebanos = maps.map((map) {
        Finca? finca;
        if (map['finca_data'] != null) {
          final fincaData = jsonDecode(map['finca_data']);
          Propietario? propietario;
          if (fincaData['propietario'] != null) {
            propietario = Propietario.fromJson(fincaData['propietario']);
          }
          finca = Finca(
            idFinca: fincaData['id_Finca'],
            idPropietario: fincaData['id_Propietario'],
            nombre: fincaData['Nombre'],
            explotacionTipo: fincaData['Explotacion_Tipo'],
            archivado: fincaData['archivado'],
            createdAt: fincaData['created_at'],
            updatedAt: fincaData['updated_at'],
            propietario: propietario,
          );
        }

        return Rebano(
          idRebano: map['id_rebano'],
          idFinca: map['id_finca'],
          nombre: map['nombre'],
          archivado: map['archivado'] == 1,
          createdAt: map['created_at'],
          updatedAt: map['updated_at'],
          finca: finca,
        );
      }).toList();
      
      LoggingService.info('${rebanos.length} rebanos retrieved from offline storage', 'DatabaseService');
      return rebanos;
    } catch (e) {
      LoggingService.error('Error retrieving rebanos from offline storage', 'DatabaseService', e);
      return [];
    }
  }

  static Future<DateTime?> getRebanosLastUpdated() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'rebanos',
        columns: ['local_updated_at'],
        orderBy: 'local_updated_at DESC',
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return DateTime.fromMillisecondsSinceEpoch(maps.first['local_updated_at']);
    } catch (e) {
      LoggingService.error('Error getting rebanos last updated time', 'DatabaseService', e);
      return null;
    }
  }

  // Animales operations
  static Future<void> saveAnimalesOffline(List<Animal> animales) async {
    try {
      LoggingService.debug('Saving ${animales.length} animales offline', 'DatabaseService');
      
      final db = await database;
      final batch = db.batch();
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      for (final animal in animales) {
        batch.insert(
          'animales',
          {
            'id_animal': animal.idAnimal,
            'id_rebano': animal.idRebano,
            'nombre': animal.nombre,
            'codigo_animal': animal.codigoAnimal,
            'sexo': animal.sexo,
            'fecha_nacimiento': animal.fechaNacimiento,
            'procedencia': animal.procedencia,
            'archivado': animal.archivado ? 1 : 0,
            'created_at': animal.createdAt,
            'updated_at': animal.updatedAt,
            'fk_composicion_raza': animal.fkComposicionRaza,
            'rebano_data': animal.rebano != null ? jsonEncode({
              'id_Rebano': animal.rebano!.idRebano,
              'id_Finca': animal.rebano!.idFinca,
              'Nombre': animal.rebano!.nombre,
              'archivado': animal.rebano!.archivado,
              'created_at': animal.rebano!.createdAt,
              'updated_at': animal.rebano!.updatedAt,
            }) : null,
            'composicion_raza_data': animal.composicionRaza != null ? jsonEncode({
              'id_Composicion': animal.composicionRaza!.idComposicion,
              'Nombre': animal.composicionRaza!.nombre,
              'Siglas': animal.composicionRaza!.siglas,
              'Pelaje': animal.composicionRaza!.pelaje,
              'Proposito': animal.composicionRaza!.proposito,
              'Tipo_Raza': animal.composicionRaza!.tipoRaza,
              'Origen': animal.composicionRaza!.origen,
              'Caracteristica_Especial': animal.composicionRaza!.caracteristicaEspecial,
              'Proporcion_Raza': animal.composicionRaza!.proporcionRaza,
            }) : null,
            'local_updated_at': currentTime,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit();
      LoggingService.info('${animales.length} animales saved offline successfully', 'DatabaseService');
    } catch (e) {
      LoggingService.error('Error saving animales offline', 'DatabaseService', e);
      rethrow;
    }
  }

  static Future<List<Animal>> getAnimalesOffline({int? idRebano, int? idFinca}) async {
    try {
      LoggingService.debug('Retrieving animales from offline storage', 'DatabaseService');
      
      final db = await database;
      String whereClause = '';
      List<dynamic> whereArgs = [];
      
      if (idRebano != null) {
        whereClause = 'id_rebano = ?';
        whereArgs = [idRebano];
      } else if (idFinca != null) {
        // When filtering by finca, we need to join with rebanos table
        final rebanosInFinca = await getRebanosOffline(idFinca: idFinca);
        if (rebanosInFinca.isEmpty) return [];
        
        final rebanoIds = rebanosInFinca.map((r) => r.idRebano).toList();
        whereClause = 'id_rebano IN (${rebanoIds.map((_) => '?').join(',')})';
        whereArgs = rebanoIds;
      }
      
      final List<Map<String, dynamic>> maps = await db.query(
        'animales',
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'local_updated_at DESC',
      );

      final animales = maps.map((map) {
        Rebano? rebano;
        if (map['rebano_data'] != null) {
          final rebanoData = jsonDecode(map['rebano_data']);
          rebano = Rebano(
            idRebano: rebanoData['id_Rebano'],
            idFinca: rebanoData['id_Finca'],
            nombre: rebanoData['Nombre'],
            archivado: rebanoData['archivado'],
            createdAt: rebanoData['created_at'],
            updatedAt: rebanoData['updated_at'],
          );
        }

        ComposicionRaza? composicionRaza;
        if (map['composicion_raza_data'] != null) {
          final composicionData = jsonDecode(map['composicion_raza_data']);
          composicionRaza = ComposicionRaza(
            idComposicion: composicionData['id_Composicion'],
            nombre: composicionData['Nombre'],
            siglas: composicionData['Siglas'],
            pelaje: composicionData['Pelaje'],
            proposito: composicionData['Proposito'],
            tipoRaza: composicionData['Tipo_Raza'],
            origen: composicionData['Origen'],
            caracteristicaEspecial: composicionData['Caracteristica_Especial'],
            proporcionRaza: composicionData['Proporcion_Raza'],
          );
        }

        return Animal(
          idAnimal: map['id_animal'],
          idRebano: map['id_rebano'],
          nombre: map['nombre'],
          codigoAnimal: map['codigo_animal'],
          sexo: map['sexo'],
          fechaNacimiento: map['fecha_nacimiento'],
          procedencia: map['procedencia'],
          archivado: map['archivado'] == 1,
          createdAt: map['created_at'],
          updatedAt: map['updated_at'],
          fkComposicionRaza: map['fk_composicion_raza'],
          rebano: rebano,
          composicionRaza: composicionRaza,
        );
      }).toList();
      
      LoggingService.info('${animales.length} animales retrieved from offline storage', 'DatabaseService');
      return animales;
    } catch (e) {
      LoggingService.error('Error retrieving animales from offline storage', 'DatabaseService', e);
      return [];
    }
  }

  static Future<DateTime?> getAnimalesLastUpdated() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'animales',
        columns: ['local_updated_at'],
        orderBy: 'local_updated_at DESC',
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return DateTime.fromMillisecondsSinceEpoch(maps.first['local_updated_at']);
    } catch (e) {
      LoggingService.error('Error getting animales last updated time', 'DatabaseService', e);
      return null;
    }
  }
}