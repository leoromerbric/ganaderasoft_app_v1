class AppConfig {
  static const String _baseUrl = 'http://10.0.2.2:8000';

  static String get baseUrl => _baseUrl;
  static String get apiUrl => '$_baseUrl/api';

  // API Endpoints
  static String get loginUrl => '$apiUrl/auth/login';
  static String get logoutUrl => '$apiUrl/auth/logout';
  static String get profileUrl => '$apiUrl/profile';
  static String get fincasUrl => '$apiUrl/fincas';
}
