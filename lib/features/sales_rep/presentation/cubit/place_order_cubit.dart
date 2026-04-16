import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/sales_rep/data/models/order_models.dart';
import 'package:mobile/features/sales_rep/data/services/place_order_service.dart';

abstract class PlaceOrderState {}

class PlaceOrderInitial extends PlaceOrderState {}

class PlaceOrderLoading extends PlaceOrderState {}

class PlaceOrderSuccess extends PlaceOrderState {
  PlaceOrderSuccess(this.message, this.orderId);

  final String message;
  final String orderId;
}

class PlaceOrderError extends PlaceOrderState {
  PlaceOrderError(this.message);

  final String message;
}

class PlaceOrderCubit extends Cubit<PlaceOrderState> {
  PlaceOrderCubit({PlaceOrderService? orderService})
    : _orderService = orderService ?? PlaceOrderService(),
      super(PlaceOrderInitial());

  final PlaceOrderService _orderService;

  Future<void> placeOrder({
    required String routeId,
    required String shopId,
    required Map<String, int> cart,
  }) async {
    if (cart.isEmpty) {
      emit(PlaceOrderError('Cart is empty'));
      return;
    }

    emit(PlaceOrderLoading());

    try {
      final items = cart.entries
          .map(
            (entry) => OrderItem(productId: entry.key, quantity: entry.value),
          )
          .toList();

      final request = CreateSalesOrderRequest(
        routeId: routeId,
        shopId: shopId,
        items: items,
      );

      final response = await _orderService.placeOrder(request);
      final orderId = response['order']?['id'] ?? '';
      final message = response['message'] ?? 'Order placed successfully!';

      emit(PlaceOrderSuccess(message, orderId));
    } on PlaceOrderException catch (error) {
      emit(PlaceOrderError(error.message));
    }
  }
}
