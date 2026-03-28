import 'package:mobile/core/config/app_config.dart';

class ShopCatalogProduct {
  const ShopCatalogProduct({
    required this.id,
    required this.sku,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.packSize,
    required this.productsPerCase,
    required this.unitPrice,
    required this.casePrice,
    required this.status,
    this.brand,
    this.description,
    this.imageUrl,
    this.isAvailable = true,
  });

  factory ShopCatalogProduct.fromJson(Map<String, dynamic> json) {
    return ShopCatalogProduct(
      id: json['id'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      name: json['productName'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      brand: json['brand'] as String?,
      packSize: json['packSize'] as String? ?? '',
      productsPerCase: _readInt(json['productsPerCase']),
      unitPrice: _readDouble(json['unitPrice']),
      casePrice: _readDouble(json['casePrice']),
      description: _readNullableString(json['description']),
      imageUrl: AppConfig.resolveApiUrl(json['imageUrl'] as String?),
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  factory ShopCatalogProduct.unavailableFromSnapshot({
    required String id,
    required String sku,
    required String name,
    required String packSize,
    required double casePrice,
    String? imageUrl,
  }) {
    return ShopCatalogProduct(
      id: id,
      sku: sku,
      name: name,
      categoryId: '',
      categoryName: 'Unavailable',
      packSize: packSize,
      productsPerCase: 0,
      unitPrice: 0,
      casePrice: casePrice,
      status: 'INACTIVE',
      description: 'This product is currently unavailable.',
      imageUrl: AppConfig.resolveApiUrl(imageUrl),
      isAvailable: false,
    );
  }

  final String id;
  final String sku;
  final String name;
  final String categoryId;
  final String categoryName;
  final String? brand;
  final String packSize;
  final int productsPerCase;
  final double unitPrice;
  final double casePrice;
  final String? description;
  final String? imageUrl;
  final String status;
  final bool isAvailable;

  String get badgeLabel {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .toList(growable: false);

    if (parts.isNotEmpty) {
      return parts.join();
    }

    if (sku.isNotEmpty) {
      return sku.substring(0, sku.length >= 2 ? 2 : 1).toUpperCase();
    }

    return 'PR';
  }

  String get caseInfo => productsPerCase > 0
      ? productsPerCase == 1
          ? '1 product per case'
          : '$productsPerCase products per case'
      : 'Currently unavailable';

  String get unitLabel => '/ case';

  double get orderPrice => casePrice;

  String get displayDescription {
    final normalizedDescription = description?.trim();
    if (normalizedDescription != null && normalizedDescription.isNotEmpty) {
      return normalizedDescription;
    }

    if (brand != null && brand!.trim().isNotEmpty && packSize.isNotEmpty) {
      return '${brand!.trim()} - $packSize';
    }

    if (packSize.isNotEmpty) {
      return packSize;
    }

    return 'Product details available.';
  }

  String get searchText => [
        name,
        sku,
        categoryName,
        brand ?? '',
        packSize,
        description ?? '',
      ].join(' ').toLowerCase();
}

double _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _readInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _readNullableString(dynamic value) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}
