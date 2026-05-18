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
    required this.userData,
    this.accessToken,
  });

  factory ProfileResult.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final userMap = rawUser is Map ? Map<String, dynamic>.from(rawUser) : null;

    return ProfileResult(
      message: json['message'] as String? ?? 'Profile request completed.',
      profile: ShopOwnerProfile.fromJson(userMap),
      userData: userMap ?? <String, dynamic>{},
      accessToken: json['accessToken'] as String?,
    );
  }

  final String message;
  final ShopOwnerProfile profile;
  final Map<String, dynamic> userData;
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
    String? shopName,
  }) async {
    try {
      final payload = <String, dynamic>{
        'username': username.trim(),
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'phoneNumber': phoneNumber.trim(),
        'email': email.trim().toLowerCase(),
      };

      if (shopName != null) {
        payload['shopName'] = shopName.trim();
      }

      final response = await _dio.patch<Map<String, dynamic>>(
        '/auth/me',
        data: payload,
      );

      final result = ProfileResult.fromJson(
        response.data ?? <String, dynamic>{},
      );

      if (result.accessToken != null && result.accessToken!.isNotEmpty) {
        await _tokenStorageService.saveAccessToken(result.accessToken!);
      }

      if (result.userData.isNotEmpty) {
        await _tokenStorageService.saveUserData(result.userData);
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
