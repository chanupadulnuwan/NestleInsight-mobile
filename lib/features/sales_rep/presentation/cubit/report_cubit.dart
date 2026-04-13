import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/sales_rep/data/services/report_service.dart';

abstract class ReportState {}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {}

class ReportGenerated extends ReportState {
  ReportGenerated(this.report);

  final DailyReport report;
}

class ReportError extends ReportState {
  ReportError(this.message);

  final String message;
}

class ReportSuccess extends ReportState {
  ReportSuccess(this.message, this.report);

  final String message;
  final DailyReport report;
}

class ReportCubit extends Cubit<ReportState> {
  ReportCubit({ReportService? reportService})
    : _reportService = reportService ?? ReportService(),
      super(ReportInitial());

  final ReportService _reportService;

  Future<bool> generateReport({required String routeId}) async {
    emit(ReportLoading());

    try {
      final result = await _reportService.generateReport(routeId: routeId);

      emit(ReportSuccess(result.message, result.report));
      return true;
    } on ReportServiceException catch (error) {
      emit(ReportError(error.message));
      return false;
    }
  }
}
