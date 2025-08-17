import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/finca.dart';
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
      version: 2,
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
}