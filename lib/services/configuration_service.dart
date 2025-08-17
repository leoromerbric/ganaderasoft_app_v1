import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../models/configuration_item.dart';
import 'database_service.dart';
import 'connectivity_service.dart';
import 'logging_service.dart';

class ConfigurationService {
  // Fetch configuration items from API or local storage
  static Future<List<ConfigurationItem>> getConfigurationItems(String tipo) async {
    try {
      LoggingService.info('Fetching configuration items of type: $tipo', 'ConfigurationService');
      
      // Check if we're online
      final isConnected = await ConnectivityService.isConnected();
      
      if (isConnected) {
        try {
          // Try to fetch from API
          final items = await _fetchFromApi(tipo);
          
          // Save to local storage
          await DatabaseService.saveConfigurationItemsOffline(items, tipo);
          
          LoggingService.info('${items.length} configuration items of type $tipo fetched from API and cached', 'ConfigurationService');
          return items;
        } catch (e) {
          LoggingService.warning('Failed to fetch from API, falling back to offline data', 'ConfigurationService', e);
          // Fall back to offline data
          return await DatabaseService.getConfigurationItemsOffline(tipo);
        }
      } else {
        LoggingService.info('No internet connection, loading from offline storage', 'ConfigurationService');
        return await DatabaseService.getConfigurationItemsOffline(tipo);
      }
    } catch (e) {
      LoggingService.error('Error fetching configuration items', 'ConfigurationService', e);
      return [];
    }
  }

  // Fetch configuration items from API
  static Future<List<ConfigurationItem>> _fetchFromApi(String tipo) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final endpoint = ConfigurationType.getApiEndpoint(tipo);
    final url = Uri.parse('${AppConfig.baseUrl}/api/configuracion/$endpoint');
    
    LoggingService.debug('Making API request to: $url', 'ConfigurationService');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    LoggingService.debug('API response status: ${response.statusCode}', 'ConfigurationService');

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      
      if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
        final List<dynamic> itemsJson = jsonResponse['data'];
        final items = itemsJson.map((json) => ConfigurationItem.fromJson(json, tipo)).toList();
        
        LoggingService.info('Successfully parsed ${items.length} configuration items of type $tipo from API', 'ConfigurationService');
        return items;
      } else {
        throw Exception('Invalid API response format');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Authentication failed');
    } else {
      throw Exception('API request failed with status ${response.statusCode}');
    }
  }

  // Sync all configuration types
  static Future<void> syncAllConfigurations() async {
    try {
      LoggingService.info('Starting sync of all configuration types', 'ConfigurationService');
      
      final isConnected = await ConnectivityService.isConnected();
      if (!isConnected) {
        throw Exception('No internet connection available');
      }

      int syncedCount = 0;
      int totalTypes = ConfigurationType.all.length;

      for (final tipo in ConfigurationType.all) {
        try {
          await getConfigurationItems(tipo);
          syncedCount++;
          LoggingService.debug('Synced configuration type: $tipo ($syncedCount/$totalTypes)', 'ConfigurationService');
        } catch (e) {
          LoggingService.error('Failed to sync configuration type: $tipo', 'ConfigurationService', e);
        }
      }

      LoggingService.info('Configuration sync completed: $syncedCount/$totalTypes types synced successfully', 'ConfigurationService');
    } catch (e) {
      LoggingService.error('Error during configuration sync', 'ConfigurationService', e);
      rethrow;
    }
  }

  // Get configuration counts for each type
  static Future<Map<String, int>> getConfigurationCounts() async {
    return await DatabaseService.getConfigurationCounts();
  }

  // Get sync status for each configuration type
  static Future<Map<String, bool>> getSyncStatus() async {
    return await DatabaseService.getConfigurationSyncStatus();
  }

  // Check if a specific configuration type has data
  static Future<bool> hasConfigurationData(String tipo) async {
    final items = await DatabaseService.getConfigurationItemsOffline(tipo);
    return items.isNotEmpty;
  }

  // Get last updated time for a configuration type
  static Future<DateTime?> getLastUpdated(String tipo) async {
    return await DatabaseService.getConfigurationLastUpdated(tipo);
  }

  // Force refresh a specific configuration type
  static Future<List<ConfigurationItem>> refreshConfigurationType(String tipo) async {
    try {
      LoggingService.info('Force refreshing configuration type: $tipo', 'ConfigurationService');
      
      final isConnected = await ConnectivityService.isConnected();
      if (!isConnected) {
        throw Exception('No internet connection available');
      }

      final items = await _fetchFromApi(tipo);
      await DatabaseService.saveConfigurationItemsOffline(items, tipo);
      
      LoggingService.info('Configuration type $tipo refreshed successfully', 'ConfigurationService');
      return items;
    } catch (e) {
      LoggingService.error('Error refreshing configuration type: $tipo', 'ConfigurationService', e);
      rethrow;
    }
  }
}