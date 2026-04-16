import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class ReturnItemLog {
  final String productId;
  final String productName;
  final int quantityCases;
  final String reason;
  final String? notes;

  ReturnItemLog({
    required this.productId,
    required this.productName,
    required this.quantityCases,
    required this.reason,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantityCases': quantityCases,
      'reason': reason,
      if (notes != null) 'notes': notes,
    };
  }
}

class SalesReturnServiceException implements Exception {
  final String message;
  SalesReturnServiceException(this.message);

  @override
  String toString() => 'SalesReturnServiceException: $message';
}

class SalesReturnService {
  final Dio _dio = DioClient.instance.client;

  Future<void> logReturn({required String routeId, required ReturnItemLog item}) async {
    try {
      await _dio.post(
        '/sales-routes/$routeId/log-return',
        data: item.toJson(),
      );
    } on DioException catch (e) {
      throw SalesReturnServiceException(
        e.response?.data?['message'] ?? e.message ?? 'Unknown error logging return item',
      );
    } catch (e) {
      throw SalesReturnServiceException('Failed to process return item logging: $e');
    }
  }
}
