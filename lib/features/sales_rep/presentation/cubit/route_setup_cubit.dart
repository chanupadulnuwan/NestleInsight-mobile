import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/sales_rep/data/services/route_setup_service.dart';

abstract class RouteSetupState {}

class RouteSetupInitial extends RouteSetupState {}

class RouteSetupLoading extends RouteSetupState {}

class RouteSetupTeritoriesLoaded extends RouteSetupState {
  RouteSetupTeritoriesLoaded(this.territories);

  final List<Territory> territories;
}

class RouteSetupWarehousesLoaded extends RouteSetupState {
  RouteSetupWarehousesLoaded(
    this.territories,
    this.warehouses,
    this.selectedTerritoryId,
  );

  final List<Territory> territories;
  final List<Warehouse> warehouses;
  final String selectedTerritoryId;
}

class RouteSetupError extends RouteSetupState {
  RouteSetupError(this.message);

  final String message;
}

class RouteSetupCubit extends Cubit<RouteSetupState> {
  RouteSetupCubit({RouteSetupService? routeSetupService})
    : _routeSetupService = routeSetupService ?? RouteSetupService(),
      super(RouteSetupInitial());

  final RouteSetupService _routeSetupService;

  Future<void> loadTerritories() async {
    emit(RouteSetupLoading());

    try {
      final territories = await _routeSetupService.fetchTerritories();
      emit(RouteSetupTeritoriesLoaded(territories));
    } on RouteSetupServiceException catch (error) {
      emit(RouteSetupError(error.message));
    }
  }

  Future<void> selectTerritory(String territoryId) async {
    final currentState = state;
    if (currentState is RouteSetupTeritoriesLoaded) {
      emit(RouteSetupLoading());

      try {
        final warehouses = await _routeSetupService.fetchWarehouses(
          territoryId: territoryId,
        );
        emit(
          RouteSetupWarehousesLoaded(
            currentState.territories,
            warehouses,
            territoryId,
          ),
        );
      } on RouteSetupServiceException catch (error) {
        emit(RouteSetupError(error.message));
        emit(RouteSetupTeritoriesLoaded(currentState.territories));
      }
    }
  }
}
