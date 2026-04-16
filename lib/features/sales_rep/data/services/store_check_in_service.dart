import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';

class StoreCheckInException implements Exception {
  const StoreCheckInException(this.message, {this.code});

  final String message;
  final String? code;
}

class StoreCheckInRequest {
  const StoreCheckInRequest({
    required this.routeId,
    required this.shopId,
    this.visitNotes,
  });

  final String routeId;
  final String shopId;
  final String? visitNotes;

  Map<String, dynamic> toJson() => {
    'routeId': routeId,
    'shopId': shopId,
    if (visitNotes != null) 'visitNotes': visitNotes,
  };
}

class StoreCheckInResponse {
  const StoreCheckInResponse({required this.message, required this.visitId});

  final String message;
  final String visitId;

  factory StoreCheckInResponse.fromJson(Map<String, dynamic> json) {
    return StoreCheckInResponse(
      message: (json['message'] ?? '').toString(),
      visitId: (json['visit']?['id'] ?? '').toString(),
    );
  }
}

class StoreCheckInService {
  final Dio _dio = DioClient.instance.client;

  Future<StoreCheckInResponse> checkInStore(StoreCheckInRequest request) async {
    try {
      final response = await _dio.post(
        '/store-visits/check-in',
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return StoreCheckInResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw StoreCheckInException('Failed to check in: ${response.statusCode}');
    } on DioException catch (e) {
      throw StoreCheckInException(
        e.response?.data?['message'] ??
            e.message ??
            'Failed to check in to store',
      );
    } catch (e) {
      throw StoreCheckInException('An unexpected error occurred: $e');
    }
  }
}
