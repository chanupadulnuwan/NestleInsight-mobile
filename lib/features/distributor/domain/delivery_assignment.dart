class OrderItem {
  const OrderItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.lineTotal,
    required this.unitPrice,
    required this.itemUnitPrice,
    required this.productsPerCase,
    this.productId,
    this.packSize,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String? ?? '',
      productId: json['productId'] as String?,
      productName: json['productName'] as String? ?? '--',
      quantity: json['quantity'] as int? ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
      unitPrice:
          ((json['casePrice'] ?? json['unitPrice']) as num?)?.toDouble() ?? 0,
      itemUnitPrice: (json['itemUnitPrice'] as num?)?.toDouble() ?? 0,
      productsPerCase: json['productsPerCase'] as int? ?? 1,
      packSize: json['packSize'] as String?,
    );
  }

  final String id;
  final String? productId;
  final String productName;
  final int quantity;
  final double lineTotal;
  final double unitPrice;
  final double itemUnitPrice;
  final int productsPerCase;
  final String? packSize;

  double get casePrice => unitPrice;

  double get resolvedItemUnitPrice {
    if (itemUnitPrice > 0) {
      return itemUnitPrice;
    }
    if (productsPerCase > 0) {
      return unitPrice / productsPerCase;
    }
    return unitPrice;
  }
}

class AssignmentOrder {
  const AssignmentOrder({
    required this.daoId,
    required this.orderId,
    required this.orderCode,
    required this.shopName,
    required this.totalAmount,
    required this.status,
    required this.sortOrder,
    required this.items,
    required this.paymentMethod,
    required this.appliedPromotionCode,
    required this.subtotalBeforeDiscount,
    required this.promotionDiscountTotal,
    required this.totalAfterDiscount,
    this.shopPhone,
    this.shopAddress,
    this.shopLatitude,
    this.shopLongitude,
    this.currencyCode = 'LKR',
  });

