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

  Future<OrderCreateResult> placeOrder(List<ShopCartItem> items) async {
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
}
