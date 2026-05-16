import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/upload_report_service.dart';

class UploadReportState {
  const UploadReportState({
    this.reports = const [],
    this.selectedReport,
    this.isLoadingReports = false,
    this.isGenerating = false,
    this.isSavingDraft = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  final List<DailyReportSummary> reports;
  final DailyReportDetail? selectedReport;
  final bool isLoadingReports;
  final bool isGenerating;
  final bool isSavingDraft;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  bool get isBusy =>
      isLoadingReports || isGenerating || isSavingDraft || isSubmitting;

  static const Object _sentinel = Object();

  UploadReportState copyWith({
    List<DailyReportSummary>? reports,
    Object? selectedReport = _sentinel,
    bool? isLoadingReports,
    bool? isGenerating,
    bool? isSavingDraft,
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
    Object? successMessage = _sentinel,
  }) {
    return UploadReportState(
      reports: reports ?? this.reports,
      selectedReport: identical(selectedReport, _sentinel)
          ? this.selectedReport
          : selectedReport as DailyReportDetail?,
      isLoadingReports: isLoadingReports ?? this.isLoadingReports,
      isGenerating: isGenerating ?? this.isGenerating,
      isSavingDraft: isSavingDraft ?? this.isSavingDraft,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      successMessage: identical(successMessage, _sentinel)
          ? this.successMessage
          : successMessage as String?,
    );
  }
}

class UploadReportCubit extends Cubit<UploadReportState> {
  UploadReportCubit({UploadReportService? service})
    : _service = service ?? UploadReportService(),
      super(const UploadReportState());

  final UploadReportService _service;

  Future<void> loadMyReports({String? focusReportId}) async {
    emit(
      state.copyWith(
        isLoadingReports: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      final reports = await _service.fetchMyReports();
      DailyReportDetail? selectedReport = state.selectedReport;
      final selectedId = focusReportId ?? state.selectedReport?.id;

      if (selectedId != null && selectedId.isNotEmpty) {
        selectedReport = await _service.fetchReport(reportId: selectedId);
      }

      emit(
        state.copyWith(
          reports: reports,
          selectedReport: selectedReport,
          isLoadingReports: false,
        ),
      );
    } on UploadReportServiceException catch (e) {
      emit(state.copyWith(isLoadingReports: false, errorMessage: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingReports: false,
          errorMessage: 'Failed to load reports: $e',
        ),
      );
    }
  }

  Future<void> openReport(String reportId) async {
    emit(
      state.copyWith(
        isLoadingReports: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      final report = await _service.fetchReport(reportId: reportId);
      emit(state.copyWith(selectedReport: report, isLoadingReports: false));
    } on UploadReportServiceException catch (e) {
      emit(state.copyWith(isLoadingReports: false, errorMessage: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingReports: false,
          errorMessage: 'Failed to open report: $e',
        ),
      );
    }
  }

  Future<void> generateReport({required String routeId}) async {
    emit(
      state.copyWith(
        isGenerating: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      final report = await _service.generateReport(routeId: routeId);
      final reports = await _service.fetchMyReports();
      emit(
        state.copyWith(
          reports: reports,
          selectedReport: report,
          isGenerating: false,
          successMessage: report.isSubmitted
              ? 'This report was already submitted.'
              : 'Draft report generated successfully.',
        ),
      );
    } on UploadReportServiceException catch (e) {
      emit(state.copyWith(isGenerating: false, errorMessage: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          isGenerating: false,
          errorMessage: 'Failed to generate report: $e',
        ),
      );
    }
  }

  Future<void> saveDraftComments(String repComments) async {
    final report = state.selectedReport;
    if (report == null) {
      emit(
        state.copyWith(errorMessage: 'Generate or open a draft report first.'),
      );
      return;
    }

    emit(
      state.copyWith(
        isSavingDraft: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      final updated = await _service.updateDraft(
        reportId: report.id,
        repComments: repComments,
      );
      final reports = await _service.fetchMyReports();
      emit(
        state.copyWith(
          reports: reports,
          selectedReport: updated,
          isSavingDraft: false,
          successMessage: updated.isSubmitted
              ? 'Report notes updated. You can resubmit now.'
              : 'Draft comments saved.',
        ),
      );
    } on UploadReportServiceException catch (e) {
      emit(state.copyWith(isSavingDraft: false, errorMessage: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          isSavingDraft: false,
          errorMessage: 'Failed to save draft: $e',
        ),
      );
    }
  }

  Future<void> submitSelectedReport() async {
    final report = state.selectedReport;
    if (report == null) {
      emit(state.copyWith(errorMessage: 'Generate or open a report first.'));
      return;
    }

    emit(
      state.copyWith(
        isSubmitting: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      final submitted = await _service.submitReport(reportId: report.id);
      final reports = await _service.fetchMyReports();
      emit(
        state.copyWith(
          reports: reports,
          selectedReport: submitted,
          isSubmitting: false,
          successMessage: report.isSubmitted
              ? 'Report resubmitted successfully.'
              : 'Final report submitted successfully.',
        ),
      );
    } on UploadReportServiceException catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to submit report: $e',
        ),
      );
    }
  }

  Future<void> submitReports(Set<String> reportIds) async {
    final ids = reportIds.where((id) => id.trim().isNotEmpty).toList();
    if (ids.isEmpty) {
      emit(state.copyWith(errorMessage: 'Select at least one draft report.'));
      return;
    }

    emit(
      state.copyWith(
        isSubmitting: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      DailyReportDetail? selectedReport = state.selectedReport;
      for (final id in ids) {
        final submitted = await _service.submitReport(reportId: id);
        if (selectedReport?.id == id) {
          selectedReport = submitted;
        }
      }

      final reports = await _service.fetchMyReports();
      emit(
        state.copyWith(
          reports: reports,
          selectedReport: selectedReport,
          isSubmitting: false,
          successMessage:
              '${ids.length} report${ids.length == 1 ? '' : 's'} uploaded successfully.',
        ),
      );
    } on UploadReportServiceException catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to upload reports: $e',
        ),
      );
    }
  }

  void clearNotifications() {
    emit(state.copyWith(errorMessage: null, successMessage: null));
  }
}
