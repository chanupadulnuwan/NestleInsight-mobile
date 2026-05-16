import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/network/network_error_helper.dart';
import 'package:mobile/features/orders/domain/shop_cart_item.dart';
import 'package:mobile/features/orders/domain/shop_order.dart';

class OrderServiceException implements Exception {
  const OrderServiceException(this.message, {this.code});

  final String message;
  final String? code;
}

class OrderCreateResult {
  const OrderCreateResult({required this.message, required this.order});

  factory OrderCreateResult.fromJson(Map<String, dynamic> json) {
    final rawOrder = json['order'];
    final orderMap = rawOrder is Map
        ? Map<String, dynamic>.from(rawOrder)
        : null;

    return OrderCreateResult(
      message: json['message'] as String? ?? 'Order completed.',
      order: ShopOrder.fromJson(orderMap ?? <String, dynamic>{}),
    );
  }

  final String message;
  final ShopOrder order;
}

class OrderListResult {
  const OrderListResult({required this.message, required this.orders});

  factory OrderListResult.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['orders'];
    final orders = rawOrders is List
        ? rawOrders
              .whereType<Map>()
              .map(
                (order) => ShopOrder.fromJson(Map<String, dynamic>.from(order)),
              )
              .toList()
        : const <ShopOrder>[];

    return OrderListResult(
      message: json['message'] as String? ?? 'Orders loaded.',
      orders: orders,
    );
  }

  final String message;
  final List<ShopOrder> orders;
}

class LatestOrderResult {
  const LatestOrderResult({required this.message, required this.order});

  factory LatestOrderResult.fromJson(Map<String, dynamic> json) {
    final rawOrder = json['order'];
    final orderMap = rawOrder is Map
        ? Map<String, dynamic>.from(rawOrder)
        : null;

    return LatestOrderResult(
      message: json['message'] as String? ?? 'Latest order loaded.',
      order: orderMap == null ? null : ShopOrder.fromJson(orderMap),
    );
  }

  final String message;
  final ShopOrder? order;
}

class AssistedOrderRequestResult {
  const AssistedOrderRequestResult({
    required this.orderId,
    required this.orderCode,
    required this.status,
    required this.message,
    required this.requiresPin,
  });

  factory AssistedOrderRequestResult.fromJson(Map<String, dynamic> json) {
    final rawOrder = json['order'];
    final orderMap = rawOrder is Map
        ? Map<String, dynamic>.from(rawOrder)
        : null;
    final orderId =
        json['orderId']?.toString() ??
        orderMap?['id']?.toString() ??
        json['assistedOrderRequestId']?.toString() ??
        '';
    final status = json['status']?.toString() ?? 'PENDING_PIN';
    final normalizedStatus = status.toUpperCase();

    return AssistedOrderRequestResult(
      orderId: orderId,
      orderCode: orderMap?['orderCode']?.toString() ?? '',
      status: status,
      message:
          json['message'] as String? ??
          (normalizedStatus == 'DRAFT'
              ? 'Order request saved as draft.'
              : 'Confirmation PIN sent to the shop owner.'),
      requiresPin:
          json['requiresPin'] == true ||
          (normalizedStatus != 'DRAFT' && normalizedStatus != 'CONFIRMED'),
    );
  }

  final String orderId;
  final String orderCode;
  final String status;
  final String message;
  final bool requiresPin;
}

class AssistedOrderConfirmationResult {
  const AssistedOrderConfirmationResult({
    required this.orderId,
    required this.orderCode,
    required this.message,
  });

  factory AssistedOrderConfirmationResult.fromJson(Map<String, dynamic> json) {
    final rawOrder = json['order'];
    final orderMap = rawOrder is Map
        ? Map<String, dynamic>.from(rawOrder)
        : null;

    return AssistedOrderConfirmationResult(
      orderId: json['orderId']?.toString() ?? orderMap?['id']?.toString() ?? '',
      orderCode:
          json['orderCode']?.toString() ??
          orderMap?['orderCode']?.toString() ??
          '',
      message:
          json['message'] as String? ??
          'Assisted order confirmed successfully.',
    );
  }

  final String orderId;
  final String orderCode;
  final String message;
}

class ImmediateDeliveryItem {
  const ImmediateDeliveryItem({
    required this.productId,
    required this.productName,
    required this.requestedCases,
    required this.deliveredCases,
    required this.pendingCases,
  });

  factory ImmediateDeliveryItem.fromJson(Map<String, dynamic> json) {
    return ImmediateDeliveryItem(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? 'Product',
      requestedCases: _readInt(json['requestedCases']),
      deliveredCases: _readInt(json['deliveredCases']),
      pendingCases: _readInt(json['pendingCases']),
    );
  }

  final String productId;
  final String productName;
  final int requestedCases;
  final int deliveredCases;
  final int pendingCases;
}

class ImmediateDeliveryResult {
  const ImmediateDeliveryResult({
    required this.message,
    required this.outcome,
    required this.deliveredItems,
    required this.pendingItems,
    this.backorderCode,
  });

  factory ImmediateDeliveryResult.fromJson(Map<String, dynamic> json) {
    final rawDelivery = json['delivery'];
    final delivery = rawDelivery is Map
        ? Map<String, dynamic>.from(rawDelivery)
        : <String, dynamic>{};
    final rawBackorder = delivery['backorder'];
    final backorder = rawBackorder is Map
        ? Map<String, dynamic>.from(rawBackorder)
        : null;

    return ImmediateDeliveryResult(
      message: json['message'] as String? ?? 'Delivery completed.',
      outcome:
          delivery['outcome']?.toString() ?? json['status']?.toString() ?? '',
      deliveredItems: _mapImmediateDeliveryItems(delivery['deliveredItems']),
      pendingItems: _mapImmediateDeliveryItems(delivery['pendingItems']),
      backorderCode: backorder?['orderCode']?.toString(),
    );
  }

