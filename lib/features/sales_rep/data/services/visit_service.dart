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
    this.photoUrls,
    this.lastOrderDateSnapshot,
    this.suggestedOrderJson,
    this.hasPendingDelivery = false,
  });

  final String id;
  final String shopNameSnapshot;
  final String status;
  final DateTime visitStartedAt;
  final List<String>? photoUrls;
  final DateTime? lastOrderDateSnapshot;
  final Map<String, dynamic>? suggestedOrderJson;
  final bool hasPendingDelivery;

  factory StoreVisit.fromJson(Map<String, dynamic> json) {
    return StoreVisit(
      id: (json['id'] ?? '').toString(),
      shopNameSnapshot: (json['shopNameSnapshot'] ?? '').toString(),
      status: (json['status'] ?? 'IN_PROGRESS').toString(),
      visitStartedAt: json['visitStartedAt'] is String
          ? DateTime.parse(json['visitStartedAt'])
          : DateTime.now(),
      photoUrls: (json['photoUrls'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      lastOrderDateSnapshot: json['lastOrderDateSnapshot'] != null
          ? DateTime.tryParse(json['lastOrderDateSnapshot'])
          : null,
      suggestedOrderJson: json['suggestedOrderJson'] as Map<String, dynamic>?,
      hasPendingDelivery: json['hasPendingDelivery'] == true,
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
    List<Map<String, dynamic>>? stockItems,
    List<Map<String, dynamic>>? expiryItems,
    List<Map<String, dynamic>>? osaIssues,
    String? competitorNotes,
    List<Map<String, dynamic>>? promotionChecks,
    List<Map<String, dynamic>>? planogramAnswers,
    List<Map<String, dynamic>>? posmAnswers,
    List<Map<String, dynamic>>? outletFeedbackAnswers,
    bool? planogramOk,
    bool? posmOk,
    String? feedback,
  }) async {
    try {
      final response = await _dio.patch(
        '/store-visits/$visitId/complete',
        data: {
          if (stockItems != null) 'stockItems': stockItems,
          if (expiryItems != null) 'expiryItems': expiryItems,
          if (osaIssues != null) 'osaIssues': osaIssues,
          if (competitorNotes != null) 'competitorNotes': competitorNotes,
          if (promotionChecks != null) 'promotionChecks': promotionChecks,
          if (planogramAnswers != null) 'planogramAnswers': planogramAnswers,
          if (posmAnswers != null) 'posmAnswers': posmAnswers,
          if (outletFeedbackAnswers != null)
            'outletFeedbackAnswers': outletFeedbackAnswers,
          if (planogramOk != null) 'planogramOk': planogramOk,
          if (posmOk != null) 'posmOk': posmOk,
          if (feedback != null) 'outletFeedback': feedback,
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

  Future<void> uploadVisitPhoto({
    required String visitId,
    required String filePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          filePath,
          filename: 'visit_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await _dio.post(
        '/store-visits/$visitId/photos',
        data: formData,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw VisitServiceException(
          'Failed to upload photo: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw VisitServiceException(
        e.response?.data?['message'] ?? e.message ?? 'Failed to upload photo',
      );
    } catch (e) {
      throw VisitServiceException('An unexpected error occurred: $e');
    }
  }
}
