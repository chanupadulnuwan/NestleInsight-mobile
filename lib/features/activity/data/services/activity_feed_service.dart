import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/network/network_error_helper.dart';
import 'package:mobile/features/activity/domain/activity_entry.dart';
import 'package:mobile/features/activity/domain/order_feedback_request.dart';

class ActivityFeedServiceException implements Exception {
  const ActivityFeedServiceException(this.message, {this.code});

  final String message;
  final String? code;
}

class ActivityFeedResult {
  const ActivityFeedResult({required this.message, required this.activities});

  factory ActivityFeedResult.fromJson(Map<String, dynamic> json) {
    final rawActivities = json['activities'];
    final activities = rawActivities is List
        ? rawActivities
              .whereType<Map>()
              .map(
                (activity) => ActivityEntry.fromJson(
                  Map<String, dynamic>.from(activity),
                ),
              )
              .toList()
        : const <ActivityEntry>[];

    return ActivityFeedResult(
      message: json['message'] as String? ?? 'Activity loaded.',
      activities: activities,
    );
  }

  final String message;
  final List<ActivityEntry> activities;
}

class FeedbackSubmitResult {
  const FeedbackSubmitResult({required this.message});

  factory FeedbackSubmitResult.fromJson(Map<String, dynamic> json) {
    return FeedbackSubmitResult(
      message: json['message'] as String? ?? 'Feedback submitted successfully.',
    );
  }

  final String message;
}

class ActivityFeedService {
  ActivityFeedService({Dio? dio}) : _dio = dio ?? DioClient.instance.client;

  final Dio _dio;

  Future<ActivityFeedResult> fetchActivities() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/activities');
      return ActivityFeedResult.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw ActivityFeedServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to load activity right now.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  Future<FeedbackSubmitResult> submitFeedback(String message) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/activities/feedback',
        data: <String, dynamic>{'message': message.trim()},
      );

      return FeedbackSubmitResult.fromJson(
        response.data ?? <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw ActivityFeedServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to submit feedback right now.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  /// Submit a star rating + optional comment for a completed order.
  /// The [territoryId] and [shopOwnerId] are resolved on the server from the JWT.
  Future<FeedbackSubmitResult> submitOrderFeedback(
    OrderFeedbackRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/activities/order-feedback',
        data: request.toJson(),
      );

      return FeedbackSubmitResult.fromJson(
        response.data ?? <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw ActivityFeedServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to submit your rating right now.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }
}
