import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/services/smart_route_service.dart';

abstract class SmartRouteState {}

class SmartRouteInitial extends SmartRouteState {}

class SmartRouteLoading extends SmartRouteState {}

class SmartRouteLoaded extends SmartRouteState {
  SmartRouteLoaded({
    required this.session,
    required this.progress,
    required this.rankedOutlets,
    this.currentStop,
    required this.isAllDone,
  });

  final SmartRouteSession session;
  final SmartRouteProgress progress;
  final List<SmartRouteRankedOutlet> rankedOutlets;
  final SmartRouteStop? currentStop;
  final bool isAllDone;
}

class SmartRouteRankedOutlet {
  const SmartRouteRankedOutlet({
    required this.outlet,
    this.distanceKm,
    this.etaMinutes,
    required this.isNearest,
    required this.isSuggestedStop,
  });

  final SmartRouteOutletSummary outlet;
  final double? distanceKm;
  final int? etaMinutes;
  final bool isNearest;
  final bool isSuggestedStop;
}

class SmartRouteError extends SmartRouteState {
  SmartRouteError(this.message);

  final String message;
}

class SmartRouteCubit extends Cubit<SmartRouteState> {
  SmartRouteCubit() : super(SmartRouteInitial());

  final SmartRouteService _service = SmartRouteService();

