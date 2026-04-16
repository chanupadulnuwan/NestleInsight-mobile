import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/smart_route_service.dart';
import 'package:geolocator/geolocator.dart';

abstract class SmartRouteState {}

class SmartRouteInitial extends SmartRouteState {}

class SmartRouteLoading extends SmartRouteState {}

class SmartRouteLoaded extends SmartRouteState {
  final SmartRouteSession session;
  final SmartRouteStop? currentStop;
  final bool isAllDone;

  SmartRouteLoaded({
    required this.session,
    this.currentStop,
    required this.isAllDone,
  });
}

class SmartRouteError extends SmartRouteState {
  final String message;
  SmartRouteError(this.message);
}

class SmartRouteCubit extends Cubit<SmartRouteState> {
  final SmartRouteService _service = SmartRouteService();

  SmartRouteCubit() : super(SmartRouteInitial());

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

  Future<void> loadSession() async {
    emit(SmartRouteLoading());
    try {
      final session = await _service.getOrCreateSession();
      final location = await _getCurrentLocation();
      
      final nextStop = await _service.getNextStop(
        sessionId: session.id,
        lat: location?.$1,
        lng: location?.$2,
      );

      emit(SmartRouteLoaded(
        session: session,
        currentStop: nextStop,
        isAllDone: nextStop == null,
      ));
    } on SmartRouteServiceException catch (e) {
      emit(SmartRouteError(e.message));
    } catch (e) {
      emit(SmartRouteError('Failed to load session: $e'));
    }
  }

  Future<void> startCurrentStop(String stopId) async {
    final currentState = state;
    if (currentState is! SmartRouteLoaded) return;
    
    emit(SmartRouteLoading());
    try {
       await _service.startStop(stopId: stopId);
       final location = await _getCurrentLocation();
       final nextStop = await _service.getNextStop(
          sessionId: currentState.session.id,
          lat: location?.$1,
          lng: location?.$2,
       );
       emit(SmartRouteLoaded(
         session: currentState.session,
         currentStop: nextStop,
         isAllDone: nextStop == null,
       ));
    } on SmartRouteServiceException catch (e) {
      emit(SmartRouteError(e.message));
    } catch (e) {
      emit(SmartRouteError('Failed to start stop: $e'));
    }
  }

  Future<void> completeCurrentStop(String stopId) async {
    final currentState = state;
    if (currentState is! SmartRouteLoaded) return;
    
    emit(SmartRouteLoading());
    try {
       await _service.completeStop(stopId: stopId);
       final location = await _getCurrentLocation();
       final nextStop = await _service.getNextStop(
          sessionId: currentState.session.id,
          lat: location?.$1,
          lng: location?.$2,
       );
       emit(SmartRouteLoaded(
         session: currentState.session,
         currentStop: nextStop,
         isAllDone: nextStop == null,
       ));
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
    if (currentState is! SmartRouteLoaded) return;

    emit(SmartRouteLoading());
    try {
      final location = await _getCurrentLocation();
      final nextStop = await _service.skipStop(
        stopId: stopId,
        reasonCode: reasonCode,
        freeText: freeText,
        lat: location?.$1,
        lng: location?.$2,
      );

      emit(SmartRouteLoaded(
        session: currentState.session,
        currentStop: nextStop,
        isAllDone: nextStop == null,
      ));
    } on SmartRouteServiceException catch (e) {
      emit(SmartRouteError(e.message));
    } catch (e) {
      emit(SmartRouteError('Failed to skip stop: $e'));
    }
  }
}
