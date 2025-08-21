class AppConstants {
  // App info
  static const String appName = 'Ganadera Soft';
  static const String appSubtitle = 'Gestión de Fincas Ganaderas';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String originalTokenKey = 'original_auth_token'; // For preserving JWT during offline mode

  // Offline keys
  static const String offlineUserKey = 'offline_user_data';
  static const String offlineFincasKey = 'offline_fincas_data';

  // UI constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;

  // Messages
  static const String loginRequired = 'Por favor inicie sesión';
  static const String networkError =
      'Error de conexión. Verifique su internet.';
  static const String unknownError = 'Ha ocurrido un error inesperado';
  static const String logoutConfirmTitle = 'Cerrar Sesión';
  static const String logoutConfirmMessage =
      '¿Está seguro que desea cerrar sesión?';
  static const String logoutConfirmButton = 'Cerrar Sesión';
  static const String cancelButton = 'Cancelar';
  static const String offlineMode = 'Modo Offline';
  static const String onlineMode = 'Modo Online';
  static const String dataFromCache = 'Datos cargados desde caché local';
}