  Future<(double, double)?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

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
    } catch (_) {
      return null;
    }
  }

  Future<void> loadSession() async {
    emit(SmartRouteLoading());
    try {
      await _reloadSessionAndSuggestion();
    } on SmartRouteServiceException catch (e) {
      emit(SmartRouteError(e.message));
    } catch (e) {
      emit(SmartRouteError('Failed to load session: $e'));
    }
  }

  Future<SmartRouteStop?> startCurrentStop(String stopId) async {
    final currentState = state;
    if (currentState is! SmartRouteLoaded) {
      return null;
    }

    emit(SmartRouteLoading());
    try {
      final startedStop = await _service.startStop(stopId: stopId);
      final refreshedSession = await _service.getOrCreateSession();
      final location = await _getCurrentLocation();
      final progress = await _service.getProgress(sessionId: refreshedSession.id);

      emit(
        SmartRouteLoaded(
          session: refreshedSession,
          progress: progress,
          rankedOutlets: _rankAssignedOutlets(
            outlets: refreshedSession.assignedOutlets,
            currentStop: startedStop,
            currentLatitude: location?.$1,
            currentLongitude: location?.$2,
          ),
          currentStop: startedStop,
          isAllDone: false,
        ),
      );
      return startedStop;
    } on SmartRouteServiceException catch (e) {
      emit(SmartRouteError(e.message));
    } catch (e) {
      emit(SmartRouteError('Failed to start stop: $e'));
    }

    return null;
  }

  Future<void> completeCurrentStop(String stopId) async {
    final currentState = state;
    if (currentState is! SmartRouteLoaded) {
      return;
    }

    emit(SmartRouteLoading());
    try {
      await _service.completeStop(stopId: stopId);
      await _reloadSessionAndSuggestion();
    } on SmartRouteServiceException catch (e) {
      emit(SmartRouteError(e.message));
    } catch (e) {
      emit(SmartRouteError('Failed to complete stop: $e'));
    }
  }

  Future<void> skipCurrentStop({
    required String stopId,
    required String reasonCode,
    required String freeText,
  }) async {
    final currentState = state;
    if (currentState is! SmartRouteLoaded) {
      return;
    }

    emit(SmartRouteLoading());
    try {
      final location = await _getCurrentLocation();
      await _service.skipStop(
        stopId: stopId,
        reasonCode: reasonCode,
        freeText: freeText,
        lat: location?.$1,
        lng: location?.$2,
      );
      await _reloadSessionAndSuggestion();
    } on SmartRouteServiceException catch (e) {
      emit(SmartRouteError(e.message));
    } catch (e) {
      emit(SmartRouteError('Failed to skip stop: $e'));
    }
  }

  Future<void> refreshSuggestion() async {
    final currentState = state;
    if (currentState is! SmartRouteLoaded) {
      await loadSession();
      return;
    }

    emit(SmartRouteLoading());
    try {
      await _reloadSessionAndSuggestion();
    } on SmartRouteServiceException catch (e) {
      emit(SmartRouteError(e.message));
    } catch (e) {
      emit(SmartRouteError('Failed to refresh smart route: $e'));
    }
  }

  Future<void> _reloadSessionAndSuggestion() async {
    final session = await _service.getOrCreateSession();
    final location = await _getCurrentLocation();
    final nextStop = await _service.getNextStop(
      sessionId: session.id,
      lat: location?.$1,
      lng: location?.$2,
    );
    final progress = await _service.getProgress(sessionId: session.id);

    emit(
      SmartRouteLoaded(
        session: session,
        progress: progress,
        rankedOutlets: _rankAssignedOutlets(
          outlets: session.assignedOutlets,
          currentStop: nextStop,
          currentLatitude: location?.$1,
          currentLongitude: location?.$2,
        ),
        currentStop: nextStop,
        isAllDone: session.totalStops > 0 && nextStop == null,
      ),
    );
  }

  List<SmartRouteRankedOutlet> _rankAssignedOutlets({
    required List<SmartRouteOutletSummary> outlets,
    SmartRouteStop? currentStop,
    double? currentLatitude,
    double? currentLongitude,
  }) {
    final ranked = outlets
        .map((outlet) {
          final distanceKm = _calculateDistanceKm(
            currentLatitude,
            currentLongitude,
            outlet.latitude,
            outlet.longitude,
          );

          return SmartRouteRankedOutlet(
            outlet: outlet,
            distanceKm: distanceKm,
            etaMinutes: _estimateEtaMinutes(distanceKm),
            isNearest: false,
            isSuggestedStop: currentStop?.outletId == outlet.id,
          );
        })
        .toList(growable: false);

    if (ranked.isEmpty) {
      return ranked;
    }

    final sorted = List<SmartRouteRankedOutlet>.from(ranked)
      ..sort((a, b) {
        final aDistance = a.distanceKm ?? double.infinity;
        final bDistance = b.distanceKm ?? double.infinity;
        final distanceComparison = aDistance.compareTo(bDistance);
        if (distanceComparison != 0) {
          return distanceComparison;
        }

        if (a.isSuggestedStop != b.isSuggestedStop) {
          return a.isSuggestedStop ? -1 : 1;
        }

        return a.outlet.suggestedSeq.compareTo(b.outlet.suggestedSeq);
      });

    final nearestIndex = sorted.indexWhere(
      (item) =>
          item.outlet.stopStatus != 'completed' &&
          item.outlet.stopStatus != 'skipped' &&
          item.distanceKm != null,
    );

    if (nearestIndex < 0) {
      return sorted;
    }

    return List<SmartRouteRankedOutlet>.generate(sorted.length, (index) {
      final item = sorted[index];
      return SmartRouteRankedOutlet(
        outlet: item.outlet,
        distanceKm: item.distanceKm,
        etaMinutes: item.etaMinutes,
        isNearest: index == nearestIndex,
        isSuggestedStop: item.isSuggestedStop,
      );
    }, growable: false);
  }

  double? _calculateDistanceKm(
    double? currentLatitude,
    double? currentLongitude,
    double? outletLatitude,
    double? outletLongitude,
  ) {
    if (currentLatitude == null ||
        currentLongitude == null ||
        outletLatitude == null ||
        outletLongitude == null) {
      return null;
    }

    final meters = Geolocator.distanceBetween(
      currentLatitude,
      currentLongitude,
      outletLatitude,
      outletLongitude,
    );
    return meters / 1000;
  }

  int? _estimateEtaMinutes(double? distanceKm) {
    if (distanceKm == null) {
      return null;
    }

    const averageCitySpeedKph = 24.0;
    final rawMinutes = (distanceKm / averageCitySpeedKph) * 60;
    final roundedMinutes = rawMinutes.round();
    if (roundedMinutes <= 1) {
      return 1;
    }
    return roundedMinutes;
  }
}
