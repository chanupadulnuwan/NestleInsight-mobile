import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/network/network_error_helper.dart';

class RouteServiceException implements Exception {
  const RouteServiceException(this.message, {this.code});

  final String message;
  final String? code;
}

class StockLine {
  const StockLine({
    required this.productId,
    required this.productName,
    required this.quantityCases,
  });

  final String productId;
  final String productName;
  final int quantityCases;

  factory StockLine.fromJson(Map<String, dynamic> json) {
    return StockLine(
      productId: (json['productId'] ?? '').toString(),
      productName: (json['productName'] ?? '').toString(),
      quantityCases: _toInt(json['quantityCases']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantityCases': quantityCases,
    };
  }
}

class VanLoadRequest {
  const VanLoadRequest({
    required this.id,
    required this.status,
    required this.deliveryStock,
    required this.freeSaleStock,
  });

  final String id;
  final String status;
  final List<StockLine> deliveryStock;
  final List<StockLine> freeSaleStock;

  factory VanLoadRequest.fromJson(Map<String, dynamic> json) {
    return VanLoadRequest(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      deliveryStock: _mapStockLines(
        json['deliveryStock'] ?? json['deliveryStockJson'],
      ),
      freeSaleStock: _mapStockLines(
        json['freeSaleStock'] ?? json['freeSaleStockJson'],
      ),
    );
  }
}

class SalesRoute {
  const SalesRoute({
    required this.id,
    required this.status,
    required this.warehouseId,
    required this.vehicleId,
    required this.startedAt,
    required this.vanLoadRequest,
  });

  final String id;
  final String status;
  final String warehouseId;
  final String? vehicleId;
  final DateTime? startedAt;
  final VanLoadRequest? vanLoadRequest;

  factory SalesRoute.fromJson(Map<String, dynamic> json) {
    final rawVanLoadRequest =
        json['vanLoadRequest'] ?? json['loadRequest'] ?? json['van_load_request'];

    return SalesRoute(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      warehouseId: (json['warehouseId'] ?? '').toString(),
      vehicleId: _nullableString(json['vehicleId']),
      startedAt: _nullableDateTime(json['startedAt']),
      vanLoadRequest: rawVanLoadRequest is Map<String, dynamic>
          ? VanLoadRequest.fromJson(rawVanLoadRequest)
          : rawVanLoadRequest is Map
              ? VanLoadRequest.fromJson(Map<String, dynamic>.from(rawVanLoadRequest))
              : null,
    );
  }
}

class CloseStockLineInput {
  const CloseStockLineInput({
    required this.productId,
    required this.productName,
    required this.quantityCases,
    required this.quantityUnits,
  });

  final String productId;
  final String productName;
  final int quantityCases;
  final int quantityUnits;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantityCases': quantityCases,
      'quantityUnits': quantityUnits,
    };
  }
}

class ReturnItemInput {
  const ReturnItemInput({
    required this.productId,
    required this.productName,
    required this.quantityCases,
    required this.reason,
  });

  final String productId;
  final String productName;
  final int quantityCases;
  final String reason;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantityCases': quantityCases,
      'reason': reason,
    };
  }
}

class RouteActionResponse {
  const RouteActionResponse({required this.message, this.route});

  final String message;
  final SalesRoute? route;
}

class RouteService {
  RouteService({Dio? dio}) : _dio = dio ?? DioClient.instance.client;

  final Dio _dio;

  Future<SalesRoute?> fetchMyRoute() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/sales-routes/my');
      final data = response.data ?? {};
      final rawRoute = data['route'];
      if (rawRoute == null) {
        return null;
      }

      final routeJson = Map<String, dynamic>.from(rawRoute as Map);
      final rawLoadRequest = data['loadRequest'];
      if (rawLoadRequest is Map) {
        routeJson['vanLoadRequest'] = Map<String, dynamic>.from(rawLoadRequest);
      }

      return SalesRoute.fromJson(routeJson);
    } on DioException catch (error) {
      throw RouteServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to fetch your route.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  Future<RouteActionResponse> createRoute({
    required String warehouseId,
    String? vehicleId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/sales-routes',
        data: {
          'warehouseId': warehouseId,
          if (vehicleId != null && vehicleId.trim().isNotEmpty)
            'vehicleId': vehicleId.trim(),
        },
      );
      final data = response.data ?? {};
      final rawRoute = data['route'];

      return RouteActionResponse(
        message:
            data['message'] as String? ?? 'Sales route created successfully.',
        route: rawRoute is Map
            ? SalesRoute.fromJson(Map<String, dynamic>.from(rawRoute))
            : null,
      );
    } on DioException catch (error) {
      throw RouteServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to create route.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  Future<RouteActionResponse> submitLoadRequest({
    required String routeId,
    required List<StockLine> deliveryStock,
    required List<StockLine> freeSaleStock,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/sales-routes/$routeId/load-request',
        data: {
          'deliveryStock': deliveryStock.map((item) => item.toJson()).toList(),
          'freeSaleStock': freeSaleStock.map((item) => item.toJson()).toList(),
        },
      );
      final data = response.data ?? {};
      return RouteActionResponse(
        message:
            data['message'] as String? ?? 'Load request submitted successfully.',
      );
    } on DioException catch (error) {
      throw RouteServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to submit load request.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  Future<RouteActionResponse> enterStartPin({
    required String routeId,
    required String pin,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/sales-routes/$routeId/start-pin',
        data: {'pin': pin},
      );
      final data = response.data ?? {};
      final rawRoute = data['route'];

      return RouteActionResponse(
        message: data['message'] as String? ?? 'Route started successfully.',
        route: rawRoute is Map
            ? SalesRoute.fromJson(Map<String, dynamic>.from(rawRoute))
            : null,
      );
    } on DioException catch (error) {
      throw RouteServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to start route.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  Future<RouteActionResponse> closeRoute({
    required String routeId,
    required String pin,
    required List<CloseStockLineInput> closingStock,
    required List<ReturnItemInput> returnItems,
    String? varianceReason,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/sales-routes/$routeId/close',
        data: {
          'pin': pin,
          'closingStock': closingStock.map((item) => item.toJson()).toList(),
          'returnItems': returnItems.map((item) => item.toJson()).toList(),
          if (varianceReason != null && varianceReason.trim().isNotEmpty)
            'varianceReason': varianceReason.trim(),
        },
      );
      final data = response.data ?? {};
      final rawRoute = data['route'];

      return RouteActionResponse(
        message: data['message'] as String? ?? 'Route closed successfully.',
        route: rawRoute is Map
            ? SalesRoute.fromJson(Map<String, dynamic>.from(rawRoute))
            : null,
      );
    } on DioException catch (error) {
      throw RouteServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to close route.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }
}

List<StockLine> _mapStockLines(dynamic raw) {
  if (raw is! List) {
    return const [];
  }

  return raw
      .whereType<Map>()
      .map((item) => StockLine.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

String? _nullableString(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty || text == 'null') {
    return null;
  }
  return text;
}

DateTime? _nullableDateTime(dynamic value) {
  final text = _nullableString(value);
  if (text == null) {
    return null;
  }
  return DateTime.tryParse(text);
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
