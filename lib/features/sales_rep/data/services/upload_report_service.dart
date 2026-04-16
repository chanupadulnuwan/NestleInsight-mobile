import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class DailyReportSummary {
  final String id;
  final String reportDate;
  final String status;
  final DateTime? submittedAt;

  DailyReportSummary({
    required this.id,
    required this.reportDate,
    required this.status,
    this.submittedAt,
  });

  factory DailyReportSummary.fromJson(Map<String, dynamic> json) {
    return DailyReportSummary(
      id: json['id'],
      reportDate: json['reportDate'],
      status: json['status'],
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt']) : null,
    );
  }
}

class UploadReportServiceException implements Exception {
  final String message;
  UploadReportServiceException(this.message);

  @override
  String toString() => 'UploadReportServiceException: $message';
}

class UploadReportService {
  final Dio _dio = DioClient.instance.client;

  Future<DailyReportSummary> generateReport({required String routeId}) async {
    try {
      final response = await _dio.post(
        '/daily-reports/generate',
        data: {'routeId': routeId},
      );
      return DailyReportSummary.fromJson(response.data);
    } on DioException catch (e) {
      throw UploadReportServiceException(
        e.response?.data?['message'] ?? e.message ?? 'Unknown error generating report',
      );
    } catch (e) {
      throw UploadReportServiceException('Failed to process generated report: $e');
    }
  }

  Future<List<DailyReportSummary>> fetchMyReports() async {
    try {
      final response = await _dio.get('/daily-reports/my');
      final data = response.data;
      final List list = data is List ? data : (data['data'] ?? []);
      return list.map((json) => DailyReportSummary.fromJson(json)).toList();
    } on DioException catch (e) {
      throw UploadReportServiceException(
        e.response?.data?['message'] ?? e.message ?? 'Unknown error fetching reports',
      );
    } catch (e) {
      throw UploadReportServiceException('Failed to process reports data: $e');
    }
  }
}
