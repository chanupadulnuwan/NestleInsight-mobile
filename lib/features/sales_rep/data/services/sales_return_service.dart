import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_error_helper.dart';

class ReturnItemLog {
  final String productId;
  final String productName;
  final int quantityCases;
  final int quantityUnits;
  final String unitType;
  final String reason;
  final String? notes;

  ReturnItemLog({
    required this.productId,
    required this.productName,
    required this.quantityCases,
    required this.quantityUnits,
    required this.unitType,
    required this.reason,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantityCases': quantityCases,
      'quantityUnits': quantityUnits,
      'unitType': unitType,
      'reason': reason,
      if (notes != null) 'notes': notes,
    };
  }

  Map<String, dynamic> toLegacyJson() {
    final isUnitEntry = quantityUnits > 0 && quantityCases == 0;
    final legacyNotes = <String>[
      if (notes != null && notes!.trim().isNotEmpty) notes!.trim(),
      if (isUnitEntry) 'Entered as product units: $quantityUnits product(s).',
    ].join('\n');

    return {
      'productId': productId,
      'productName': productName,
      'quantityCases': quantityCases > 0 ? quantityCases : quantityUnits,
      'reason': reason,
      if (legacyNotes.isNotEmpty) 'notes': legacyNotes,
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

  Future<void> logReturn({
    required String routeId,
    required ReturnItemLog item,
  }) async {
    try {
      await _dio.post('/sales-routes/$routeId/log-return', data: item.toJson());
    } on DioException catch (e) {
      final message = extractBackendErrorMessage(
        e,
        fallbackMessage: 'Unknown error logging return item',
      );
      if (_isLegacyReturnDtoError(message)) {
        try {
          await _dio.post(
            '/sales-routes/$routeId/log-return',
            data: item.toLegacyJson(),
          );
          return;
        } on DioException catch (legacyError) {
          throw SalesReturnServiceException(
            extractBackendErrorMessage(
              legacyError,
              fallbackMessage: 'Unknown error logging return item',
            ),
          );
        }
      }

      throw SalesReturnServiceException(message);
    } catch (e) {
      throw SalesReturnServiceException(
        'Failed to process return item logging: $e',
      );
    }
  }

  bool _isLegacyReturnDtoError(String message) {
    return message.contains('quantityUnits should not exist') ||
        message.contains('unitType should not exist');
  }
}
