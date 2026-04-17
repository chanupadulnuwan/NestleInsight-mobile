import 'package:dio/dio.dart';
// 1. FIX: Changed to a relative import so it works no matter what your project is named!
import '../../../../core/network/dio_client.dart';

class OutletServiceException implements Exception {
  const OutletServiceException(this.message, {this.code});

  final String message;
  final String? code;
}

class Outlet {
  const Outlet({
    required this.id,
    required this.outletName,
    required this.ownerName,
    required this.status,
  });

  final String id;
  final String outletName;
  final String ownerName;
  final String status;

  factory Outlet.fromJson(Map<String, dynamic> json) {
    return Outlet(
      id: (json['id'] ?? '').toString(),
      outletName: (json['outletName'] ?? '').toString(),
      ownerName: (json['ownerName'] ?? '').toString(),
      status: (json['status'] ?? 'PENDING_APPROVAL').toString(),
    );
  }
}

class OutletRegistrationResult {
  const OutletRegistrationResult({required this.message, required this.outlet});

  final String message;
  final Outlet outlet;
}

class OutletService {
  final Dio _dio = DioClient.instance.client;

  Future<OutletRegistrationResult> registerOutlet({
    required String name,
    required String owner,
    required String phone,
    required String email,
    required String address,
    required double latitude,
    required double longitude,
    required String territoryId, // 👈 ADDED THIS
  }) async {
    try {
      final response = await _dio.post(
        '/outlets',
        data: {
          'outletName': name,
          'ownerName': owner,
          'contactNumber': phone, // 👈 CHANGED from ownerPhone to contactNumber
          'ownerEmail': email,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'territoryId': territoryId, // 👈 ADDED THIS
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // 2. FIX: Explicitly cast the dynamic response to a Map to satisfy Flutter's strict mode
        final responseData = response.data as Map<String, dynamic>;
        final outlet = Outlet.fromJson(responseData);

        return OutletRegistrationResult(
          message: 'Outlet registered successfully and is pending approval',
          outlet: outlet,
        );
      }

      throw OutletServiceException(
        'Failed to register outlet: ${response.statusCode}',
      );
    } on DioException catch (e) {
      // 3. FIX: Safely parse the dynamic error message without angering the type checker
      final errorData = e.response?.data;
      final errorMessage = errorData is Map<String, dynamic>
          ? errorData['message']
          : null;

      throw OutletServiceException(
        errorMessage?.toString() ?? e.message ?? 'Failed to register outlet',
      );
    } catch (e) {
      throw OutletServiceException('An unexpected error occurred: $e');
    }
  }
}
