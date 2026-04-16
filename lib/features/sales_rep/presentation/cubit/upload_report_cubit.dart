import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/upload_report_service.dart';

abstract class UploadReportState {}

class UploadReportInitial extends UploadReportState {}

class UploadReportLoading extends UploadReportState {}

class UploadReportLoaded extends UploadReportState {
  final List<DailyReportSummary> reports;
  UploadReportLoaded(this.reports);
}

class UploadReportGenerating extends UploadReportState {}

class UploadReportGenerated extends UploadReportState {
  final DailyReportSummary report;
  UploadReportGenerated(this.report);
}

class UploadReportError extends UploadReportState {
  final String message;
  UploadReportError(this.message);
}

class UploadReportCubit extends Cubit<UploadReportState> {
  final UploadReportService _service = UploadReportService();

  UploadReportCubit() : super(UploadReportInitial());

  Future<void> loadMyReports() async {
    emit(UploadReportLoading());
    try {
      final reports = await _service.fetchMyReports();
      emit(UploadReportLoaded(reports));
    } on UploadReportServiceException catch (e) {
      emit(UploadReportError(e.message));
    } catch (e) {
      emit(UploadReportError('Failed to load reports: $e'));
    }
  }

  Future<void> generateReport({required String routeId}) async {
    emit(UploadReportGenerating());
    try {
      final report = await _service.generateReport(routeId: routeId);
      emit(UploadReportGenerated(report));
      await loadMyReports(); // Reload list internally for tabs immediately
    } on UploadReportServiceException catch (e) {
      emit(UploadReportError(e.message));
    } catch (e) {
      emit(UploadReportError('Failed to generate report: $e'));
    }
  }
}
