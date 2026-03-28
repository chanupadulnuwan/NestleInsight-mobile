import 'package:mobile/core/config/app_config.dart';

class ShopOrderItem {
  const ShopOrderItem({
    required this.id,
    required this.productId,
    required this.sku,
    required this.productName,
    required this.casePrice,
    required this.quantity,
    required this.lineTotal,
    required this.isCurrentlyAvailable,
    this.packSize,
    this.imageUrl,
  });

  factory ShopOrderItem.fromJson(Map<String, dynamic> json) {
    return ShopOrderItem(
      id: json['id'] as String? ?? '',
      productId: json['productId'] as String?,
      sku: json['sku'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      packSize: json['packSize'] as String?,
      imageUrl: AppConfig.resolveApiUrl(json['imageUrl'] as String?),
      casePrice: _readDouble(json['casePrice']),
      quantity: _readInt(json['quantity']),
      lineTotal: _readDouble(json['lineTotal']),
      isCurrentlyAvailable: json['isCurrentlyAvailable'] == true,
    );
  }

  final String id;
  final String? productId;
  final String sku;
  final String productName;
  final String? packSize;
  final String? imageUrl;
  final double casePrice;
  final int quantity;
  final double lineTotal;
  final bool isCurrentlyAvailable;
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
    this.customerNote,
    this.delayReason,
    this.delayedAt,
    this.deliveryDueAt,
    this.isOverdue = false,
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
      customerNote: json['customerNote'] as String?,
      delayReason: json['delayReason'] as String?,
      delayedAt: DateTime.tryParse(
        json['delayedAt'] as String? ?? '',
      )?.toLocal(),
      deliveryDueAt: DateTime.tryParse(
        json['deliveryDueAt'] as String? ?? '',
      )?.toLocal(),
      isOverdue: json['isOverdue'] == true,
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
  final String? customerNote;
  final String? delayReason;
  final DateTime? delayedAt;
  final DateTime? deliveryDueAt;
  final bool isOverdue;
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
