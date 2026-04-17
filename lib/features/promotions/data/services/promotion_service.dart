import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/network/network_error_helper.dart';
import 'package:mobile/features/promotions/domain/promotion.dart';

/// Thrown when [PromotionService] cannot complete a request.
class PromotionServiceException implements Exception {
  const PromotionServiceException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'PromotionServiceException: $message';
}

/// Result of a promotion validation request.
class PromotionValidationResult {
  const PromotionValidationResult({
    required this.success,
    required this.discountAmount,
    required this.message,
    this.promotionId,
    this.code,
    this.discountType,
  });

  factory PromotionValidationResult.fromJson(Map<String, dynamic> json) {
    return PromotionValidationResult(
      success: json['success'] as bool? ?? false,
      discountAmount: (json['discountAmount'] as num? ?? 0).toDouble(),
      message: json['message'] as String? ?? '',
      promotionId: json['promotionId'] as String?,
      code: json['code'] as String?,
      discountType: json['discountType'] as String?,
    );
  }

  final bool success;
  final double discountAmount;
  final String message;
  final String? promotionId;
  final String? code;
  final String? discountType;
}

/// Fetches promotions from the NestJS backend.
class PromotionService {
  PromotionService({Dio? dio}) : _dio = dio ?? DioClient.instance.client;

  final Dio _dio;

  /// Returns active promotions scoped to [territoryId].
  ///
  /// Calls `GET /promotions/active?territoryId=<territoryId>`.
  /// The [territoryId] must be non-empty; callers should guard before invoking.
  Future<List<Promotion>> fetchActivePromotions(String territoryId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/promotions/active',
        queryParameters: <String, dynamic>{'territoryId': territoryId},
      );

      final body = response.data;

      // Backend may return a bare list or a wrapped { data: [...] } shape.
      final List<dynamic> raw;
      if (body is List) {
        raw = body;
      } else if (body is Map && body['data'] is List) {
        raw = body['data'] as List<dynamic>;
      } else {
        raw = const <dynamic>[];
      }

      return raw
          .whereType<Map<String, dynamic>>()
          .map(Promotion.fromJson)
          .toList();
    } on DioException catch (error) {
      throw PromotionServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to load promotions right now.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  /// Validates a promo code against current cart contents.
  ///
  /// Calls `POST /promotions/validate`.
  Future<PromotionValidationResult> validatePromotion({
    required String code,
    required String territoryId,
    required double cartTotal,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/promotions/validate',
        data: <String, dynamic>{
          'code': code,
          'territoryId': territoryId,
          'cartTotal': cartTotal,
          'cartItems': items,
        },
      );

      return PromotionValidationResult.fromJson(
        response.data ?? <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw PromotionServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Promotion could not be applied.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }
}
