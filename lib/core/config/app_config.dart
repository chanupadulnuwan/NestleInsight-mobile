import 'package:flutter/foundation.dart';

class AppConfig {
  static const _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    if (kIsWeb) {
      return 'https://backend.obscuranet.it.com';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'https://backend.obscuranet.it.com';
      default:
        return 'https://backend.obscuranet.it.com';
    }
  }

  static String resolveApiUrl(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return '';
    }

    if (
        normalized.startsWith('http://') ||
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
