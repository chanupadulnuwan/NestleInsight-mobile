class AppConfig {
  static const _productionApiBaseUrl = 'http://206.189.144.128:3000';
  static const _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    return _productionApiBaseUrl;
  }

  static String resolveApiUrl(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return '';
    }

    if (normalized.startsWith('http://') ||
        normalized.startsWith('https://') ||
        normalized.startsWith('assets/')) {
      return normalized;
    }

    if (normalized.startsWith('/')) {
      return '$apiBaseUrl$normalized';
    }

    return '$apiBaseUrl/$normalized';
  }
}
