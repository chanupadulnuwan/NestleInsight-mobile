import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/network/network_error_helper.dart';
import 'package:mobile/core/storage/token_storage_service.dart';
import 'package:mobile/features/auth/domain/public_user_role.dart';

class AuthServiceException implements Exception {
  const AuthServiceException(this.message, {this.code});

  final String message;
  final String? code;
}

class AuthResult {
  const AuthResult({
    required this.message,
    this.accessToken,
    this.user,
    this.otpRequired = false,
    this.otpDeliveryMethod,
    this.debugOtpCode,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];

    return AuthResult(
      message: json['message'] as String? ?? 'Request completed.',
      accessToken: json['accessToken'] as String?,
      user: rawUser is Map ? Map<String, dynamic>.from(rawUser) : null,
      otpRequired: json['otpRequired'] as bool? ?? false,
      otpDeliveryMethod: json['otpDeliveryMethod'] as String?,
      debugOtpCode: json['debugOtpCode'] as String?,
    );
  }

  final String message;
  final String? accessToken;
  final Map<String, dynamic>? user;
  final bool otpRequired;
  final String? otpDeliveryMethod;
  final String? debugOtpCode;
}

class AuthService {
  AuthService({Dio? dio, TokenStorageService? tokenStorageService})
    : _dio = dio ?? DioClient.instance.client,
      _tokenStorageService = tokenStorageService ?? TokenStorageService();

  final Dio _dio;
  final TokenStorageService _tokenStorageService;

  Future<AuthResult> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'identifier': identifier.trim(), 'password': password},
      );

      final result = AuthResult.fromJson(response.data ?? <String, dynamic>{});

      if (result.accessToken != null && result.accessToken!.isNotEmpty) {
        await _tokenStorageService.saveAccessToken(result.accessToken!);
      }

      return result;
    } on DioException catch (error) {
      throw AuthServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to log in right now.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required PublicUserRole role,
    String? employeeId,
    String? shopName,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final payload = _buildRegisterPayload(
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      confirmPassword: confirmPassword,
      role: role,
      employeeId: employeeId,
      shopName: shopName,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: payload,
      );

      return AuthResult.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw AuthServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to create the account right now.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<Map<String, dynamic>>('/auth/logout');
    } on DioException {
      // Local token clearing should still complete even if the logout activity call fails.
    } finally {
      await _tokenStorageService.clearSession();
    }
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/auth/password',
        data: <String, dynamic>{
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmNewPassword': confirmNewPassword,
        },
      );

      return response.data?['message'] as String? ??
          'Password changed successfully.';
    } on DioException catch (error) {
      throw AuthServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to change the password right now.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  Map<String, dynamic> _buildRegisterPayload({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required PublicUserRole role,
    String? employeeId,
    String? shopName,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    final normalizedEmployeeId = employeeId?.trim();
    final normalizedShopName = shopName?.trim();
    final normalizedAddress = address?.trim();

    return {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'username': username.trim(),
      'email': email.trim().toLowerCase(),
      'phoneNumber': phoneNumber.trim(),
      'password': password,
      'confirmPassword': confirmPassword,
      'role': role.backendValue,
      'platformAccess': 'MOBILE',
      ...(normalizedEmployeeId == null || normalizedEmployeeId.isEmpty
          ? const <String, dynamic>{}
          : {'employeeId': normalizedEmployeeId}),
      ...(normalizedShopName == null || normalizedShopName.isEmpty
          ? const <String, dynamic>{}
          : {'shopName': normalizedShopName}),
      ...(normalizedAddress == null || normalizedAddress.isEmpty
          ? const <String, dynamic>{}
          : {'address': normalizedAddress}),
      ...(latitude == null
          ? const <String, dynamic>{}
          : {'latitude': latitude}),
      ...(longitude == null
          ? const <String, dynamic>{}
          : {'longitude': longitude}),
    };
  }
}
