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

  Future<Map<String, dynamic>> placeOrder(
    CreateSalesOrderRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/orders/sales-rep',
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw PlaceOrderException(
        'Failed to place order: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw PlaceOrderException(
        e.response?.data?['message'] ?? e.message ?? 'Failed to place order',
      );
    } catch (e) {
      throw PlaceOrderException('An unexpected error occurred: $e');
    }
  }
}
