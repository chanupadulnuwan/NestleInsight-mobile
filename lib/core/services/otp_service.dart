import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/network/network_error_helper.dart';

class OtpServiceException implements Exception {
  const OtpServiceException(this.message, {this.code});

  final String message;
  final String? code;
}

class OtpResult {
  const OtpResult({
    required this.message,
    this.otpDeliveryMethod,
    this.debugOtpCode,
    this.user,
  });

  factory OtpResult.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];

    return OtpResult(
      message: json['message'] as String? ?? 'OTP request completed.',
      otpDeliveryMethod: json['otpDeliveryMethod'] as String?,
      debugOtpCode: json['debugOtpCode'] as String?,
      user: rawUser is Map ? Map<String, dynamic>.from(rawUser) : null,
    );
  }

  final String message;
  final String? otpDeliveryMethod;
  final String? debugOtpCode;
  final Map<String, dynamic>? user;
}

class OtpService {
  OtpService({Dio? dio}) : _dio = dio ?? DioClient.instance.client;

  final Dio _dio;

  bool get isAvailable => true;

  String get unavailableReason => '';

  Future<OtpResult> verifyOtp({
    required String identifier,
    required String otp,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/otp/verify',
        data: {'identifier': identifier.trim(), 'otp': otp.trim()},
      );

      return OtpResult.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw OtpServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to verify OTP right now.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  Future<OtpResult> resendOtp({required String identifier}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/otp/resend',
        data: {'identifier': identifier.trim()},
      );

      return OtpResult.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw OtpServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to resend OTP right now.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }
}
