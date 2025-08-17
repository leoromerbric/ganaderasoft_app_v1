import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/models/configuration_item.dart';

void main() {
  group('ConfigurationItem', () {
    test('should create from JSON correctly', () {
      final json = {
        'id': 1,
        'nombre': 'Test Name',
        'descripcion': 'Test Description',
        'activo': true,
        'created_at': '2024-01-15T10:00:00.000000Z',
        'updated_at': '2024-01-15T10:00:00.000000Z',
      };

      final item = ConfigurationItem.fromJson(json, ConfigurationType.estadoSalud);

      expect(item.id, 1);
      expect(item.nombre, 'Test Name');
      expect(item.descripcion, 'Test Description');
      expect(item.activo, true);
      expect(item.tipo, ConfigurationType.estadoSalud);
      expect(item.isSynced, true);
    });

    test('should convert to database map correctly', () {
      final item = ConfigurationItem(
        id: 1,
        nombre: 'Test Name',
        descripcion: 'Test Description',
        activo: true,
        createdAt: '2024-01-15T10:00:00.000000Z',
        updatedAt: '2024-01-15T10:00:00.000000Z',
        tipo: ConfigurationType.estadoSalud,
        isSynced: true,
      );

      final map = item.toDatabaseMap();

      expect(map['id'], 1);
      expect(map['nombre'], 'Test Name');
      expect(map['descripcion'], 'Test Description');
      expect(map['activo'], 1);
      expect(map['tipo'], ConfigurationType.estadoSalud);
      expect(map['is_synced'], 1);
      expect(map['local_updated_at'], isA<int>());
    });

    test('should create from database correctly', () {
      final map = {
        'id': 1,
        'nombre': 'Test Name',
        'descripcion': 'Test Description',
        'activo': 1,
        'created_at': '2024-01-15T10:00:00.000000Z',
        'updated_at': '2024-01-15T10:00:00.000000Z',
        'tipo': ConfigurationType.estadoSalud,
        'is_synced': 1,
      };

      final item = ConfigurationItem.fromDatabase(map);

      expect(item.id, 1);
      expect(item.nombre, 'Test Name');
      expect(item.descripcion, 'Test Description');
      expect(item.activo, true);
      expect(item.tipo, ConfigurationType.estadoSalud);
      expect(item.isSynced, true);
    });
  });

  group('ConfigurationType', () {
    test('should get correct display names', () {
      expect(ConfigurationType.getDisplayName(ConfigurationType.estadoSalud), 'Estado de Salud');
      expect(ConfigurationType.getDisplayName(ConfigurationType.etapas), 'Etapas de Vida');
      expect(ConfigurationType.getDisplayName(ConfigurationType.fuenteAgua), 'Fuentes de Agua');
    });

    test('should get correct API endpoints', () {
      expect(ConfigurationType.getApiEndpoint(ConfigurationType.estadoSalud), 'estado-salud');
      expect(ConfigurationType.getApiEndpoint(ConfigurationType.etapas), 'etapas');
      expect(ConfigurationType.getApiEndpoint(ConfigurationType.fuenteAgua), 'fuente-agua');
    });

    test('should have all configuration types', () {
      expect(ConfigurationType.all.length, 10);
      expect(ConfigurationType.all.contains(ConfigurationType.estadoSalud), true);
      expect(ConfigurationType.all.contains(ConfigurationType.tiposAnimal), true);
    });
  });
}