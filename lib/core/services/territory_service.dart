import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/network/network_error_helper.dart';

class TerritoryServiceException implements Exception {
  const TerritoryServiceException(this.message, {this.code});

  final String message;
  final String? code;
}

class LocationAssignment {
  const LocationAssignment({
    required this.territoryId,
    required this.territoryName,
    required this.warehouseId,
    required this.warehouseName,
  });

  factory LocationAssignment.fromJson(Map<String, dynamic> json) {
    final territory = json['territory'] as Map<dynamic, dynamic>?;
    final warehouse = json['warehouse'] as Map<dynamic, dynamic>?;

    return LocationAssignment(
      territoryId: territory?['id']?.toString() ?? '',
      territoryName: territory?['name']?.toString() ?? '',
      warehouseId: warehouse?['id']?.toString() ?? '',
      warehouseName: warehouse?['name']?.toString() ?? '',
    );
  }

  final String territoryId;
  final String territoryName;
  final String warehouseId;
  final String warehouseName;

  bool get isComplete =>
      territoryId.isNotEmpty &&
      territoryName.isNotEmpty &&
      warehouseId.isNotEmpty &&
      warehouseName.isNotEmpty;
}

class WarehouseAssignment {
  const WarehouseAssignment({
    required this.warehouseId,
    required this.warehouseName,
    required this.territoryId,
    required this.territoryName,
  });

  factory WarehouseAssignment.fromJson(Map<String, dynamic> json) {
    final warehouse = json['warehouse'] as Map<dynamic, dynamic>?;

    return WarehouseAssignment(
      warehouseId: warehouse?['id']?.toString() ?? '',
      warehouseName: warehouse?['name']?.toString() ?? '',
      territoryId: warehouse?['territoryId']?.toString() ?? '',
      territoryName: warehouse?['territoryName']?.toString() ?? '',
    );
  }

  final String warehouseId;
  final String warehouseName;
  final String territoryId;
  final String territoryName;
}

class TerritoryService {
  TerritoryService({Dio? dio}) : _dio = dio ?? DioClient.instance.client;

  final Dio _dio;

  bool get isAvailable => true;

  String get unavailableReason =>
      'Territory and warehouse assignments can be resolved automatically from the backend.';

  Future<LocationAssignment?> resolveAssignment({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/territories/resolve',
        queryParameters: <String, dynamic>{
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      final payload = response.data ?? <String, dynamic>{};
      final assignment = LocationAssignment.fromJson(payload);
      return assignment.isComplete ? assignment : null;
    } on DioException catch (error) {
      throw TerritoryServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to resolve the nearest territory right now.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  Future<String?> resolveTerritory({
    required double latitude,
    required double longitude,
  }) async {
    final assignment = await resolveAssignment(
      latitude: latitude,
      longitude: longitude,
    );

    return assignment?.territoryName;
  }

  Future<WarehouseAssignment> lookupWarehouse(String warehouseName) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/warehouses/lookup',
        queryParameters: <String, dynamic>{'name': warehouseName.trim()},
      );

      return WarehouseAssignment.fromJson(
        response.data ?? <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw TerritoryServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Warehouse name was not found.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }
}
