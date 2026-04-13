import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';

class VisitServiceException implements Exception {
  const VisitServiceException(this.message, {this.code});

  final String message;
  final String? code;
}

class StoreVisit {
  const StoreVisit({
    required this.id,
    required this.shopNameSnapshot,
    required this.status,
    required this.visitStartedAt,
  });

  final String id;
  final String shopNameSnapshot;
  final String status;
  final DateTime visitStartedAt;

  factory StoreVisit.fromJson(Map<String, dynamic> json) {
    return StoreVisit(
      id: (json['id'] ?? '').toString(),
      shopNameSnapshot: (json['shopNameSnapshot'] ?? '').toString(),
      status: (json['status'] ?? 'IN_PROGRESS').toString(),
      visitStartedAt: json['visitStartedAt'] is String
          ? DateTime.parse(json['visitStartedAt'])
          : DateTime.now(),
    );
  }
}

class StartVisitResult {
  const StartVisitResult({required this.message, required this.visit});

  final String message;
  final StoreVisit visit;
}

class CompleteVisitResult {
  const CompleteVisitResult({
    required this.message,
    required this.durationSeconds,
  });

  final String message;
  final int durationSeconds;
}

class VisitService {
  final Dio _dio = DioClient.instance.client;

  Future<StartVisitResult> startVisit({
    required String routeId,
    String? shopId,
    required String shopName,
    required double latitude,
    required double longitude,
    required String territoryId,
  }) async {
    try {
      final response = await _dio.post(
        '/store-visits/start',
        data: {
          'routeId': routeId,
          'shopId': shopId,
          'shopNameSnapshot': shopName,
          'latitude': latitude,
          'longitude': longitude,
          'territoryId': territoryId,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final visit = StoreVisit.fromJson(response.data);
        return StartVisitResult(
          message: 'Store visit started successfully',
          visit: visit,
        );
      }

      throw VisitServiceException(
        'Failed to start visit: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw VisitServiceException(
        e.response?.data?['message'] ?? e.message ?? 'Failed to start visit',
      );
    } catch (e) {
      throw VisitServiceException('An unexpected error occurred: $e');
    }
  }

  Future<CompleteVisitResult> completeVisit({
    required String visitId,
    dynamic shelfStock,
    dynamic backroomStock,
    dynamic osaIssues,
    dynamic promotions,
    bool? planogramOk,
    bool? posmOk,
    String? feedback,
  }) async {
    try {
      final response = await _dio.patch(
        '/store-visits/$visitId/complete',
        data: {
          'shelfStockJson': shelfStock,
          'backroomStockJson': backroomStock,
          'osaIssuesJson': osaIssues,
          'promotionsJson': promotions,
          'planogramOk': planogramOk,
          'posmOk': posmOk,
          'outletFeedback': feedback,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final durationSeconds = response.data?['durationSeconds'] ?? 0;
        return CompleteVisitResult(
          message: 'Store visit completed successfully',
          durationSeconds: durationSeconds,
        );
      }

      throw VisitServiceException(
        'Failed to complete visit: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw VisitServiceException(
        e.response?.data?['message'] ?? e.message ?? 'Failed to complete visit',
      );
    } catch (e) {
      throw VisitServiceException('An unexpected error occurred: $e');
    }
  }
}
