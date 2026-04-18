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
    final orderMap = rawOrder is Map ? Map<String, dynamic>.from(rawOrder) : null;

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
              .map((order) => ShopOrder.fromJson(Map<String, dynamic>.from(order)))
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
    final orderMap = rawOrder is Map ? Map<String, dynamic>.from(rawOrder) : null;

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
    required this.status,
    required this.message,
    required this.requiresPin,
  });

  factory AssistedOrderRequestResult.fromJson(Map<String, dynamic> json) {
    final rawOrder = json['order'];
    final orderMap = rawOrder is Map ? Map<String, dynamic>.from(rawOrder) : null;
    final orderId =
        json['orderId']?.toString() ??
        orderMap?['id']?.toString() ??
        json['assistedOrderRequestId']?.toString() ??
        '';
    final status = json['status']?.toString() ?? 'PENDING_PIN';
    final normalizedStatus = status.toUpperCase();

    return AssistedOrderRequestResult(
      orderId: orderId,
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
    final orderMap = rawOrder is Map ? Map<String, dynamic>.from(rawOrder) : null;

    return AssistedOrderConfirmationResult(
      orderId:
          json['orderId']?.toString() ??
          orderMap?['id']?.toString() ??
          '',
      orderCode:
          json['orderCode']?.toString() ??
          orderMap?['orderCode']?.toString() ??
          '',
      message:
          json['message'] as String? ?? 'Assisted order confirmed successfully.',
    );
  }

  final String orderId;
  final String orderCode;
  final String message;
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
          'appliedPromotionId': ?appliedPromotionId,
          'appliedPromotionCode': ?appliedPromotionCode,
          'discountAmount': ?discountAmount,
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
    String shopId,
    List<ShopCartItem> items,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders/rep-request',
        data: <String, dynamic>{
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
    String shopId,
    List<ShopCartItem> items,
  ) async {
    final result = await requestAssistedOrderResult(shopId, items);
    return result.orderId;
  }

  Future<AssistedOrderConfirmationResult> confirmAssistedOrderResult(
    String orderId,
    String pin,
    String reason,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders/rep-confirm',
        data: <String, dynamic>{
          'orderId': orderId,
          'pin': pin,
          'assistedReason': reason,
        },
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
}
