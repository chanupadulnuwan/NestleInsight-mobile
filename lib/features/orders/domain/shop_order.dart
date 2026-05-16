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
    required this.subtotalBeforeDiscount,
    required this.promotionDiscountTotal,
    required this.totalAfterDiscount,
    required this.placedAt,
    required this.items,
    this.appliedPromotionCode,
    this.paymentMethod = 'STANDARD',
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
      subtotalBeforeDiscount: _readOptionalDouble(json['subtotalBeforeDiscount']) ??
          _readDouble(json['totalAmount']),
      promotionDiscountTotal:
          _readOptionalDouble(json['promotionDiscountTotal']) ?? 0,
      totalAfterDiscount: _readOptionalDouble(json['totalAfterDiscount']) ??
          _readDouble(json['totalAmount']),
      placedAt: DateTime.tryParse(json['placedAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      appliedPromotionCode: json['appliedPromotionCode'] as String?,
      paymentMethod: json['paymentMethod'] as String? ?? 'STANDARD',
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
  final double subtotalBeforeDiscount;
  final double promotionDiscountTotal;
  final double totalAfterDiscount;
  final DateTime placedAt;
  final String? appliedPromotionCode;
  final String paymentMethod;
  final String? customerNote;
  final String? delayReason;
  final DateTime? delayedAt;
  final DateTime? deliveryDueAt;
  final bool isOverdue;
  final List<ShopOrderItem> items;

  String get paymentMethodLabel {
    if (paymentMethod.toUpperCase() == 'CASH_ON_DELIVERY') {
      return 'Cash on delivery';
    }

    return 'Standard checkout';
  }
}

double _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _readOptionalDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

int _readInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
