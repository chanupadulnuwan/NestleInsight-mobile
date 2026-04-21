import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/sales_rep/data/services/route_service.dart';

abstract class RouteState {}

class RouteInitial extends RouteState {}

class RouteLoading extends RouteState {}

class RouteLoaded extends RouteState {
  RouteLoaded(this.activeRoute);

  final SalesRoute? activeRoute;
}

class RouteError extends RouteState {
  RouteError(this.message);

  final String message;
}

class RouteActionSuccess extends RouteState {
  RouteActionSuccess(this.message, this.route);

  final String message;
  final SalesRoute? route;
}

class RouteCubit extends Cubit<RouteState> {
  RouteCubit({RouteService? routeService})
    : _routeService = routeService ?? RouteService(),
      super(RouteInitial());

  final RouteService _routeService;

  SalesRoute? get currentRoute {
    final currentState = state;
    if (currentState is RouteLoaded) {
      return currentState.activeRoute;
    }
    if (currentState is RouteActionSuccess) {
      return currentState.route;
    }
    return null;
  }

  Future<bool> loadRoute() async {
    emit(RouteLoading());

    try {
      final route = await _routeService.fetchMyRoute();
      emit(RouteLoaded(route));
      return true;
    } on RouteServiceException catch (error) {
      emit(RouteError(error.message));
      return false;
    }
  }

  Future<bool> createRoute({
    required String warehouseId,
    required String vehicleId,
  }) async {
    final previousRoute = currentRoute;
    emit(RouteLoading());

    try {
      final result = await _routeService.createRoute(
        warehouseId: warehouseId,
        vehicleId: vehicleId,
      );
      emit(RouteActionSuccess(result.message, result.route));
      emit(RouteLoaded(result.route));
      return true;
    } on RouteServiceException catch (error) {
      emit(RouteError(error.message));
      emit(RouteLoaded(previousRoute));
      return false;
    }
  }

  Future<bool> updateBeatPlan({
    required String routeId,
    required List<String> selectedOutletIds,
    required List<String> selectedShopOwnerIds,
  }) async {
    final previousRoute = currentRoute;
    emit(RouteLoading());

    try {
      final result = await _routeService.updateBeatPlan(
        routeId: routeId,
        selectedOutletIds: selectedOutletIds,
        selectedShopOwnerIds: selectedShopOwnerIds,
      );
      final nextRoute = result.route ?? await _routeService.fetchMyRoute();
      emit(RouteActionSuccess(result.message, nextRoute));
      emit(RouteLoaded(nextRoute));
      return true;
    } on RouteServiceException catch (error) {
      emit(RouteError(error.message));
      emit(RouteLoaded(previousRoute));
      return false;
    }
  }

  Future<bool> requestDeliveryApproval({
    required String routeId,
    required List<String> orderIds,
  }) async {
    final previousRoute = currentRoute;
    emit(RouteLoading());

    try {
      final result = await _routeService.requestDeliveryApproval(
        routeId: routeId,
        orderIds: orderIds,
      );
      final refreshedRoute = await _routeService.fetchMyRoute();
      emit(RouteActionSuccess(result.message, refreshedRoute));
      emit(RouteLoaded(refreshedRoute));
      return true;
    } on RouteServiceException catch (error) {
      emit(RouteError(error.message));
      emit(RouteLoaded(previousRoute));
      return false;
    }
  }

  Future<bool> confirmDeliveryApprovalPin({
    required String approvalRequestId,
    required String pin,
  }) async {
    final previousRoute = currentRoute;
    emit(RouteLoading());

    try {
      final result = await _routeService.confirmDeliveryApprovalPin(
        approvalRequestId: approvalRequestId,
        pin: pin,
      );
      final refreshedRoute = await _routeService.fetchMyRoute();
      emit(RouteActionSuccess(result.message, refreshedRoute));
      emit(RouteLoaded(refreshedRoute));
      return true;
    } on RouteServiceException catch (error) {
      emit(RouteError(error.message));
      emit(RouteLoaded(previousRoute));
      return false;
    }
  }

  Future<bool> submitLoadRequest({
    required String routeId,
    required List<StockLine> deliveryStock,
    required List<StockLine> freeSaleStock,
  }) async {
    final previousRoute = currentRoute;
    emit(RouteLoading());

    try {
      final result = await _routeService.submitLoadRequest(
        routeId: routeId,
        deliveryStock: deliveryStock,
        freeSaleStock: freeSaleStock,
      );
      final refreshedRoute = await _routeService.fetchMyRoute();
      emit(RouteActionSuccess(result.message, refreshedRoute));
      emit(RouteLoaded(refreshedRoute));
      return true;
    } on RouteServiceException catch (error) {
      emit(RouteError(error.message));
      emit(RouteLoaded(previousRoute));
      return false;
    }
  }

  Future<bool> enterPin({required String routeId, required String pin}) async {
    final previousRoute = currentRoute;
    emit(RouteLoading());

    try {
      final result = await _routeService.enterStartPin(
        routeId: routeId,
        pin: pin,
      );
      final nextRoute = result.route ?? await _routeService.fetchMyRoute();
      emit(RouteActionSuccess(result.message, nextRoute));
      emit(RouteLoaded(nextRoute));
      return true;
    } on RouteServiceException catch (error) {
      emit(RouteError(error.message));
      emit(RouteLoaded(previousRoute));
      return false;
    }
  }

  Future<bool> cancelRoute({required String routeId}) async {
    emit(RouteLoading());
    try {
      final result = await _routeService.cancelRoute(routeId: routeId);
      emit(RouteActionSuccess(result.message, null));
      emit(RouteLoaded(null));
      return true;
    } on RouteServiceException catch (error) {
      emit(RouteError(error.message));
      emit(RouteLoaded(currentRoute));
      return false;
    }
  }

  Future<bool> requestPinRefresh({required String routeId}) async {
    final previousRoute = currentRoute;
    emit(RouteLoading());
    try {
      final result = await _routeService.requestPinRefresh(routeId: routeId);
      final refreshedRoute = await _routeService.fetchMyRoute();
      emit(RouteActionSuccess(result.message, refreshedRoute));
      emit(RouteLoaded(refreshedRoute));
      return true;
    } on RouteServiceException catch (error) {
      emit(RouteError(error.message));
      emit(RouteLoaded(previousRoute));
      return false;
    }
  }

  Future<bool> closeRoute({
    required String routeId,
    required String pin,
    required List<CloseStockLineInput> closingStock,
    required List<ReturnItemInput> returnItems,
    String? varianceReason,
  }) async {
    final previousRoute = currentRoute;
    emit(RouteLoading());

    try {
      final result = await _routeService.closeRoute(
        routeId: routeId,
        pin: pin,
        closingStock: closingStock,
        returnItems: returnItems,
        varianceReason: varianceReason,
      );
      emit(RouteActionSuccess(result.message, result.route));
      emit(RouteLoaded(result.route));
      return true;
    } on RouteServiceException catch (error) {
      emit(RouteError(error.message));
      emit(RouteLoaded(previousRoute));
      return false;
    }
  }
}
