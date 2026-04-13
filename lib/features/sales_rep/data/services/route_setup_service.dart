import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';

class RouteSetupServiceException implements Exception {
  const RouteSetupServiceException(this.message, {this.code});

  final String message;
  final String? code;
}

class Territory {
  const Territory({required this.id, required this.name});

  final String id;
  final String name;

  factory Territory.fromJson(Map<String, dynamic> json) {
    return Territory(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class Warehouse {
  const Warehouse({required this.id, required this.name});

  final String id;
  final String name;

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class RouteSetupService {
  final Dio _dio = DioClient.instance.client;

  Future<List<Territory>> fetchTerritories() async {
    try {
      final response = await _dio.get('/territories');

      if (response.statusCode == 200) {
        final territories = response.data?['territories'] ?? [];
        if (territories is List) {
          return territories
              .map((t) => Territory.fromJson(t as Map<String, dynamic>))
              .toList();
        }
      }

      throw RouteSetupServiceException(
        'Failed to fetch territories: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw RouteSetupServiceException(
        e.response?.data?['message'] ??
            e.message ??
            'Failed to fetch territories',
      );
    } catch (e) {
      throw RouteSetupServiceException('An unexpected error occurred: $e');
    }
  }

  Future<List<Warehouse>> fetchWarehouses({required String territoryId}) async {
    try {
      final response = await _dio.get(
        '/warehouses',
        queryParameters: {'territoryId': territoryId},
      );

      if (response.statusCode == 200) {
        final warehouses = response.data?['warehouses'] ?? [];
        if (warehouses is List) {
          return warehouses
              .map((w) => Warehouse.fromJson(w as Map<String, dynamic>))
              .toList();
        }
      }

      throw RouteSetupServiceException(
        'Failed to fetch warehouses: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw RouteSetupServiceException(
        e.response?.data?['message'] ??
            e.message ??
            'Failed to fetch warehouses',
      );
    } catch (e) {
      throw RouteSetupServiceException('An unexpected error occurred: $e');
    }
  }
}
