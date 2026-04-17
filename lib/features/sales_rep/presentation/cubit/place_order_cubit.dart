import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/sales_rep/data/models/order_models.dart';
import 'package:mobile/features/sales_rep/data/services/place_order_service.dart';

abstract class PlaceOrderState {}

class PlaceOrderInitial extends PlaceOrderState {}

class PlaceOrderLoading extends PlaceOrderState {}

class PlaceOrderAwaitingPin extends PlaceOrderState {
  PlaceOrderAwaitingPin({
    required this.message,
    required this.assistedOrderRequestId,
    this.expiresAt,
  });

  final String message;
  final String assistedOrderRequestId;
  final DateTime? expiresAt;
}

class PlaceOrderDraftSaved extends PlaceOrderState {
  PlaceOrderDraftSaved(this.message, this.assistedOrderRequestId);

  final String message;
  final String assistedOrderRequestId;
}

class PlaceOrderSuccess extends PlaceOrderState {
  PlaceOrderSuccess(this.message, this.orderId, this.orderCode);

  final String message;
  final String orderId;
  final String orderCode;
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

  Future<void> requestOrderPin({
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

      final request = RequestAssistedOrderPinRequest(
        routeId: routeId,
        shopId: shopId,
        items: items,
      );

      final response = await _orderService.requestOrderPin(request);

      if (response.requiresPin) {
        emit(
          PlaceOrderAwaitingPin(
            message: response.message,
            assistedOrderRequestId: response.assistedOrderRequestId,
            expiresAt: response.expiresAt,
          ),
        );
        return;
      }

      emit(
        PlaceOrderDraftSaved(
          response.message,
          response.assistedOrderRequestId,
        ),
      );
    } on PlaceOrderException catch (error) {
      emit(PlaceOrderError(error.message));
    }
  }

  Future<void> confirmOrderPin({
    required String assistedOrderRequestId,
    required String pin,
    required String assistedReason,
  }) async {
    if (assistedOrderRequestId.trim().isEmpty) {
      emit(PlaceOrderError('Request a confirmation PIN first.'));
      return;
    }

    if (pin.trim().isEmpty) {
      emit(PlaceOrderError('Enter the 6-digit confirmation PIN.'));
      return;
    }

    if (assistedReason.trim().length < 5) {
      emit(
        PlaceOrderError(
          'Enter a short reason for the assisted order before confirming.',
        ),
      );
      return;
    }

    emit(PlaceOrderLoading());

    try {
      final response = await _orderService.confirmOrderPin(
        assistedOrderRequestId: assistedOrderRequestId,
        request: ConfirmAssistedOrderPinRequest(
          pin: pin.trim(),
          assistedReason: assistedReason.trim(),
        ),
      );

      emit(
        PlaceOrderSuccess(
          response.message,
          response.orderId,
          response.orderCode,
        ),
      );
    } on PlaceOrderException catch (error) {
      emit(PlaceOrderError(error.message));
    }
  }

  void reset() {
    emit(PlaceOrderInitial());
  }
}
