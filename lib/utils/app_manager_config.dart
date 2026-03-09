class AppManagerConfig {
  static const String appSlug = 'almurakib_silver';
  static const String _defaultApiBase = 'https://amanager.almurakib.com';
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '604938591486-ad18ecqi6uhoqp035o8ivbdhku5njcuh.apps.googleusercontent.com',
  );

  // API base priority:
  // 1) --dart-define=APP_MANAGER_API_BASE=...
  // 2) Production base URL
  static String get apiBaseUrl {
    const configured = String.fromEnvironment(
      'APP_MANAGER_API_BASE',
      defaultValue: '',
    );
    return _normalizeApiBase(
      configured.trim().isNotEmpty ? configured : _defaultApiBase,
    );
  }

  static String _normalizeApiBase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '$_defaultApiBase/api/v1';

    final withoutTrailingSlash = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    final parsed = Uri.tryParse(withoutTrailingSlash);
    if (parsed == null) return withoutTrailingSlash;

    if (parsed.path.isEmpty || parsed.path == '/') {
      return '$withoutTrailingSlash/api/v1';
    }
    return withoutTrailingSlash;
  }

  static const Duration requestTimeout = Duration(seconds: 20);
}
