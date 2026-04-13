import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/sales_rep/data/services/incident_service.dart';

abstract class IncidentState {}

class IncidentInitial extends IncidentState {}

class IncidentLoading extends IncidentState {}

class IncidentReported extends IncidentState {
  IncidentReported(this.incident);

  final SalesIncident incident;
}

class IncidentError extends IncidentState {
  IncidentError(this.message);

  final String message;
}

class IncidentSuccess extends IncidentState {
  IncidentSuccess(this.message, this.incident);

  final String message;
  final SalesIncident incident;
}

class IncidentCubit extends Cubit<IncidentState> {
  IncidentCubit({IncidentService? incidentService})
    : _incidentService = incidentService ?? IncidentService(),
      super(IncidentInitial());

  final IncidentService _incidentService;

  Future<bool> reportIncident({
    required String routeId,
    required String type,
    required String description,
    required String severity,
    required double latitude,
    required double longitude,
  }) async {
    emit(IncidentLoading());

    try {
      final result = await _incidentService.reportIncident(
        routeId: routeId,
        type: type,
        description: description,
        severity: severity,
        latitude: latitude,
        longitude: longitude,
      );

      emit(IncidentSuccess(result.message, result.incident));
      return true;
    } on IncidentServiceException catch (error) {
      emit(IncidentError(error.message));
      return false;
    }
  }
}
