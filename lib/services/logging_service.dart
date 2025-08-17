import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

class LoggingService {
  static const String _tag = 'GanaderaSoft';
  
  static void debug(String message, [String? tag]) {
    _log(LogLevel.debug, message, tag);
  }
  
  static void info(String message, [String? tag]) {
    _log(LogLevel.info, message, tag);
  }
  
  static void warning(String message, [String? tag]) {
    _log(LogLevel.warning, message, tag);
  }
  
  static void error(String message, [String? tag, Object? error]) {
    _log(LogLevel.error, message, tag, error);
  }
  
  static void _log(LogLevel level, String message, [String? tag, Object? error]) {
    final logTag = tag ?? _tag;
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase();
    
    final logMessage = '[$timestamp] [$levelStr] [$logTag] $message';
    
    // Print to console for debug builds
    print(logMessage);
    
    // Also use developer.log for better Android Studio debugging
    developer.log(
      message,
      time: DateTime.now(),
      level: _getLevelValue(level),
      name: logTag,
      error: error,
    );
  }
  
  static int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}