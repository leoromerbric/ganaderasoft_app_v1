import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/configuration_models.dart';
import 'auth_service.dart';
import 'logging_service.dart';

class ConfigurationService {
  static final AuthService _authService = AuthService();

  // Get headers with authentication
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Estados de Salud
  static Future<EstadoSaludResponse> getEstadosSalud() async {
    try {
      LoggingService.debug(
        'Fetching estados de salud from server',
        'ConfigurationService',
      );

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/estados-salud'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        LoggingService.info(
          'Estados de salud fetched successfully',
          'ConfigurationService',
        );
        return EstadoSaludResponse.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to load estados de salud: ${response.statusCode}',
        );
      }
    } catch (e) {
      LoggingService.error(
        'Error fetching estados de salud',
        'ConfigurationService',
        e,
      );
      rethrow;
    }
  }

  // Etapas
  static Future<List<Etapa>> getEtapas() async {
    try {
      LoggingService.debug(
        'Fetching etapas from server',
        'ConfigurationService',
      );

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/etapas'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final etapas = (jsonData['data'] as List)
            .map((item) => Etapa.fromJson(item))
            .toList();
        LoggingService.info(
          '${etapas.length} etapas fetched successfully',
          'ConfigurationService',
        );
        return etapas;
      } else {
        throw Exception('Failed to load etapas: ${response.statusCode}');
      }
    } catch (e) {
      LoggingService.error('Error fetching etapas', 'ConfigurationService', e);
      rethrow;
    }
  }

  // Fuente Agua
  static Future<List<FuenteAgua>> getFuenteAgua() async {
    try {
      LoggingService.debug(
        'Fetching fuente agua from server',
        'ConfigurationService',
      );

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/configuracion/fuente-agua'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final fuenteAgua = (jsonData['data'] as List)
            .map((item) => FuenteAgua.fromJson(item))
            .toList();
        LoggingService.info(
          '${fuenteAgua.length} fuente agua items fetched successfully',
          'ConfigurationService',
        );
        return fuenteAgua;
      } else {
        throw Exception('Failed to load fuente agua: ${response.statusCode}');
      }
    } catch (e) {
      LoggingService.error(
        'Error fetching fuente agua',
        'ConfigurationService',
        e,
      );
      rethrow;
    }
  }

  // Método Riego
  static Future<List<MetodoRiego>> getMetodoRiego() async {
    try {
      LoggingService.debug(
        'Fetching metodo riego from server',
        'ConfigurationService',
      );

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/configuracion/metodo-riego'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final metodoRiego = (jsonData['data'] as List)
            .map((item) => MetodoRiego.fromJson(item))
            .toList();
        LoggingService.info(
          '${metodoRiego.length} metodo riego items fetched successfully',
          'ConfigurationService',
        );
        return metodoRiego;
      } else {
        throw Exception('Failed to load metodo riego: ${response.statusCode}');
      }
    } catch (e) {
      LoggingService.error(
        'Error fetching metodo riego',
        'ConfigurationService',
        e,
      );
      rethrow;
    }
  }

  // pH Suelo
  static Future<List<PhSuelo>> getPhSuelo() async {
    try {
      LoggingService.debug(
        'Fetching pH suelo from server',
        'ConfigurationService',
      );

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/configuracion/ph-suelo'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final phSuelo = (jsonData['data'] as List)
            .map((item) => PhSuelo.fromJson(item))
            .toList();
        LoggingService.info(
          '${phSuelo.length} pH suelo items fetched successfully',
          'ConfigurationService',
        );
        return phSuelo;
      } else {
        throw Exception('Failed to load pH suelo: ${response.statusCode}');
      }
    } catch (e) {
      LoggingService.error(
        'Error fetching pH suelo',
        'ConfigurationService',
        e,
      );
      rethrow;
    }
  }

  // Sexo
  static Future<List<Sexo>> getSexo() async {
    try {
      LoggingService.debug('Fetching sexo from server', 'ConfigurationService');

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/configuracion/sexo'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final sexo = (jsonData['data'] as List)
            .map((item) => Sexo.fromJson(item))
            .toList();
        LoggingService.info(
          '${sexo.length} sexo items fetched successfully',
          'ConfigurationService',
        );
        return sexo;
      } else {
        throw Exception('Failed to load sexo: ${response.statusCode}');
      }
    } catch (e) {
      LoggingService.error('Error fetching sexo', 'ConfigurationService', e);
      rethrow;
    }
  }

  // Textura Suelo
  static Future<List<TexturaSuelo>> getTexturaSuelo() async {
    try {
      LoggingService.debug(
        'Fetching textura suelo from server',
        'ConfigurationService',
      );

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/configuracion/textura-suelo'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final texturaSuelo = (jsonData['data'] as List)
            .map((item) => TexturaSuelo.fromJson(item))
            .toList();
        LoggingService.info(
          '${texturaSuelo.length} textura suelo items fetched successfully',
          'ConfigurationService',
        );
        return texturaSuelo;
      } else {
        throw Exception('Failed to load textura suelo: ${response.statusCode}');
      }
    } catch (e) {
      LoggingService.error(
        'Error fetching textura suelo',
        'ConfigurationService',
        e,
      );
      rethrow;
    }
  }

  // Tipo Explotación
  static Future<List<TipoExplotacion>> getTipoExplotacion() async {
    try {
      LoggingService.debug(
        'Fetching tipo explotacion from server',
        'ConfigurationService',
      );

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/configuracion/tipo-explotacion'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final tipoExplotacion = (jsonData['data'] as List)
            .map((item) => TipoExplotacion.fromJson(item))
            .toList();
        LoggingService.info(
          '${tipoExplotacion.length} tipo explotacion items fetched successfully',
          'ConfigurationService',
        );
        return tipoExplotacion;
      } else {
        throw Exception(
          'Failed to load tipo explotacion: ${response.statusCode}',
        );
      }
    } catch (e) {
      LoggingService.error(
        'Error fetching tipo explotacion',
        'ConfigurationService',
        e,
      );
      rethrow;
    }
  }

  // Tipo Relieve
  static Future<List<TipoRelieve>> getTipoRelieve() async {
    try {
      LoggingService.debug(
        'Fetching tipo relieve from server',
        'ConfigurationService',
      );

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/configuracion/tipo-relieve'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final tipoRelieve = (jsonData['data'] as List)
            .map((item) => TipoRelieve.fromJson(item))
            .toList();
        LoggingService.info(
          '${tipoRelieve.length} tipo relieve items fetched successfully',
          'ConfigurationService',
        );
        return tipoRelieve;
      } else {
        throw Exception('Failed to load tipo relieve: ${response.statusCode}');
      }
    } catch (e) {
      LoggingService.error(
        'Error fetching tipo relieve',
        'ConfigurationService',
        e,
      );
      rethrow;
    }
  }

  // Tipos Animal
  static Future<TipoAnimalResponse> getTiposAnimal() async {
    try {
      LoggingService.debug(
        'Fetching tipos animal from server',
        'ConfigurationService',
      );

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/tipos-animal'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        LoggingService.info(
          'Tipos animal fetched successfully',
          'ConfigurationService',
        );
        return TipoAnimalResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load tipos animal: ${response.statusCode}');
      }
    } catch (e) {
      LoggingService.error(
        'Error fetching tipos animal',
        'ConfigurationService',
        e,
      );
      rethrow;
    }
  }
}
