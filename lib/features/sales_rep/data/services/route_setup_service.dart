import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/network/network_error_helper.dart';

class RouteSetupServiceException implements Exception {
  const RouteSetupServiceException(this.message, {this.code});

  final String message;
  final String? code;
}

class RouteSetupVehicle {
  const RouteSetupVehicle({
    required this.id,
    required this.label,
    required this.registrationNumber,
    required this.status,
    required this.isAvailable,
    required this.unavailableReason,
  });

  final String id;
  final String label;
  final String registrationNumber;
  final String status;
  final bool isAvailable;
  final String? unavailableReason;

  factory RouteSetupVehicle.fromJson(Map<String, dynamic> json) {
    return RouteSetupVehicle(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      registrationNumber: (json['registrationNumber'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      isAvailable: json['isAvailable'] == true,
      unavailableReason: json['unavailableReason']?.toString(),
    );
  }
}

class RouteSetupWarehouse {
  const RouteSetupWarehouse({
    required this.id,
    required this.name,
    required this.address,
    required this.vehicles,
  });

  final String id;
  final String name;
  final String address;
  final List<RouteSetupVehicle> vehicles;

  factory RouteSetupWarehouse.fromJson(Map<String, dynamic> json) {
    final rawVehicles = json['vehicles'];
    return RouteSetupWarehouse(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      vehicles: rawVehicles is List
          ? rawVehicles
                .whereType<Map>()
                .map(
                  (item) => RouteSetupVehicle.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class RouteSetupOptions {
  const RouteSetupOptions({
    required this.territoryId,
    required this.warehouses,
  });

  final String? territoryId;
  final List<RouteSetupWarehouse> warehouses;

  factory RouteSetupOptions.fromJson(Map<String, dynamic> json) {
    final rawWarehouses = json['warehouses'];
    return RouteSetupOptions(
      territoryId: json['territoryId']?.toString(),
      warehouses: rawWarehouses is List
          ? rawWarehouses
                .whereType<Map>()
                .map(
                  (item) => RouteSetupWarehouse.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class RouteSetupService {
  RouteSetupService({Dio? dio}) : _dio = dio ?? DioClient.instance.client;

  final Dio _dio;

  Future<RouteSetupOptions> fetchSetupOptions() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/sales-routes/setup');
      return RouteSetupOptions.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw RouteSetupServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to load route setup options.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }
}
