class AppManagerConfig {
  static const String appSlug = 'almurakib_silver';
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '604938591486-ad18ecqi6uhoqp035o8ivbdhku5njcuh.apps.googleusercontent.com',
  );

  // Production API base:
  // https://amanager.almurakib.com/api/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'APP_MANAGER_API_BASE',
    defaultValue: 'https://amanager.almurakib.com/api/v1',
  );

  static const Duration requestTimeout = Duration(seconds: 20);
}
