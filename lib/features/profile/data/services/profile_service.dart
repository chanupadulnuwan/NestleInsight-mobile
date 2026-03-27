import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/network/network_error_helper.dart';
import 'package:mobile/core/storage/token_storage_service.dart';
import 'package:mobile/features/profile/domain/shop_owner_profile.dart';

class ProfileServiceException implements Exception {
  const ProfileServiceException(this.message, {this.code});

  final String message;
  final String? code;
}

class ProfileResult {
  const ProfileResult({
    required this.message,
    required this.profile,
    this.accessToken,
  });

  factory ProfileResult.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final userMap = rawUser is Map ? Map<String, dynamic>.from(rawUser) : null;

    return ProfileResult(
      message: json['message'] as String? ?? 'Profile request completed.',
      profile: ShopOwnerProfile.fromJson(userMap),
      accessToken: json['accessToken'] as String?,
    );
  }

  final String message;
  final ShopOwnerProfile profile;
  final String? accessToken;
}

class ProfileService {
  ProfileService({Dio? dio, TokenStorageService? tokenStorageService})
    : _dio = dio ?? DioClient.instance.client,
      _tokenStorageService = tokenStorageService ?? TokenStorageService();

  final Dio _dio;
  final TokenStorageService _tokenStorageService;

  Future<ProfileResult> getCurrentProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      return ProfileResult.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw ProfileServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to load your profile right now.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }

  Future<ProfileResult> updateCurrentProfile({
    required String username,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String email,
    required String shopName,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/auth/me',
        data: <String, dynamic>{
          'username': username.trim(),
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'phoneNumber': phoneNumber.trim(),
          'email': email.trim().toLowerCase(),
          'shopName': shopName.trim(),
        },
      );

      final result = ProfileResult.fromJson(
        response.data ?? <String, dynamic>{},
      );

      if (result.accessToken != null && result.accessToken!.isNotEmpty) {
        await _tokenStorageService.saveAccessToken(result.accessToken!);
      }

      return result;
    } on DioException catch (error) {
      throw ProfileServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to save your profile right now.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }
}
