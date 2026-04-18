import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

class DailyReportSummary {
  DailyReportSummary({
    required this.id,
    required this.routeId,
    required this.reportDate,
    required this.status,
    this.submittedAt,
  });

  final String id;
  final String? routeId;
  final String reportDate;
  final String status;
  final DateTime? submittedAt;

  bool get isSubmitted => status.toUpperCase() == 'SUBMITTED';
  bool get isDraft => status.toUpperCase() == 'DRAFT';

  factory DailyReportSummary.fromJson(Map<String, dynamic> json) {
    return DailyReportSummary(
      id: (json['id'] ?? '').toString(),
      routeId: _nullableString(json['routeId']),
      reportDate: (json['reportDate'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      submittedAt: _nullableDateTime(json['submittedAt']),
    );
  }
}

class DailyReportDetail extends DailyReportSummary {
  DailyReportDetail({
    required super.id,
    required super.routeId,
    required super.reportDate,
    required super.status,
    super.submittedAt,
    this.repComments,
    this.routeSummary,
    this.visitSummary,
    this.osaSummary,
    this.deliverySummary,
    this.returnSummary,
    this.incidentSummary,
  });

  final String? repComments;
  final Map<String, dynamic>? routeSummary;
  final Map<String, dynamic>? visitSummary;
  final Map<String, dynamic>? osaSummary;
  final Map<String, dynamic>? deliverySummary;
  final Map<String, dynamic>? returnSummary;
  final Map<String, dynamic>? incidentSummary;

  factory DailyReportDetail.fromJson(Map<String, dynamic> json) {
    return DailyReportDetail(
      id: (json['id'] ?? '').toString(),
      routeId: _nullableString(json['routeId']),
      reportDate: (json['reportDate'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      submittedAt: _nullableDateTime(json['submittedAt']),
      repComments: _nullableString(json['repComments']),
      routeSummary: _nullableMap(json['routeSummaryJson']),
      visitSummary: _nullableMap(json['visitSummaryJson']),
      osaSummary: _nullableMap(json['osaSummaryJson']),
      deliverySummary: _nullableMap(json['deliverySummaryJson']),
      returnSummary: _nullableMap(json['returnSummaryJson']),
      incidentSummary: _nullableMap(json['incidentSummaryJson']),
    );
  }
}

class UploadReportServiceException implements Exception {
  UploadReportServiceException(this.message);

  final String message;

  @override
  String toString() => 'UploadReportServiceException: $message';
}

class UploadReportService {
  final Dio _dio = DioClient.instance.client;

  Future<DailyReportDetail> generateReport({required String routeId}) async {
    try {
      final response = await _dio.post(
        '/daily-reports/generate',
        data: {'routeId': routeId},
      );
      return DailyReportDetail.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw UploadReportServiceException(
        e.response?.data?['message'] ??
            e.message ??
            'Unknown error generating report',
      );
    } catch (e) {
      throw UploadReportServiceException(
        'Failed to process generated report: $e',
      );
    }
  }

  Future<List<DailyReportSummary>> fetchMyReports() async {
    try {
      final response = await _dio.get('/daily-reports/my');
      final data = response.data;
      final list = data is List ? data : (data['data'] ?? []);
      return (list as List)
          .map(
            (json) => DailyReportSummary.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw UploadReportServiceException(
        e.response?.data?['message'] ??
            e.message ??
            'Unknown error fetching reports',
      );
    } catch (e) {
      throw UploadReportServiceException(
        'Failed to process reports data: $e',
      );
    }
  }

  Future<DailyReportDetail> fetchReport({required String reportId}) async {
    try {
      final response = await _dio.get('/daily-reports/my/$reportId');
      return DailyReportDetail.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw UploadReportServiceException(
        e.response?.data?['message'] ??
            e.message ??
            'Unknown error fetching report',
      );
    } catch (e) {
      throw UploadReportServiceException('Failed to process report data: $e');
    }
  }

  Future<DailyReportDetail> updateDraft({
    required String reportId,
    required String repComments,
  }) async {
    try {
      final response = await _dio.patch(
        '/daily-reports/$reportId',
        data: {'repComments': repComments},
      );
      return DailyReportDetail.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw UploadReportServiceException(
        e.response?.data?['message'] ??
            e.message ??
            'Unknown error updating report draft',
      );
    } catch (e) {
      throw UploadReportServiceException('Failed to update draft: $e');
    }
  }

  Future<DailyReportDetail> submitReport({required String reportId}) async {
    try {
      final response = await _dio.post('/daily-reports/$reportId/submit');
      return DailyReportDetail.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw UploadReportServiceException(
        e.response?.data?['message'] ??
            e.message ??
            'Unknown error submitting report',
      );
    } catch (e) {
      throw UploadReportServiceException('Failed to submit report: $e');
    }
  }
}

String? _nullableString(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty || text == 'null') {
    return null;
  }
  return text;
}

DateTime? _nullableDateTime(dynamic value) {
  final text = _nullableString(value);
  if (text == null) {
    return null;
  }
  return DateTime.tryParse(text);
}

Map<String, dynamic>? _nullableMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}
