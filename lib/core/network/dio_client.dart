import 'package:dio/dio.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/storage/token_storage_service.dart';

class DioClient {
  DioClient._internal();

  static final DioClient instance = DioClient._internal();

  final TokenStorageService _tokenStorageService = TokenStorageService();

  late final Dio _client =
      Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            contentType: Headers.jsonContentType,
            responseType: ResponseType.json,
            headers: const {'Accept': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await _tokenStorageService.readAccessToken();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
          ),
        );

  Dio get client => _client;
}
