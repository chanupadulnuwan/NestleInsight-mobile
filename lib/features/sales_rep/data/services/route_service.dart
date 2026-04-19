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

class BeatPlanItem {
  const BeatPlanItem({
    required this.id,
    required this.outletId,
    required this.outletName,
    required this.ownerName,
    required this.source,
    required this.isSelected,
    required this.hasPendingDelivery,
    required this.pendingDeliveryCount,
    required this.orderIds,
  });

  final String id;
  final String outletId;
  final String outletName;
  final String? ownerName;
  final String source;
  final bool isSelected;
  final bool hasPendingDelivery;
  final int pendingDeliveryCount;
  final List<String> orderIds;

  factory BeatPlanItem.fromJson(Map<String, dynamic> json) {
    return BeatPlanItem(
      id: (json['id'] ?? '').toString(),
      outletId: (json['outletId'] ?? '').toString(),
      outletName: (json['outletName'] ?? '').toString(),
      ownerName: json['ownerName']?.toString(),
      source: (json['source'] ?? '').toString(),
      isSelected: json['isSelected'] == true,
      hasPendingDelivery: json['hasPendingDelivery'] == true,
      pendingDeliveryCount: _toInt(json['pendingDeliveryCount']),
      orderIds: _toStringList(json['orderIds']),
    );
  }
}

class RouteOutletOption {
  const RouteOutletOption({
    required this.id,
    required this.outletName,
    required this.ownerName,
  });

  final String id;
  final String outletName;
  final String? ownerName;

  factory RouteOutletOption.fromJson(Map<String, dynamic> json) {
    return RouteOutletOption(
      id: (json['id'] ?? '').toString(),
      outletName: (json['outletName'] ?? '').toString(),
      ownerName: json['ownerName']?.toString(),
    );
  }
}

class DeliveryAlert {
  const DeliveryAlert({
    required this.outletId,
    required this.outletName,
    required this.orderCount,
    required this.orderIds,
    required this.products,
  });

  final String outletId;
  final String outletName;
  final int orderCount;
  final List<String> orderIds;
  final List<StockLine> products;

  factory DeliveryAlert.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];
    return DeliveryAlert(
      outletId: (json['outletId'] ?? '').toString(),
      outletName: (json['outletName'] ?? '').toString(),
      orderCount: _toInt(json['orderCount']),
      orderIds: _toStringList(json['orderIds']),
      products: rawProducts is List
          ? rawProducts
                .whereType<Map>()
                .map(
                  (item) => StockLine.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }
}

class DeliveryApprovalSummary {
  const DeliveryApprovalSummary({
    required this.id,
    required this.status,
    required this.pinVerifiedAt,
    required this.pinExpiresAt,
    required this.notes,
  });

  final String id;
  final String status;
  final DateTime? pinVerifiedAt;
  final DateTime? pinExpiresAt;
  final String? notes;

  factory DeliveryApprovalSummary.fromJson(Map<String, dynamic> json) {
    return DeliveryApprovalSummary(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      pinVerifiedAt: _nullableDateTime(json['pinVerifiedAt']),
      pinExpiresAt: _nullableDateTime(json['pinExpiresAt']),
      notes: json['notes']?.toString(),
    );
  }
}

class VanLoadRequest {
  const VanLoadRequest({
    required this.id,
    required this.status,
    required this.deliveryStock,
    required this.freeSaleStock,
    required this.managerNotes,
  });

  final String id;
  final String status;
  final List<StockLine> deliveryStock;
  final List<StockLine> freeSaleStock;
  final String? managerNotes;

  factory VanLoadRequest.fromJson(Map<String, dynamic> json) {
    return VanLoadRequest(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      deliveryStock: _mapStockLines(json['deliveryStock']),
      freeSaleStock: _mapStockLines(json['freeSaleStock']),
      managerNotes: json['managerNotes']?.toString(),
    );
  }
}

class SalesRoute {
  const SalesRoute({
    required this.id,
    required this.status,
    required this.territoryId,
    required this.warehouseId,
    required this.warehouseName,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.startedAt,
    required this.closedAt,
    required this.routeStartPinExpiresAt,
    required this.deliveryOrderIds,
    required this.beatPlanItems,
    required this.availableOutlets,
    required this.deliveryAlerts,
    required this.deliveryApproval,
    required this.vanLoadRequest,
  });

  final String id;
  final String status;
  final String? territoryId;
  final String warehouseId;
  final String? warehouseName;
  final String? vehicleId;
  final String? vehicleLabel;
  final DateTime? startedAt;
  final DateTime? closedAt;
  final DateTime? routeStartPinExpiresAt;
  final List<String> deliveryOrderIds;
  final List<BeatPlanItem> beatPlanItems;
  final List<RouteOutletOption> availableOutlets;
  final List<DeliveryAlert> deliveryAlerts;
  final DeliveryApprovalSummary? deliveryApproval;
  final VanLoadRequest? vanLoadRequest;

