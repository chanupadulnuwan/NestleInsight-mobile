import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/network/network_error_helper.dart';
import 'package:mobile/features/distributor/domain/delivery_assignment.dart';

class DistributorServiceException implements Exception {
  const DistributorServiceException(this.message, {this.code});

  final String message;
  final String? code;
}

class DistributorService {
  DistributorService({Dio? dio}) : _dio = dio ?? DioClient.instance.client;

  final Dio _dio;

  Future<DeliveryAssignment?> getMyAssignment() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/delivery-assignments/my',
      );
      final data = response.data ?? {};
      final raw = data['assignment'];
      if (raw == null) return null;
      return DeliveryAssignment.fromJson(Map<String, dynamic>.from(raw as Map));
    } on DioException catch (e) {
      throw DistributorServiceException(
        extractBackendErrorMessage(
          e,
          fallbackMessage: 'Unable to fetch assignment.',
        ),
        code: extractBackendErrorCode(e),
      );
    } catch (_) {
      throw const DistributorServiceException(
        'Unable to read the assignment data right now. Please refresh again.',
      );
    }
  }

  Future<String> requestDeliveryPin({required String orderId}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/delivery-assignments/orders/$orderId/request-delivery-pin',
      );
      return response.data?['message'] as String? ?? 'PIN sent to shop owner.';
    } on DioException catch (e) {
      throw DistributorServiceException(
        extractBackendErrorMessage(
          e,
          fallbackMessage: 'Unable to request delivery PIN.',
        ),
        code: extractBackendErrorCode(e),
      );
    }
  }

  Future<String> completeOrder({
    required String orderId,
    required String pin,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/delivery-assignments/orders/$orderId/complete',
        data: {'pin': pin},
      );
      return response.data?['message'] as String? ?? 'Order completed.';
    } on DioException catch (e) {
      throw DistributorServiceException(
        extractBackendErrorMessage(
          e,
          fallbackMessage: 'Unable to complete order.',
        ),
        code: extractBackendErrorCode(e),
      );
    }
  }

  Future<String> requestShopReturnPin({required String orderId}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/delivery-assignments/orders/$orderId/request-shop-return-pin',
      );
      return response.data?['message'] as String? ?? 'PIN sent to shop owner.';
    } on DioException catch (e) {
      throw DistributorServiceException(
        extractBackendErrorMessage(
          e,
          fallbackMessage: 'Unable to request return PIN.',
        ),
        code: extractBackendErrorCode(e),
      );
    }
  }

  Future<String> submitShopReturn({
    required String orderId,
    required String pin,
    required List<ReturnItemInput> items,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/delivery-assignments/orders/$orderId/submit-shop-return',
        data: {'pin': pin, 'items': items.map((i) => i.toJson()).toList()},
      );
      return response.data?['message'] as String? ?? 'Return recorded.';
    } on DioException catch (e) {
      throw DistributorServiceException(
        extractBackendErrorMessage(
          e,
          fallbackMessage: 'Unable to submit shop return.',
        ),
        code: extractBackendErrorCode(e),
      );
    }
  }

  Future<String> requestWarehouseReturnPin({
    required String assignmentId,
    required double cashReturnedAmount,
    String? earlyClosureReason,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/delivery-assignments/$assignmentId/request-warehouse-return-pin',
        data: {
          'cashReturnedAmount': cashReturnedAmount,
          if (earlyClosureReason != null && earlyClosureReason.trim().isNotEmpty)
            'earlyClosureReason': earlyClosureReason.trim(),
        },
      );
      return response.data?['message'] as String? ??
          'End-route review sent to Territory Manager.';
    } on DioException catch (e) {
      throw DistributorServiceException(
        extractBackendErrorMessage(
          e,
          fallbackMessage: 'Unable to request warehouse return PIN.',
        ),
        code: extractBackendErrorCode(e),
      );
    }
  }

  Future<String> submitReturn({
    required String assignmentId,
    required String tmPin,
    required List<ReturnItemInput> items,
    required double cashReturnedAmount,
    String? earlyClosureReason,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/delivery-assignments/$assignmentId/returns',
        data: {
          'tmPin': tmPin,
          'cashReturnedAmount': cashReturnedAmount,
          if (earlyClosureReason != null && earlyClosureReason.trim().isNotEmpty)
            'earlyClosureReason': earlyClosureReason.trim(),
          'items': items.map((i) => i.toJson()).toList(),
        },
      );
      return response.data?['message'] as String? ?? 'Return submitted.';
    } on DioException catch (e) {
      throw DistributorServiceException(
        extractBackendErrorMessage(
          e,
          fallbackMessage: 'Unable to submit return.',
        ),
        code: extractBackendErrorCode(e),
      );
    }
  }

  Future<String> addNote({
    required String category,
    required String message,
    String? assignmentId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/delivery-assignments/notes',
        data: {
          'category': category,
          'message': message,
          'assignmentId': ?assignmentId,
        },
      );
      return response.data?['message'] as String? ?? 'Note sent.';
    } on DioException catch (e) {
      throw DistributorServiceException(
        extractBackendErrorMessage(e, fallbackMessage: 'Unable to send note.'),
        code: extractBackendErrorCode(e),
      );
    }
  }

  Future<String> reportIncident({
    required String incidentType,
    required String description,
    String? assignmentId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/delivery-assignments/incidents',
        data: {
          ...?assignmentId == null ? null : {'assignmentId': assignmentId},
          'incidentType': incidentType,
          'description': description,
        },
      );
      return response.data?['message'] as String? ?? 'Incident reported.';
    } on DioException catch (e) {
      throw DistributorServiceException(
        extractBackendErrorMessage(
          e,
          fallbackMessage: 'Unable to report incident.',
        ),
        code: extractBackendErrorCode(e),
      );
    }
  }
}
