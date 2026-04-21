import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/orders/data/services/order_service.dart';
import 'package:mobile/features/orders/domain/shop_cart_item.dart';

abstract class RepOrderState {
  const RepOrderState();
}

class RepOrderInitial extends RepOrderState {
  const RepOrderInitial();
}

class RepOrderLoading extends RepOrderState {
  const RepOrderLoading({this.orderId});

  final String? orderId;
}

class RepOrderPendingPin extends RepOrderState {
  const RepOrderPendingPin({required this.orderId, required this.message});

  final String orderId;
  final String message;
}

class RepOrderDraftSaved extends RepOrderState {
  const RepOrderDraftSaved({required this.orderId, required this.message});

  final String orderId;
  final String message;
}

class RepOrderSuccess extends RepOrderState {
  const RepOrderSuccess({
    required this.orderId,
    required this.orderCode,
    required this.message,
    required this.assistedReason,
  });

  final String orderId;
  final String orderCode;
  final String message;
  final String assistedReason;
}

class RepOrderError extends RepOrderState {
  const RepOrderError(this.message, {this.orderId});

  final String message;
  final String? orderId;
}

class RepOrderCubit extends Cubit<RepOrderState> {
  RepOrderCubit({OrderService? orderService})
    : _orderService = orderService ?? OrderService(),
      super(const RepOrderInitial());

  final OrderService _orderService;
  List<ShopCartItem> _cartItems = const <ShopCartItem>[];

  void syncCartItems(List<ShopCartItem> items) {
    _cartItems = List<ShopCartItem>.unmodifiable(items);
  }

  Future<void> submitOrderRequest({
    required String routeId,
    required String shopId,
  }) async {
    if (_cartItems.isEmpty) {
      emit(const RepOrderError('Add at least one product before submitting.'));
      return;
    }

    emit(const RepOrderLoading());

    try {
      final result = await _orderService.requestAssistedOrderResult(
        routeId,
        shopId,
        _cartItems,
      );

      final normalizedStatus = result.status.toUpperCase();
      if (normalizedStatus == 'CONFIRMED' || normalizedStatus == 'COMPLETED') {
        emit(
          RepOrderSuccess(
            orderId: result.orderId,
            orderCode: result.orderCode,
            message: result.message,
            assistedReason: 'Captured during store visit',
          ),
        );
        return;
      }

      if (normalizedStatus == 'DRAFT' || !result.requiresPin) {
        emit(
          RepOrderDraftSaved(orderId: result.orderId, message: result.message),
        );
        return;
      }

      emit(
        RepOrderPendingPin(orderId: result.orderId, message: result.message),
      );
    } on OrderServiceException catch (error) {
      emit(RepOrderError(error.message));
    }
  }

  Future<void> confirmOrder(String orderId, String pin, String reason) async {
    if (orderId.trim().isEmpty) {
      emit(const RepOrderError('Missing order reference for confirmation.'));
      return;
    }

    if (pin.trim().length < 4) {
      emit(RepOrderError('Enter the shop owner PIN.', orderId: orderId));
      return;
    }

    if (reason.trim().length < 5) {
      emit(
        RepOrderError(
          'Enter a short reason for the assisted order.',
          orderId: orderId,
        ),
      );
      return;
    }

    emit(RepOrderLoading(orderId: orderId));

    try {
      final result = await _orderService.confirmAssistedOrderResult(
        orderId,
        pin.trim(),
        reason.trim(),
      );

      emit(
        RepOrderSuccess(
          orderId: result.orderId.isEmpty ? orderId : result.orderId,
          orderCode: result.orderCode,
          message: result.message,
          assistedReason: reason.trim(),
        ),
      );
    } on OrderServiceException catch (error) {
      emit(RepOrderError(error.message, orderId: orderId));
    }
  }

  void reset() {
    _cartItems = const <ShopCartItem>[];
    emit(const RepOrderInitial());
  }
}
