import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/sales_rep/data/services/route_setup_service.dart';

abstract class RouteSetupState {}

class RouteSetupInitial extends RouteSetupState {}

class RouteSetupLoading extends RouteSetupState {}

class RouteSetupLoaded extends RouteSetupState {
  RouteSetupLoaded(this.options);

  final RouteSetupOptions options;
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

  Future<void> loadSetupOptions() async {
    emit(RouteSetupLoading());

    try {
      final options = await _routeSetupService.fetchSetupOptions();
      emit(RouteSetupLoaded(options));
    } on RouteSetupServiceException catch (error) {
      emit(RouteSetupError(error.message));
    }
  }
}
