import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';

class RegisterOutletException implements Exception {
  const RegisterOutletException(this.message, {this.code});

  final String message;
  final String? code;
}

class RegisterOutletRequest {
  const RegisterOutletRequest({
    required this.outletName,
    required this.ownerName,
    required this.contactNumber,
    required this.territoryId,
    required this.latitude,
    required this.longitude,
    this.ownerEmail,
    this.address,
  });

  final String outletName;
  final String ownerName;
  final String contactNumber;
  final String territoryId;
  final double latitude;
  final double longitude;
  final String? ownerEmail;
  final String? address;

  Map<String, dynamic> toJson() => {
    'outletName': outletName,
    'ownerName': ownerName,
    'contactNumber': contactNumber,
    'territoryId': territoryId,
    'latitude': latitude,
    'longitude': longitude,
    if (ownerEmail != null) 'ownerEmail': ownerEmail,
    if (address != null) 'address': address,
  };
}

class RegisterOutletResponse {
  const RegisterOutletResponse({required this.message, required this.outletId});

  final String message;
  final String outletId;

  factory RegisterOutletResponse.fromJson(Map<String, dynamic> json) {
    return RegisterOutletResponse(
      message: (json['message'] ?? '').toString(),
      outletId: (json['outlet']?['id'] ?? '').toString(),
    );
  }
}

class RegisterOutletService {
  final Dio _dio = DioClient.instance.client;

  Future<RegisterOutletResponse> registerOutlet(
    RegisterOutletRequest request,
  ) async {
    try {
      final response = await _dio.post('/outlets', data: request.toJson());

      if (response.statusCode == 201 || response.statusCode == 200) {
        return RegisterOutletResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw RegisterOutletException(
        'Failed to register outlet: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw RegisterOutletException(
        e.response?.data?['message'] ??
            e.message ??
            'Failed to register outlet',
      );
    } catch (e) {
      throw RegisterOutletException('An unexpected error occurred: $e');
    }
  }
}
