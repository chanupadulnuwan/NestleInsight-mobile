import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/sales_rep/data/services/visit_service.dart';

abstract class VisitState {}

class VisitInitial extends VisitState {}

class VisitLoading extends VisitState {}

class VisitInProgress extends VisitState {
  VisitInProgress(this.visit);

  final StoreVisit visit;
}

class VisitCompleted extends VisitState {
  VisitCompleted(this.message, this.durationSeconds);

  final String message;
  final int durationSeconds;
}

class VisitError extends VisitState {
  VisitError(this.message);

  final String message;
}

class VisitCubit extends Cubit<VisitState> {
  VisitCubit({VisitService? visitService})
    : _visitService = visitService ?? VisitService(),
      super(VisitInitial());

  final VisitService _visitService;

  StoreVisit? get currentVisit {
    final currentState = state;
    if (currentState is VisitInProgress) {
      return currentState.visit;
    }
    return null;
  }

  Future<bool> startVisit({
    required String routeId,
    String? shopId,
    required String shopName,
    required double latitude,
    required double longitude,
    required String territoryId,
  }) async {
    emit(VisitLoading());

    try {
      final result = await _visitService.startVisit(
        routeId: routeId,
        shopId: shopId,
        shopName: shopName,
        latitude: latitude,
        longitude: longitude,
        territoryId: territoryId,
      );

      emit(VisitInProgress(result.visit));
      return true;
    } on VisitServiceException catch (error) {
      emit(VisitError(error.message));
      return false;
    }
  }

  Future<bool> completeVisit({
    required String visitId,
    dynamic shelfStock,
    dynamic backroomStock,
    dynamic osaIssues,
    dynamic promotions,
    bool? planogramOk,
    bool? posmOk,
    String? feedback,
  }) async {
    emit(VisitLoading());

    try {
      final result = await _visitService.completeVisit(
        visitId: visitId,
        shelfStock: shelfStock,
        backroomStock: backroomStock,
        osaIssues: osaIssues,
        promotions: promotions,
        planogramOk: planogramOk,
        posmOk: posmOk,
        feedback: feedback,
      );

      emit(VisitCompleted(result.message, result.durationSeconds));
      return true;
    } on VisitServiceException catch (error) {
      emit(VisitError(error.message));
      return false;
    }
  }
}
