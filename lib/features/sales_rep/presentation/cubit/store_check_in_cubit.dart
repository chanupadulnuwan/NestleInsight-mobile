import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/sales_rep/data/services/store_check_in_service.dart';

abstract class StoreCheckInState {}

class StoreCheckInInitial extends StoreCheckInState {}

class StoreCheckInLoading extends StoreCheckInState {}

class StoreCheckInSuccess extends StoreCheckInState {
  StoreCheckInSuccess(this.message, this.visitId);

  final String message;
  final String visitId;
}

class StoreCheckInError extends StoreCheckInState {
  StoreCheckInError(this.message);

  final String message;
}

class StoreCheckInCubit extends Cubit<StoreCheckInState> {
  StoreCheckInCubit({StoreCheckInService? checkInService})
    : _checkInService = checkInService ?? StoreCheckInService(),
      super(StoreCheckInInitial());

  final StoreCheckInService _checkInService;

  Future<void> checkInToStore({
    required String routeId,
    required String shopId,
    String? visitNotes,
  }) async {
    emit(StoreCheckInLoading());

    try {
      final request = StoreCheckInRequest(
        routeId: routeId,
        shopId: shopId,
        visitNotes: visitNotes,
      );

      final response = await _checkInService.checkInStore(request);
      emit(StoreCheckInSuccess(response.message, response.visitId));
    } on StoreCheckInException catch (error) {
      emit(StoreCheckInError(error.message));
    }
  }
}
