import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/sales_rep/data/services/route_return_progress_store.dart';

import '../../data/services/sales_return_service.dart';

abstract class SalesReturnState {}

class SalesReturnInitial extends SalesReturnState {}

class SalesReturnSubmitting extends SalesReturnState {}

class SalesReturnSuccess extends SalesReturnState {
  final String message;
  SalesReturnSuccess(this.message);
}

class SalesReturnError extends SalesReturnState {
  final String message;
  SalesReturnError(this.message);
}

class SalesReturnCubit extends Cubit<SalesReturnState> {
  final SalesReturnService _service = SalesReturnService();
  final RouteReturnProgressStore _returnProgressStore =
      RouteReturnProgressStore();

  SalesReturnCubit() : super(SalesReturnInitial());

  Future<void> submitReturn({
    required String routeId,
    required List<ReturnItemLog> items,
  }) async {
    if (items.isEmpty) {
      emit(SalesReturnError('No items to return.'));
      return;
    }

    emit(SalesReturnSubmitting());
    try {
      // Loop sequentially to avoid overwhelming the server + easier error mapping
      for (final item in items) {
        await _service.logReturn(routeId: routeId, item: item);
      }
      await _returnProgressStore.addReturnItems(routeId: routeId, items: items);
      emit(SalesReturnSuccess('Returns logged successfully'));
    } on SalesReturnServiceException catch (e) {
      emit(SalesReturnError(e.message));
    } catch (e) {
      emit(SalesReturnError('Failed to submit returns: $e'));
    }
  }
}
