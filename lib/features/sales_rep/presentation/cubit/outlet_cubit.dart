import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/outlet_service.dart';

part 'outlet_state.dart';

class OutletCubit extends Cubit<OutletState> {
  final OutletService _outletService;

  OutletCubit({OutletService? outletService})
    : _outletService = outletService ?? OutletService(),
      super(OutletInitial());

  Future<bool> registerOutlet({
    required String name,
    required String owner,
    required String phone,
    required String email,
    required String address,
    required double latitude,
    required double longitude,
    required String territoryId,
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
        territoryId: '',
      );

      emit(OutletSuccess(result.message, result.outlet));
      return true;
    } catch (error) {
      // The Ultimate Failsafe Catch
      final errorMessage = error is OutletServiceException
          ? error.message
          : 'Failed to connect to server: $error';

      emit(OutletError(errorMessage));
      return false;
    }
  }
}
