import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/configuration_models.dart';
import 'auth_service.dart';
import 'connectivity_service.dart';
import 'database_service.dart';
import 'logging_service.dart';

class ConfigurationService {
  static final AuthService _authService = AuthService();
  static const Duration _httpTimeout = Duration(seconds: 10);

  // Get headers with authentication
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Estados de Salud (with offline support)
  static Future<EstadoSaludResponse> getEstadosSalud() async {
    LoggingService.debug(
      'Getting estados de salud list...',
      'ConfigurationService',
    );

    try {
      // Check connectivity first
      final isConnected = await ConnectivityService.isConnected();

      if (!isConnected) {
        LoggingService.info(
          'No connectivity - using cached estados de salud data',
          'ConfigurationService',
        );
        return await _getOfflineEstadosSalud();
      }

      LoggingService.debug(
        'Connectivity available - fetching estados de salud from server',
        'ConfigurationService',
      );

      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('${AppConfig.apiUrl}/estados-salud'), headers: headers)
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final estadoSaludResponse = EstadoSaludResponse.fromJson(jsonData);

        LoggingService.info(
          'Estados de salud fetched successfully from server (${estadoSaludResponse.data.data.length} items)',
          'ConfigurationService',
        );

        // Save to offline storage
        await DatabaseService.saveEstadosSaludOffline(
          estadoSaludResponse.data.data,
        );

        return estadoSaludResponse;
      } else {
        LoggingService.error(
          'Estados de salud request failed with status: ${response.statusCode}',
          'ConfigurationService',
        );
        throw Exception(
          'Failed to load estados de salud: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      LoggingService.warning(
        'Estados de salud request timeout - falling back to offline data',
        'ConfigurationService',
      );
      return await _getOfflineEstadosSalud();
    } on SocketException {
      LoggingService.warning(
        'Estados de salud request socket error - falling back to offline data',
        'ConfigurationService',
      );
      return await _getOfflineEstadosSalud();
    } catch (e) {
      LoggingService.error(e.toString(), 'ConfigurationService', e);
      LoggingService.error(
        'Estados de salud request error',
        'ConfigurationService',
        e,
      );

      // If any network-related error, try offline data
      if (_isNetworkError(e)) {
        LoggingService.info(
          'Network error detected - trying offline estados de salud data',
          'ConfigurationService',
        );
        return await _getOfflineEstadosSalud();
      }

      rethrow;
    }
  }

  // Etapas (with offline support)
  static Future<List<Etapa>> getEtapas() async {
    LoggingService.debug('Getting etapas list...', 'ConfigurationService');

    try {
      // Check connectivity first
      final isConnected = await ConnectivityService.isConnected();

      if (!isConnected) {
        LoggingService.info(
          'No connectivity - using cached etapas data',
          'ConfigurationService',
        );
        return await _getOfflineEtapas();
      }

      LoggingService.debug(
        'Connectivity available - fetching etapas from server',
        'ConfigurationService',
      );

      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('${AppConfig.apiUrl}/etapas'), headers: headers)
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final etapas = (jsonData['data'] as List)
            .map((item) => Etapa.fromJson(item))
            .toList();

        LoggingService.info(
          'Etapas fetched successfully from server (${etapas.length} items)',
          'ConfigurationService',
        );

        // Save to offline storage
        await DatabaseService.saveEtapasOffline(etapas);

        return etapas;
      } else {
        LoggingService.error(
          'Etapas request failed with status: ${response.statusCode}',
          'ConfigurationService',
        );
        throw Exception('Failed to load etapas: ${response.statusCode}');
      }
    } on TimeoutException {
      LoggingService.warning(
        'Etapas request timeout - falling back to offline data',
        'ConfigurationService',
      );
      return await _getOfflineEtapas();
    } on SocketException {
      LoggingService.warning(
        'Etapas request socket error - falling back to offline data',
        'ConfigurationService',
      );
      return await _getOfflineEtapas();
    } catch (e) {
      LoggingService.error(e.toString(), 'ConfigurationService', e);
      LoggingService.error('Etapas request error', 'ConfigurationService', e);

      // If any network-related error, try offline data
      if (_isNetworkError(e)) {
        LoggingService.info(
          'Network error detected - trying offline etapas data',
          'ConfigurationService',
        );
        return await _getOfflineEtapas();
      }

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

  // Tipos Animal (with offline support)
  static Future<TipoAnimalResponse> getTiposAnimal() async {
    LoggingService.debug(
      'Getting tipos animal list...',
      'ConfigurationService',
    );

    try {
      // Check connectivity first
      final isConnected = await ConnectivityService.isConnected();

      if (!isConnected) {
        LoggingService.info(
          'No connectivity - using cached tipos animal data',
          'ConfigurationService',
        );
        return await _getOfflineTiposAnimal();
      }

      LoggingService.debug(
        'Connectivity available - fetching tipos animal from server',
        'ConfigurationService',
      );

      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('${AppConfig.apiUrl}/tipos-animal'), headers: headers)
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final tipoAnimalResponse = TipoAnimalResponse.fromJson(jsonData);

        LoggingService.info(
          'Tipos animal fetched successfully from server (${tipoAnimalResponse.data.data.length} items)',
          'ConfigurationService',
        );

        // Save to offline storage
        await DatabaseService.saveTiposAnimalOffline(
          tipoAnimalResponse.data.data,
        );

        return tipoAnimalResponse;
      } else {
        LoggingService.error(
          'Tipos animal request failed with status: ${response.statusCode}',
          'ConfigurationService',
        );
        throw Exception('Failed to load tipos animal: ${response.statusCode}');
      }
    } on TimeoutException {
      LoggingService.warning(
        'Tipos animal request timeout - falling back to offline data',
        'ConfigurationService',
      );
      return await _getOfflineTiposAnimal();
    } on SocketException {
      LoggingService.warning(
        'Tipos animal request socket error - falling back to offline data',
        'ConfigurationService',
      );
      return await _getOfflineTiposAnimal();
    } catch (e) {
      LoggingService.error(e.toString(), 'ConfigurationService', e);
      LoggingService.error(
        'Tipos animal request error',
        'ConfigurationService',
        e,
      );

      // If any network-related error, try offline data
      if (_isNetworkError(e)) {
        LoggingService.info(
          'Network error detected - trying offline tipos animal data',
          'ConfigurationService',
        );
        return await _getOfflineTiposAnimal();
      }

      rethrow;
    }
  }

  // Composición Raza (with offline support)
  static Future<ComposicionRazaResponse> getComposicionRaza() async {
    LoggingService.debug(
      'Getting composicion raza list...',
      'ConfigurationService',
    );

    try {
      // Check connectivity first
      final isConnected = await ConnectivityService.isConnected();

      if (!isConnected) {
        LoggingService.info(
          'No connectivity - using cached composicion raza data',
          'ConfigurationService',
        );
        return await _getOfflineComposicionRaza();
      }

      LoggingService.debug(
        'Connectivity available - fetching composicion raza from server',
        'ConfigurationService',
      );

      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse(AppConfig.composicionRazaUrl), headers: headers)
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        final composicionRazaResponse = ComposicionRazaResponse.fromJson(
          jsonData,
        );

        LoggingService.info(
          'Composicion raza fetched successfully from server (${composicionRazaResponse.data.data.length} items)',
          'ConfigurationService',
        );

        // Save to offline storage
        await DatabaseService.saveComposicionRazaOffline(
          composicionRazaResponse.data.data,
        );

        return composicionRazaResponse;
      } else {
        LoggingService.error(
          'Composicion raza request failed with status: ${response.statusCode}',
          'ConfigurationService',
        );
        throw Exception(
          'Failed to load composicion raza: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      LoggingService.warning(
        'Composicion raza request timeout - falling back to offline data',
        'ConfigurationService',
      );
      return await _getOfflineComposicionRaza();
    } on SocketException {
      LoggingService.warning(
        'Composicion raza request socket error - falling back to offline data',
        'ConfigurationService',
      );
      return await _getOfflineComposicionRaza();
    } catch (e) {
      LoggingService.error(e.toString(), 'ConfigurationService', e);
      LoggingService.error(
        'Composicion raza request error',
        'ConfigurationService',
        e,
      );

      // If any network-related error, try offline data
      if (_isNetworkError(e)) {
        LoggingService.info(
          'Network error detected - trying offline composicion raza data',
          'ConfigurationService',
        );
        return await _getOfflineComposicionRaza();
      }

      rethrow;
    }
  }

  // Get offline estados de salud data
  static Future<EstadoSaludResponse> _getOfflineEstadosSalud() async {
    try {
      LoggingService.debug(
        'Getting estados de salud from offline storage',
        'ConfigurationService',
      );

      final estadosSalud = await DatabaseService.getEstadosSaludOffline();

      if (estadosSalud.isEmpty) {
        LoggingService.warning(
          'No estados de salud data found in offline storage',
          'ConfigurationService',
        );
        throw Exception('No hay datos de estados de salud disponibles offline');
      }

      LoggingService.info(
        '${estadosSalud.length} estados de salud items retrieved from offline storage',
        'ConfigurationService',
      );

      // Create a mock paginated response
      return EstadoSaludResponse(
        success: true,
        message:
            'Datos de estados de salud obtenidos desde almacenamiento local',
        data: PaginatedData<EstadoSalud>(
          currentPage: 1,
          data: estadosSalud,
          total: estadosSalud.length,
          perPage: estadosSalud.length,
        ),
      );
    } catch (e) {
      LoggingService.error(
        'Error getting offline estados de salud data',
        'ConfigurationService',
        e,
      );
      rethrow;
    }
  }

  // Get offline etapas data
  static Future<List<Etapa>> _getOfflineEtapas() async {
    try {
      LoggingService.debug(
        'Getting etapas from offline storage',
        'ConfigurationService',
      );

      final etapas = await DatabaseService.getEtapasOffline();

      if (etapas.isEmpty) {
        LoggingService.warning(
          'No etapas data found in offline storage',
          'ConfigurationService',
        );
        throw Exception('No hay datos de etapas disponibles offline');
      }

      LoggingService.info(
        '${etapas.length} etapas items retrieved from offline storage',
        'ConfigurationService',
      );

      return etapas;
    } catch (e) {
      LoggingService.error(
        'Error getting offline etapas data',
        'ConfigurationService',
        e,
      );
      rethrow;
    }
  }

  // Get offline tipos animal data
  static Future<TipoAnimalResponse> _getOfflineTiposAnimal() async {
    try {
      LoggingService.debug(
        'Getting tipos animal from offline storage',
        'ConfigurationService',
      );

      final tiposAnimal = await DatabaseService.getTiposAnimalOffline();

      if (tiposAnimal.isEmpty) {
        LoggingService.warning(
          'No tipos animal data found in offline storage',
          'ConfigurationService',
        );
        throw Exception('No hay datos de tipos animal disponibles offline');
      }

      LoggingService.info(
        '${tiposAnimal.length} tipos animal items retrieved from offline storage',
        'ConfigurationService',
      );

      // Create a mock paginated response
      return TipoAnimalResponse(
        success: true,
        message: 'Datos de tipos animal obtenidos desde almacenamiento local',
        data: PaginatedData<TipoAnimal>(
          currentPage: 1,
          data: tiposAnimal,
          total: tiposAnimal.length,
          perPage: tiposAnimal.length,
        ),
      );
    } catch (e) {
      LoggingService.error(
        'Error getting offline tipos animal data',
        'ConfigurationService',
        e,
      );
      rethrow;
    }
  }

  // Get offline composicion raza data
  static Future<ComposicionRazaResponse> _getOfflineComposicionRaza() async {
    try {
      LoggingService.debug(
        'Getting composicion raza from offline storage',
        'ConfigurationService',
      );

      final composicionRaza = await DatabaseService.getComposicionRazaOffline();

      if (composicionRaza.isEmpty) {
        LoggingService.warning(
          'No composicion raza data found in offline storage',
          'ConfigurationService',
        );
        throw Exception('No hay datos de composicion raza disponibles offline');
      }

      LoggingService.info(
        '${composicionRaza.length} composicion raza items retrieved from offline storage',
        'ConfigurationService',
      );

      // Create a mock paginated response
      return ComposicionRazaResponse(
        success: true,
        message:
            'Datos de composicion raza obtenidos desde almacenamiento local',
        data: PaginatedData<ComposicionRaza>(
          currentPage: 1,
          data: composicionRaza,
          total: composicionRaza.length,
          perPage: composicionRaza.length,
        ),
      );
    } catch (e) {
      LoggingService.error(
        'Error getting offline composicion raza data',
        'ConfigurationService',
        e,
      );
      rethrow;
    }
  }

  // Helper method to check if error is network-related
  static bool _isNetworkError(dynamic error) {
    return error is SocketException ||
        error is TimeoutException ||
        error.toString().contains('connection') ||
        error.toString().contains('network') ||
        error.toString().contains('timeout');
  }
}
