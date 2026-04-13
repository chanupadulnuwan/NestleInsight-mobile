import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';

class ReportServiceException implements Exception {
  const ReportServiceException(this.message, {this.code});

  final String message;
  final String? code;
}

class DailyReport {
  const DailyReport({
    required this.id,
    required this.reportDate,
    required this.status,
  });

  final String id;
  final String reportDate;
  final String status;

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    return DailyReport(
      id: (json['id'] ?? '').toString(),
      reportDate: (json['reportDate'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class ReportGenerateResult {
  const ReportGenerateResult({required this.message, required this.report});

  final String message;
  final DailyReport report;
}

class ReportService {
  final Dio _dio = DioClient.instance.client;

  Future<ReportGenerateResult> generateReport({required String routeId}) async {
    try {
      final response = await _dio.post(
        '/daily-reports/generate',
        data: {'routeId': routeId},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final report = DailyReport.fromJson(response.data);
        return ReportGenerateResult(
          message: 'Daily report generated successfully',
          report: report,
        );
      }

      throw ReportServiceException(
        'Failed to generate report: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw ReportServiceException(
        e.response?.data?['message'] ??
            e.message ??
            'Failed to generate report',
      );
    } catch (e) {
      throw ReportServiceException('An unexpected error occurred: $e');
    }
  }
}
