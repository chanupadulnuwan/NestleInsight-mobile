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
        stockItems: _normalizeStockItems(shelfStock, backroomStock),
        osaIssues: _normalizeListMap(osaIssues),
        promotionChecks: _normalizeListMap(promotions),
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

  Future<bool> uploadPhoto({
    required String visitId,
    required String filePath,
  }) async {
    // Keep internal local loading if we want, but for now just pass through
    try {
      await _visitService.uploadVisitPhoto(
        visitId: visitId,
        filePath: filePath,
      );
      // Optional: Refresh visit state if we want to show the new URL immediately
      return true;
    } on VisitServiceException catch (error) {
      emit(VisitError(error.message));
      return false;
    }
  }
}

List<Map<String, dynamic>>? _normalizeListMap(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
  if (value is Map) {
    return [Map<String, dynamic>.from(value)];
  }
  return null;
}

List<Map<String, dynamic>>? _normalizeStockItems(
  dynamic shelfStock,
  dynamic backroomStock,
) {
  final stockItems = _normalizeListMap(shelfStock);
  if (stockItems != null) {
    return stockItems;
  }

  final shelfMap = shelfStock is Map
      ? Map<String, dynamic>.from(shelfStock)
      : null;
  final backroomMap = backroomStock is Map
      ? Map<String, dynamic>.from(backroomStock)
      : null;
  if (shelfMap == null && backroomMap == null) {
    return null;
  }

  final productIds = <String>{
    ...?shelfMap?.keys.map((key) => key.toString()),
    ...?backroomMap?.keys.map((key) => key.toString()),
  };
  return productIds
      .map(
        (productId) => <String, dynamic>{
          'productId': productId,
          'shelfCount': shelfMap?[productId] ?? 0,
          'backroomCount': backroomMap?[productId] ?? 0,
        },
      )
      .toList(growable: false);
}