  factory SalesRoute.fromJson(Map<String, dynamic> json) {
    final rawBeatPlanItems = json['beatPlanItems'];
    final rawAvailableOutlets = json['availableOutlets'];
    final rawDeliveryAlerts = json['deliveryAlerts'];
    final rawDeliveryApproval = json['deliveryApproval'];
    final rawVanLoadRequest = json['vanLoadRequest'];

    return SalesRoute(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      territoryId: json['territoryId']?.toString(),
      warehouseId: (json['warehouseId'] ?? '').toString(),
      warehouseName: json['warehouseName']?.toString(),
      vehicleId: _nullableString(json['vehicleId']),
      vehicleLabel: _nullableString(json['vehicleLabel']),
      startedAt: _nullableDateTime(json['startedAt']),
      closedAt: _nullableDateTime(json['closedAt']),
      routeStartPinExpiresAt: _nullableDateTime(json['routeStartPinExpiresAt']),
      deliveryOrderIds: _toStringList(json['deliveryOrderIds']),
      beatPlanItems: rawBeatPlanItems is List
          ? rawBeatPlanItems
                .whereType<Map>()
                .map(
                  (item) => BeatPlanItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      availableOutlets: rawAvailableOutlets is List
          ? rawAvailableOutlets
                .whereType<Map>()
                .map(
                  (item) => RouteOutletOption.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      deliveryAlerts: rawDeliveryAlerts is List
          ? rawDeliveryAlerts
                .whereType<Map>()
                .map(
                  (item) => DeliveryAlert.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      deliveryApproval: rawDeliveryApproval is Map
          ? DeliveryApprovalSummary.fromJson(
              Map<String, dynamic>.from(rawDeliveryApproval),
            )
          : null,
      vanLoadRequest: rawVanLoadRequest is Map
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

class PinActionResponse {
  const PinActionResponse({
    required this.message,
    this.pin,
    this.pinExpiresAt,
  });

  final String message;
  final String? pin;
  final DateTime? pinExpiresAt;
}

class RouteService {
  RouteService({Dio? dio}) : _dio = dio ?? DioClient.instance.client;

  final Dio _dio;

  Future<SalesRoute?> fetchMyRoute() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/sales-routes/my');
      final data = response.data ?? {};
      final rawRoute = data['route'];
      if (rawRoute is! Map) {
        return null;
      }

      return SalesRoute.fromJson(Map<String, dynamic>.from(rawRoute));
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
    required String vehicleId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/sales-routes',
        data: {
          'warehouseId': warehouseId,
          'vehicleId': vehicleId,
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

  Future<RouteActionResponse> updateBeatPlan({
    required String routeId,
    required List<String> selectedOutletIds,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/sales-routes/$routeId/beat-plan',
        data: {
          'selectedOutletIds': selectedOutletIds,
          'saveTemplate': true,
        },
      );
      final data = response.data ?? {};
      final rawRoute = data['route'];
      return RouteActionResponse(
        message: data['message'] as String? ?? 'Best plan updated successfully.',
        route: rawRoute is Map
            ? SalesRoute.fromJson(Map<String, dynamic>.from(rawRoute))
            : null,
      );
    } on DioException catch (error) {
      throw RouteServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to update the best plan.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  Future<PinActionResponse> requestDeliveryApproval({
    required String routeId,
    required List<String> orderIds,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/sales-routes/$routeId/delivery-approval-request',
        data: {
          'orderIds': orderIds,
        },
      );
      final data = response.data ?? {};
      return PinActionResponse(
        message:
            data['message'] as String? ??
            'Delivery approval request submitted successfully.',
      );
    } on DioException catch (error) {
      throw RouteServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to request delivery approval.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  Future<PinActionResponse> confirmDeliveryApprovalPin({
    required String approvalRequestId,
    required String pin,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/sales-routes/approval-requests/$approvalRequestId/confirm-pin',
        data: {'pin': pin},
      );
      final data = response.data ?? {};
      return PinActionResponse(
        message:
            data['message'] as String? ??
            'Delivery approval PIN confirmed successfully.',
      );
    } on DioException catch (error) {
      throw RouteServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to confirm the delivery approval PIN.',
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
            data['message'] as String? ??
            'Load request submitted successfully.',
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

List<String> _toStringList(dynamic raw) {
  if (raw is! List) {
    return const [];
  }

  return raw
      .map((item) => item?.toString())
      .whereType<String>()
      .where((item) => item.isNotEmpty)
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
