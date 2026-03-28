import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageService {
  static const _accessTokenKey = 'nestle_insight_access_token';
  static const _userDataKey = 'nestle_insight_user_data';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> readAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> saveUserData(Map<String, dynamic> user) async {
    await _storage.write(key: _userDataKey, value: jsonEncode(user));
  }

  Future<Map<String, dynamic>?> readUserData() async {
    final raw = await _storage.read(key: _userDataKey);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _userDataKey);
  }
}
