import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/sales_rep/data/models/order_models.dart';

class PlaceOrderException implements Exception {
  const PlaceOrderException(this.message, {this.code});

  final String message;
  final String? code;
}

class PlaceOrderService {
  final Dio _dio = DioClient.instance.client;

  Future<AssistedOrderPinRequestResult> requestOrderPin(
    RequestAssistedOrderPinRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/orders/sales-rep/request-pin',
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AssistedOrderPinRequestResult.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }

      throw PlaceOrderException(
        'Failed to request confirmation PIN: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw PlaceOrderException(
        e.response?.data?['message'] ??
            e.message ??
            'Failed to request confirmation PIN',
      );
    } catch (e) {
      throw PlaceOrderException(
        'An unexpected error occurred while requesting the PIN: $e',
      );
    }
  }

  Future<AssistedOrderPinConfirmResult> confirmOrderPin({
    required String assistedOrderRequestId,
    required ConfirmAssistedOrderPinRequest request,
  }) async {
    try {
      final response = await _dio.post(
        '/orders/sales-rep/$assistedOrderRequestId/confirm-pin',
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AssistedOrderPinConfirmResult.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }

      throw PlaceOrderException(
        'Failed to confirm assisted order: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw PlaceOrderException(
        e.response?.data?['message'] ??
            e.message ??
            'Failed to confirm assisted order',
      );
    } catch (e) {
      throw PlaceOrderException(
        'An unexpected error occurred while confirming the assisted order: $e',
      );
    }
  }
}