  final String message;
  final String outcome;
  final List<ImmediateDeliveryItem> deliveredItems;
  final List<ImmediateDeliveryItem> pendingItems;
  final String? backorderCode;
}

class OrderService {
  OrderService({Dio? dio}) : _dio = dio ?? DioClient.instance.client;

  final Dio _dio;

  Future<OrderListResult> fetchOrders() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/orders');
      return OrderListResult.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw OrderServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to load orders right now.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  Future<LatestOrderResult> fetchLatestOrder() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/orders/latest');
      return LatestOrderResult.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw OrderServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to load the previous order right now.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  Future<OrderCreateResult> placeOrder(
    List<ShopCartItem> items, {
    String? appliedPromotionId,
    String? appliedPromotionCode,
    double? discountAmount,
    String? paymentMethod,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders',
        data: <String, dynamic>{
          'items': items
              .map(
                (item) => <String, dynamic>{
                  'productId': item.product.id,
                  'quantity': item.quantity,
                },
              )
              .toList(),
          if (appliedPromotionId != null && appliedPromotionId.trim().isNotEmpty)
            'appliedPromotionId': appliedPromotionId.trim(),
          if (appliedPromotionCode != null &&
              appliedPromotionCode.trim().isNotEmpty)
            'appliedPromotionCode': appliedPromotionCode.trim(),
          ...?discountAmount == null
              ? null
              : <String, dynamic>{'discountAmount': discountAmount},
          ...?(paymentMethod == null || paymentMethod.trim().isEmpty)
              ? null
              : <String, dynamic>{'paymentMethod': paymentMethod.trim()},
        },
      );

      return OrderCreateResult.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw OrderServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to place the order right now.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  Future<AssistedOrderRequestResult> requestAssistedOrderResult(
    String routeId,
    String shopId,
    List<ShopCartItem> items,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders/sales-rep/request-pin',
        data: <String, dynamic>{
          'routeId': routeId,
          'shopId': shopId,
          'items': items
              .map(
                (item) => <String, dynamic>{
                  'productId': item.product.id,
                  'quantity': item.quantity,
                },
              )
              .toList(growable: false),
        },
      );

      return AssistedOrderRequestResult.fromJson(
        response.data ?? <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw OrderServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to submit the assisted order request.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  Future<String> requestAssistedOrder(
    String routeId,
    String shopId,
    List<ShopCartItem> items,
  ) async {
    final result = await requestAssistedOrderResult(routeId, shopId, items);
    return result.orderId;
  }

  Future<AssistedOrderConfirmationResult> confirmAssistedOrderResult(
    String orderId,
    String pin,
    String reason,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders/sales-rep/$orderId/confirm-pin',
        data: <String, dynamic>{'pin': pin, 'assistedReason': reason},
      );

      return AssistedOrderConfirmationResult.fromJson(
        response.data ?? <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw OrderServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to confirm the assisted order.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  Future<void> confirmAssistedOrder(
    String orderId,
    String pin,
    String reason,
  ) async {
    await confirmAssistedOrderResult(orderId, pin, reason);
  }

  Future<ImmediateDeliveryResult> completeImmediateSalesRepDelivery({
    required String orderId,
    required String routeId,
    required String confirmationNote,
    DateTime? nextDeliveryDate,
  }) async {
    final payload = <String, dynamic>{
      'orderId': orderId,
      'routeId': routeId,
      'confirmationNote': confirmationNote,
      if (nextDeliveryDate != null)
        'nextDeliveryDate': nextDeliveryDate.toIso8601String(),
    };

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders/sales-rep/deliver-now',
        data: payload,
      );

      return ImmediateDeliveryResult.fromJson(
        response.data ?? <String, dynamic>{},
      );
    } on DioException catch (error) {
      if (_isMissingDeliveryEndpoint(error)) {
        try {
          final retryResponse = await _dio.post<Map<String, dynamic>>(
            '/orders/sales-rep/$orderId/deliver-now',
            data: payload,
          );
          return ImmediateDeliveryResult.fromJson(
            retryResponse.data ?? <String, dynamic>{},
          );
        } on DioException catch (retryError) {
          if (_isMissingDeliveryEndpoint(retryError)) {
            throw const OrderServiceException(
              'The delivery completion API is not active on this server yet. The order has already been submitted for TM approval.',
              code: 'DELIVERY_ENDPOINT_UNAVAILABLE',
            );
          }
          throw OrderServiceException(
            extractBackendErrorMessage(
              retryError,
              fallbackMessage: 'Unable to complete the delivery right now.',
            ),
            code: extractBackendErrorCode(retryError),
          );
        }
      }

      throw OrderServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to complete the delivery right now.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }
}

bool _isMissingDeliveryEndpoint(DioException error) {
  final statusCode = error.response?.statusCode;
  final rawData = error.response?.data;
  final message = rawData is Map
      ? rawData['message']?.toString() ?? ''
      : rawData?.toString() ?? '';

  return statusCode == 404 &&
      message.toLowerCase().contains('cannot post') &&
      message.toLowerCase().contains('deliver-now');
}

List<ImmediateDeliveryItem> _mapImmediateDeliveryItems(dynamic raw) {
  if (raw is! List) {
    return const <ImmediateDeliveryItem>[];
  }

  return raw
      .whereType<Map>()
      .map(
        (item) =>
            ImmediateDeliveryItem.fromJson(Map<String, dynamic>.from(item)),
      )
      .toList(growable: false);
}

int _readInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
