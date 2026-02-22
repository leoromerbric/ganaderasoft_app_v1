class AppConfig {
  static const String _baseUrl =
      'http://ec2-54-219-108-54.us-west-1.compute.amazonaws.com:9000';

  static String get baseUrl => _baseUrl;
  static String get apiUrl => '$_baseUrl/api';

  // API Endpoints
  static String get loginUrl => '$apiUrl/auth/login';
  static String get logoutUrl => '$apiUrl/auth/logout';
  static String get profileUrl => '$apiUrl/profile';
  static String get fincasUrl => '$apiUrl/fincas';
  static String get animalesUrl => '$apiUrl/animales';
  static String get rebanosUrl => '$apiUrl/rebanos';
  static String get composicionRazaUrl => '$apiUrl/composicion-raza';

  // Farm Management Endpoints
  static String get cambiosAnimalUrl => '$apiUrl/cambios-animal';
  static String get lactanciaUrl => '$apiUrl/lactancia';
  static String get registroLecheroUrl => '$apiUrl/leche';
  static String get pesoCorporalUrl => '$apiUrl/peso-corporal';
  static String get medidasCorporalesUrl => '$apiUrl/medidas-corporales';
  static String get personalFincaUrl => '$apiUrl/personal-finca';
}
