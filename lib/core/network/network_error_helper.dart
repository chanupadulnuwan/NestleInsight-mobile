import 'package:dio/dio.dart';

String extractBackendErrorMessage(
  DioException error, {
  required String fallbackMessage,
}) {
  final data = error.response?.data;

  if (data is String) {
    final message = data.trim();
    if (message.isNotEmpty) {
      return message;
    }
  }

  if (data is Map) {
    final rawMessage = data['message'] ?? data['error'] ?? data['detail'];

    if (rawMessage is String && rawMessage.isNotEmpty) {
      return rawMessage;
    }

    if (rawMessage is List && rawMessage.isNotEmpty) {
      return rawMessage.map((item) => item.toString()).join('\n');
    }
  }

  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      final baseUrl = error.requestOptions.baseUrl;
      return baseUrl.isEmpty
          ? 'Cannot reach the backend right now. Make sure the server is running and accessible from this device.'
          : 'Cannot reach the backend at $baseUrl. Make sure the server is running and accessible from this device.';
    default:
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
      return fallbackMessage;
  }
}

String? extractBackendErrorCode(DioException error) {
  final data = error.response?.data;

  if (data is Map) {
    final code = data['code'];
    if (code is String && code.isNotEmpty) {
      return code;
    }
  }

  return null;
}
