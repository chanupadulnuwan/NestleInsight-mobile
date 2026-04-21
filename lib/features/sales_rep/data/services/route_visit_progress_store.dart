import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RouteVisitProgressStore {
  static const _completedPrefix = 'nestle_route_completed_outlets_';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String _completedKey(String routeId) => '$_completedPrefix$routeId';

  Future<Set<String>> completedOutletIds(String routeId) async {
    if (routeId.trim().isEmpty) {
      return {};
    }

    final raw = await _storage.read(key: _completedKey(routeId));
    if (raw == null || raw.trim().isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return {};
      }
      return decoded
          .map((item) => item?.toString().trim())
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> markOutletCompleted({
    required String routeId,
    required String outletId,
  }) async {
    final cleanedRouteId = routeId.trim();
    final cleanedOutletId = outletId.trim();
    if (cleanedRouteId.isEmpty || cleanedOutletId.isEmpty) {
      return;
    }

    final completedIds = await completedOutletIds(cleanedRouteId);
    completedIds.add(cleanedOutletId);
    await _storage.write(
      key: _completedKey(cleanedRouteId),
      value: jsonEncode(completedIds.toList()..sort()),
    );
  }

  Future<void> clearRoute(String routeId) async {
    if (routeId.trim().isEmpty) {
      return;
    }
    await _storage.delete(key: _completedKey(routeId.trim()));
  }
}
