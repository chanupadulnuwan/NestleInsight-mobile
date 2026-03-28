import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/network/network_error_helper.dart';
import 'package:mobile/features/home/domain/shop_catalog_product.dart';

class ProductCatalogServiceException implements Exception {
  const ProductCatalogServiceException(this.message, {this.code});

  final String message;
  final String? code;
}

class ProductCatalogResult {
  const ProductCatalogResult({
    required this.message,
    required this.categories,
    required this.products,
  });

  factory ProductCatalogResult.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    final categories = rawCategories is List
        ? rawCategories
              .whereType<Map>()
              .map((category) => category['name']?.toString().trim() ?? '')
              .where((name) => name.isNotEmpty)
              .toSet()
              .toList()
        : const <String>[];

    final rawProducts = json['products'];
    final products = rawProducts is List
        ? rawProducts
              .whereType<Map>()
              .map(
                (product) =>
                    ShopCatalogProduct.fromJson(Map<String, dynamic>.from(product)),
              )
              .toList()
        : const <ShopCatalogProduct>[];

    return ProductCatalogResult(
      message: json['message'] as String? ?? 'Catalog loaded successfully.',
      categories: categories,
      products: products,
    );
  }

  final String message;
  final List<String> categories;
  final List<ShopCatalogProduct> products;
}

class ProductCatalogService {
  ProductCatalogService({Dio? dio}) : _dio = dio ?? DioClient.instance.client;

  final Dio _dio;

  Future<ProductCatalogResult> fetchCatalog() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/products/catalog');
      return ProductCatalogResult.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw ProductCatalogServiceException(
        extractBackendErrorMessage(
          error,
          fallbackMessage: 'Unable to load the product catalog right now.',
        ),
        code: extractBackendErrorCode(error),
      );
    }
  }
}