  factory AssignmentOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return AssignmentOrder(
      daoId: json['daoId'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      orderCode: json['orderCode'] as String? ?? '--',
      shopName: json['shopName'] as String? ?? '--',
      shopPhone: json['shopPhone'] as String?,
      shopAddress: json['shopAddress'] as String?,
      shopLatitude: (json['shopLatitude'] as num?)?.toDouble(),
      shopLongitude: (json['shopLongitude'] as num?)?.toDouble(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      currencyCode: json['currencyCode'] as String? ?? 'LKR',
      paymentMethod: json['paymentMethod'] as String? ?? 'STANDARD',
      appliedPromotionCode: json['appliedPromotionCode'] as String?,
      subtotalBeforeDiscount:
          (json['subtotalBeforeDiscount'] as num?)?.toDouble(),
      promotionDiscountTotal:
          (json['promotionDiscountTotal'] as num?)?.toDouble(),
      totalAfterDiscount: (json['totalAfterDiscount'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'UNKNOWN',
      sortOrder: json['sortOrder'] as int? ?? 0,
      items: rawItems
          .map((i) => OrderItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
    );
  }

  final String daoId;
  final String orderId;
  final String orderCode;
  final String shopName;
  final String? shopPhone;
  final String? shopAddress;
  final double? shopLatitude;
  final double? shopLongitude;
  final double totalAmount;
  final String currencyCode;
  final String paymentMethod;
  final String? appliedPromotionCode;
  final double? subtotalBeforeDiscount;
  final double? promotionDiscountTotal;
  final double? totalAfterDiscount;
  final String status;
  final int sortOrder;
  final List<OrderItem> items;

  bool get isCompleted => status == 'COMPLETED';
  double get effectiveTotal => totalAfterDiscount ?? totalAmount;
}

class RecordedReturnItem {
  const RecordedReturnItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.reason,
    this.productId,
    this.unitType,
    this.reasonNote,
  });

  factory RecordedReturnItem.fromJson(Map<String, dynamic> json) {
    return RecordedReturnItem(
      id: json['id'] as String? ?? '',
      productId: json['productId'] as String?,
      productName: json['productName'] as String? ?? '--',
      quantity: json['quantity'] as int? ?? 0,
      reason: json['reason'] as String? ?? '',
      unitType: json['unitType'] as String?,
      reasonNote: json['reasonNote'] as String?,
    );
  }

  final String id;
  final String? productId;
  final String productName;
  final int quantity;
  final String reason;
  final String? unitType;
  final String? reasonNote;
}

class RecordedReturn {
  const RecordedReturn({
    required this.id,
    required this.returnType,
    required this.tmVerified,
    required this.estimatedValue,
    required this.items,
    required this.createdAt,
    this.assignmentId,
    this.orderId,
    this.orderCode,
    this.shopName,
    this.verificationNote,
  });

  factory RecordedReturn.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return RecordedReturn(
      id: json['id'] as String? ?? '',
      assignmentId: json['assignmentId'] as String?,
      orderId: json['orderId'] as String?,
      orderCode: json['orderCode'] as String?,
      shopName: json['shopName'] as String?,
      returnType: json['returnType'] as String? ?? 'WAREHOUSE',
      tmVerified: json['tmVerified'] as bool? ?? false,
      verificationNote: json['verificationNote'] as String?,
      estimatedValue: (json['estimatedValue'] as num?)?.toDouble() ?? 0,
      items: rawItems
          .map(
            (item) => RecordedReturnItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String id;
  final String? assignmentId;
  final String? orderId;
  final String? orderCode;
  final String? shopName;
  final String returnType;
  final bool tmVerified;
  final String? verificationNote;
  final double estimatedValue;
  final List<RecordedReturnItem> items;
  final DateTime createdAt;
}

class DeliveryAssignment {
  const DeliveryAssignment({
    required this.id,
    required this.distributorId,
    required this.distributorName,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.vehicleCapacityCases,
    required this.vehicleRegistrationNumber,
    required this.vehicleType,
    required this.deliveryDate,
    required this.status,
    required this.notes,
    required this.expectedCashAmount,
    required this.cashReturnedAmount,
    required this.cashVarianceAmount,
    required this.cashVarianceType,
    required this.cashVarianceReason,
    required this.settlementCompletedAt,
    required this.orders,
    required this.returns,
  });

  factory DeliveryAssignment.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['orders'] as List<dynamic>? ?? [];
    final rawReturns = json['returns'] as List<dynamic>? ?? [];
    return DeliveryAssignment(
      id: json['id'] as String,
      distributorId: json['distributorId'] as String? ?? '',
      distributorName: json['distributorName'] as String? ?? '',
      vehicleId: json['vehicleId'] as String?,
      vehicleLabel: json['vehicleLabel'] as String?,
      vehicleCapacityCases: json['vehicleCapacityCases'] as int?,
      vehicleRegistrationNumber: json['vehicleRegistrationNumber'] as String?,
      vehicleType: json['vehicleType'] as String?,
      deliveryDate: json['deliveryDate'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      notes: json['notes'] as String?,
      expectedCashAmount: (json['expectedCashAmount'] as num?)?.toDouble(),
      cashReturnedAmount: (json['cashReturnedAmount'] as num?)?.toDouble(),
      cashVarianceAmount: (json['cashVarianceAmount'] as num?)?.toDouble(),
      cashVarianceType: json['cashVarianceType'] as String?,
      cashVarianceReason: json['cashVarianceReason'] as String?,
      settlementCompletedAt: DateTime.tryParse(
        json['settlementCompletedAt'] as String? ?? '',
      ),
      orders: rawOrders
          .map(
            (o) => AssignmentOrder.fromJson(
              Map<String, dynamic>.from(o as Map),
            ),
          )
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      returns: rawReturns
          .map(
            (entry) =>
                RecordedReturn.fromJson(Map<String, dynamic>.from(entry as Map)),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  final String id;
  final String distributorId;
  final String distributorName;
  final String? vehicleId;
  final String? vehicleLabel;
  final int? vehicleCapacityCases;
  final String? vehicleRegistrationNumber;
  final String? vehicleType;
  final String deliveryDate;
  final String status;
  final String? notes;
  final double? expectedCashAmount;
  final double? cashReturnedAmount;
  final double? cashVarianceAmount;
  final String? cashVarianceType;
  final String? cashVarianceReason;
  final DateTime? settlementCompletedAt;
  final List<AssignmentOrder> orders;
  final List<RecordedReturn> returns;

  int get completedCount => orders.where((order) => order.isCompleted).length;
  int get totalCount => orders.length;
  bool get isActive => status == 'ACTIVE';
  int get remainingStopsCount =>
      orders.where((order) => !order.isCompleted).length;
  List<RecordedReturn> get shopReturns =>
      returns.where((entry) => entry.returnType == 'SHOP').toList();
  double get recordedShopReturnValue => shopReturns.fold(
    0,
    (sum, entry) => sum + entry.estimatedValue,
  );
  double get completedDeliveredValue => orders
      .where((order) => order.isCompleted)
      .fold(0, (sum, order) => sum + order.effectiveTotal);
  double get expectedRouteCash {
    final expected = completedDeliveredValue - recordedShopReturnValue;
    return expected < 0 ? 0 : expected;
  }

  List<OrderItem> get lorryInventory {
    final map = <String, _LorryItem>{};
    for (final order in orders.where((entry) => !entry.isCompleted)) {
      for (final item in order.items) {
        final key = item.productId ?? item.productName;
        if (map.containsKey(key)) {
          map[key]!.quantity += item.quantity;
          map[key]!.value += item.lineTotal;
        } else {
          map[key] = _LorryItem(
            productId: item.productId,
            productName: item.productName,
            quantity: item.quantity,
            value: item.lineTotal,
            unitPrice: item.unitPrice,
            itemUnitPrice: item.itemUnitPrice,
            productsPerCase: item.productsPerCase,
            packSize: item.packSize,
          );
        }
      }
    }
    return map.values
        .map(
          (entry) => OrderItem(
            id: entry.productId ?? entry.productName,
            productId: entry.productId,
            productName: entry.productName,
            quantity: entry.quantity,
            lineTotal: entry.value,
            unitPrice: entry.unitPrice,
            itemUnitPrice: entry.itemUnitPrice,
            productsPerCase: entry.productsPerCase,
            packSize: entry.packSize,
          ),
        )
        .toList()
      ..sort((a, b) => a.productName.compareTo(b.productName));
  }
}

class _LorryItem {
  _LorryItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.value,
    required this.unitPrice,
    required this.itemUnitPrice,
    required this.productsPerCase,
    required this.packSize,
  });

  final String? productId;
  final String productName;
  int quantity;
  double value;
  final double unitPrice;
  final double itemUnitPrice;
  final int productsPerCase;
  final String? packSize;
}

class ReturnItemInput {
  ReturnItemInput({
    required this.productNameSnapshot,
    required this.quantity,
    required this.reason,
    this.productId,
    this.unitType = 'CASE',
    this.reasonNote,
    this.unitPrice,
    this.itemUnitPrice,
    this.productsPerCase,
  });

  String? productId;
  String productNameSnapshot;
  int quantity;
  String reason;
  String unitType;
  String? reasonNote;
  double? unitPrice;
  double? itemUnitPrice;
  int? productsPerCase;

  Map<String, dynamic> toJson() => {
        if (productId != null) 'productId': productId,
        'productNameSnapshot': productNameSnapshot,
        'quantity': quantity,
        'unitType': unitType,
        'reason': reason,
        if (reasonNote != null) 'reasonNote': reasonNote,
        if (unitPrice != null) 'unitPrice': unitPrice,
        if (itemUnitPrice != null) 'itemUnitPrice': itemUnitPrice,
        if (productsPerCase != null) 'productsPerCase': productsPerCase,
      };

  double get totalValue {
    if (unitType.trim().toUpperCase() == 'ITEM') {
      return (itemUnitPrice ?? 0) * quantity;
    }
    return (unitPrice ?? 0) * quantity;
  }
}
