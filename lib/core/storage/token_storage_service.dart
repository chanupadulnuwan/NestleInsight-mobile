import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageService {
  static const _accessTokenKey = 'nestle_insight_access_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> readAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
  }
}
