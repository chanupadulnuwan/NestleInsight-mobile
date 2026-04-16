import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/services/outlet_visit_service.dart';
import '../../data/services/visit_service.dart';

abstract class OutletVisitState {}

class OutletVisitInitial extends OutletVisitState {}

class OutletVisitLoadingOutlets extends OutletVisitState {}

class OutletVisitOutletsLoaded extends OutletVisitState {
  final List<TerritoryOutlet> outlets;
  OutletVisitOutletsLoaded(this.outlets);
}

class OutletVisitInProgress extends OutletVisitState {
  final StoreVisit visit;
  final TerritoryOutlet? selectedOutlet;
  OutletVisitInProgress({required this.visit, this.selectedOutlet});
}

class OutletVisitCompleted extends OutletVisitState {
  final String message;
  final int durationSeconds;
  OutletVisitCompleted({required this.message, required this.durationSeconds});
}

class OutletVisitError extends OutletVisitState {
  final String message;
  OutletVisitError(this.message);
}

class OutletVisitCubit extends Cubit<OutletVisitState> {
  final OutletVisitService _outletVisitService = OutletVisitService();
  final VisitService _visitService = VisitService();

  OutletVisitCubit() : super(OutletVisitInitial());

  Future<(double, double)?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return null;
    } 

    try {
      final position = await Geolocator.getCurrentPosition();
      return (position.latitude, position.longitude);
    } catch (e) {
      return null;
    }
  }

  Future<void> loadOutlets() async {
    emit(OutletVisitLoadingOutlets());
    try {
      final outlets = await _outletVisitService.fetchMyOutlets();
      emit(OutletVisitOutletsLoaded(outlets));
    } on OutletVisitServiceException catch (e) {
      emit(OutletVisitError(e.message));
    } catch (e) {
      emit(OutletVisitError('Failed to load outlets: $e'));
    }
  }

  Future<void> startVisit({
    required String routeId,
    required String territoryId,
    required TerritoryOutlet outlet,
  }) async {
    emit(OutletVisitLoadingOutlets());
    try {
      final location = await _getCurrentLocation();
      final lat = location?.$1 ?? outlet.latitude ?? 0.0;
      final lng = location?.$2 ?? outlet.longitude ?? 0.0;

      final res = await _visitService.startVisit(
        routeId: routeId,
        shopId: outlet.id,
        shopName: outlet.outletName,
        latitude: lat,
        longitude: lng,
        territoryId: territoryId,
      );

      emit(OutletVisitInProgress(visit: res.visit, selectedOutlet: outlet));
    } on VisitServiceException catch (e) {
      emit(OutletVisitError(e.message));
    } catch (e) {
      emit(OutletVisitError('Failed to start visit: $e'));
    }
  }

  Future<void> completeVisit({
    required String visitId,
    bool? planogramOk,
    bool? posmOk,
    String? osaNote,
    String? feedback,
  }) async {
    final currentState = state;
    if (currentState is! OutletVisitInProgress) return;

    emit(OutletVisitLoadingOutlets()); // Show loading while completing
    try {
      final osaIssuesJson = osaNote != null && osaNote.isNotEmpty
          ? {'note': osaNote}
          : null;

      final res = await _visitService.completeVisit(
        visitId: visitId,
        planogramOk: planogramOk,
        posmOk: posmOk,
        osaIssues: osaIssuesJson,
        feedback: feedback,
      );

      emit(OutletVisitCompleted(
        message: res.message,
        durationSeconds: res.durationSeconds,
      ));
    } on VisitServiceException catch (e) {
      emit(OutletVisitError(e.message));
    } catch (e) {
      emit(OutletVisitError('Failed to complete visit: $e'));
    }
  }
}
