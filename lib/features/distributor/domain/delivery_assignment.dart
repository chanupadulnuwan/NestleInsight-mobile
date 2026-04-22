class OrderItem {
  const OrderItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.lineTotal,
    required this.unitPrice,
    this.productId,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String? ?? '',
      productId: json['productId'] as String?,
      productName: json['productName'] as String? ?? '—',
      quantity: json['quantity'] as int? ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }

  final String id;
  final String? productId;
  final String productName;
  final int quantity;
  final double lineTotal;
  final double unitPrice;
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
      orderCode: json['orderCode'] as String? ?? '—',
      shopName: json['shopName'] as String? ?? '—',
      shopPhone: json['shopPhone'] as String?,
      shopAddress: json['shopAddress'] as String?,
      shopLatitude: (json['shopLatitude'] as num?)?.toDouble(),
      shopLongitude: (json['shopLongitude'] as num?)?.toDouble(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      currencyCode: json['currencyCode'] as String? ?? 'LKR',
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
  final String status;
  final int sortOrder;
  final List<OrderItem> items;

  bool get isCompleted => status == 'COMPLETED';
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
    required this.orders,
  });

  factory DeliveryAssignment.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['orders'] as List<dynamic>? ?? [];
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
      orders:
          rawOrders
              .map(
                (o) => AssignmentOrder.fromJson(
                  Map<String, dynamic>.from(o as Map),
                ),
              )
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
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
  final List<AssignmentOrder> orders;

  int get completedCount => orders.where((o) => o.isCompleted).length;
  int get totalCount => orders.length;
  bool get isActive => status == 'ACTIVE';

  List<OrderItem> get lorryInventory {
    final map = <String, _LorryItem>{};
    for (final order in orders.where((o) => !o.isCompleted)) {
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
          );
        }
      }
    }
    return map.values
        .map(
          (e) => OrderItem(
            id: e.productId ?? e.productName,
            productId: e.productId,
            productName: e.productName,
            quantity: e.quantity,
            lineTotal: e.value,
            unitPrice: e.unitPrice,
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
  });

  final String? productId;
  final String productName;
  int quantity;
  double value;
  final double unitPrice;
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
  });

  String? productId;
  String productNameSnapshot;
  int quantity;
  String reason;
  String unitType;
  String? reasonNote;
  double? unitPrice;

  Map<String, dynamic> toJson() => {
    if (productId != null) 'productId': productId,
    'productNameSnapshot': productNameSnapshot,
    'quantity': quantity,
    'unitType': unitType,
    'reason': reason,
    if (reasonNote != null) 'reasonNote': reasonNote,
    if (unitPrice != null) 'unitPrice': unitPrice,
  };

  double get totalValue => (unitPrice ?? 0) * quantity;
}
