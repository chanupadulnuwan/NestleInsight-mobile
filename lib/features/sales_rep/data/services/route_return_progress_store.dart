import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:mobile/features/sales_rep/data/services/route_service.dart';
import 'package:mobile/features/sales_rep/data/services/sales_return_service.dart';

class RouteReturnProgressStore {
  static const _returnsPrefix = 'nestle_route_return_items_';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String _returnsKey(String routeId) => '$_returnsPrefix$routeId';

  Future<List<RouteReturnItem>> returnItems(String routeId) async {
    if (routeId.trim().isEmpty) {
      return const [];
    }

    final raw = await _storage.read(key: _returnsKey(routeId.trim()));
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => RouteReturnItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.productId.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> addReturnItems({
    required String routeId,
    required List<ReturnItemLog> items,
  }) async {
    final cleanedRouteId = routeId.trim();
    if (cleanedRouteId.isEmpty || items.isEmpty) {
      return;
    }

    final existing = await _rawReturnItems(cleanedRouteId);
    final now = DateTime.now().toIso8601String();
    existing.addAll(items.map((item) => {...item.toJson(), 'loggedAt': now}));

    await _storage.write(
      key: _returnsKey(cleanedRouteId),
      value: jsonEncode(existing),
    );
  }

  Future<void> clearRoute(String routeId) async {
    if (routeId.trim().isEmpty) {
      return;
    }
    await _storage.delete(key: _returnsKey(routeId.trim()));
  }

  Future<List<Map<String, dynamic>>> _rawReturnItems(String routeId) async {
    final raw = await _storage.read(key: _returnsKey(routeId));
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
