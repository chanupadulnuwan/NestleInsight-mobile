import 'package:mobile/features/home/domain/shop_catalog_product.dart';
import 'package:mobile/features/orders/domain/shop_cart_item.dart';

class ShopOrderItem {
  const ShopOrderItem({
    required this.id,
    required this.productCode,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.imageAssetPath,
  });

  factory ShopOrderItem.fromJson(Map<String, dynamic> json) {
    return ShopOrderItem(
      id: json['id'] as String? ?? '',
      productCode: json['productCode'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      unitPrice: _readDouble(json['unitPrice']),
      quantity: _readInt(json['quantity']),
      lineTotal: _readDouble(json['lineTotal']),
      imageAssetPath: json['imageAssetPath'] as String?,
    );
  }

  final String id;
  final String productCode;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final String? imageAssetPath;

  ShopCartItem toCartItem(Map<String, ShopCatalogProduct> catalogByCode) {
    final matchedProduct = catalogByCode[productCode];
    return ShopCartItem(
      product:
          matchedProduct ??
          ShopCatalogProduct(
            code: productCode,
            name: productName,
            description: 'Saved from previous order',
            caseInfo: 'Previous order item',
            unitPrice: unitPrice,
            unitLabel: '/ case',
            imageAssetPath: imageAssetPath ?? '',
            badgeLabel: productName.isNotEmpty
                ? productName.substring(0, 1).toUpperCase()
                : 'P',
          ),
      quantity: quantity,
    );
  }
}

class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.orderCode,
    required this.shopName,
    required this.status,
    required this.currencyCode,
    required this.totalAmount,
    required this.placedAt,
    required this.items,
  });

  factory ShopOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((item) => ShopOrderItem.fromJson(Map<String, dynamic>.from(item)))
              .toList()
        : const <ShopOrderItem>[];

    return ShopOrder(
      id: json['id'] as String? ?? '',
      orderCode: json['orderCode'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      currencyCode: json['currencyCode'] as String? ?? 'LKR',
      totalAmount: _readDouble(json['totalAmount']),
      placedAt: DateTime.tryParse(json['placedAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      items: items,
    );
  }

  final String id;
  final String orderCode;
  final String shopName;
  final String status;
  final String currencyCode;
  final double totalAmount;
  final DateTime placedAt;
  final List<ShopOrderItem> items;
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
