import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';

class IncidentServiceException implements Exception {
  const IncidentServiceException(this.message, {this.code});

  final String message;
  final String? code;
}

class SalesIncident {
  const SalesIncident({
    required this.id,
    required this.incidentType,
    required this.severity,
    required this.description,
  });

  final String id;
  final String incidentType;
  final String severity;
  final String description;

  factory SalesIncident.fromJson(Map<String, dynamic> json) {
    return SalesIncident(
      id: (json['id'] ?? '').toString(),
      incidentType: (json['incidentType'] ?? '').toString(),
      severity: (json['severity'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }
}

class IncidentReportResult {
  const IncidentReportResult({required this.message, required this.incident});

  final String message;
  final SalesIncident incident;
}

class IncidentService {
  final Dio _dio = DioClient.instance.client;

  Future<IncidentReportResult> reportIncident({
    required String routeId,
    required String type,
    required String description,
    required String severity,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.post(
        '/sales-incidents',
        data: {
          'routeId': routeId,
          'incidentType': type,
          'description': description,
          'severity': severity,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final incident = SalesIncident.fromJson(response.data);
        return IncidentReportResult(
          message: 'Incident reported successfully',
          incident: incident,
        );
      }

      throw IncidentServiceException(
        'Failed to report incident: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw IncidentServiceException(
        e.response?.data?['message'] ??
            e.message ??
            'Failed to report incident',
      );
    } catch (e) {
      throw IncidentServiceException('An unexpected error occurred: $e');
    }
  }
}
