import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/sales_rep/data/services/outlet_service.dart';

abstract class OutletState {}

class OutletInitial extends OutletState {}

class OutletLoading extends OutletState {}

class OutletLoaded extends OutletState {
  OutletLoaded(this.outlet);

  final Outlet outlet;
}

class OutletError extends OutletState {
  OutletError(this.message);

  final String message;
}

class OutletSuccess extends OutletState {
  OutletSuccess(this.message, this.outlet);

  final String message;
  final Outlet outlet;
}

class OutletCubit extends Cubit<OutletState> {
  OutletCubit({OutletService? outletService})
    : _outletService = outletService ?? OutletService(),
      super(OutletInitial());

  final OutletService _outletService;

  Future<bool> registerOutlet({
    required String name,
    required String owner,
    required String phone,
    required String email,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    emit(OutletLoading());

    try {
      final result = await _outletService.registerOutlet(
        name: name,
        owner: owner,
        phone: phone,
        email: email,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );

      emit(OutletSuccess(result.message, result.outlet));
      return true;
    } on OutletServiceException catch (error) {
      emit(OutletError(error.message));
      return false;
    }
  }
}
