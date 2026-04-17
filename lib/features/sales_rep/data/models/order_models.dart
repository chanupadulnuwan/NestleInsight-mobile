class Product {
  final String id;
  final String name;
  final double price;

  Product({required this.id, required this.name, required this.price});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'price': price};
}

class OrderItem {
  final String productId;
  final int quantity;

  OrderItem({required this.productId, required this.quantity});

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
  };
}

class RequestAssistedOrderPinRequest {
  final String routeId;
  final String shopId;
  final List<OrderItem> items;

  RequestAssistedOrderPinRequest({
    required this.routeId,
    required this.shopId,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'routeId': routeId,
    'shopId': shopId,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

class AssistedOrderPinRequestResult {
  const AssistedOrderPinRequestResult({
    required this.message,
    required this.assistedOrderRequestId,
    required this.status,
    required this.requiresPin,
    this.expiresAt,
  });

  factory AssistedOrderPinRequestResult.fromJson(Map<String, dynamic> json) {
    return AssistedOrderPinRequestResult(
      message:
          json['message']?.toString() ??
          'Confirmation PIN request completed successfully.',
      assistedOrderRequestId:
          json['assistedOrderRequestId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING_SHOP_PIN',
      requiresPin: json['requiresPin'] == true,
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
    );
  }

  final String message;
  final String assistedOrderRequestId;
  final String status;
  final bool requiresPin;
  final DateTime? expiresAt;
}

class ConfirmAssistedOrderPinRequest {
  const ConfirmAssistedOrderPinRequest({
    required this.pin,
    required this.assistedReason,
  });

  final String pin;
  final String assistedReason;

  Map<String, dynamic> toJson() => {
    'pin': pin,
    'assistedReason': assistedReason,
  };
}

class AssistedOrderPinConfirmResult {
  const AssistedOrderPinConfirmResult({
    required this.message,
    required this.orderId,
    required this.orderCode,
  });

  factory AssistedOrderPinConfirmResult.fromJson(Map<String, dynamic> json) {
    final rawOrder = json['order'];
    final order = rawOrder is Map<String, dynamic>
        ? rawOrder
        : <String, dynamic>{};

    return AssistedOrderPinConfirmResult(
      message:
          json['message']?.toString() ?? 'Assisted order created successfully.',
      orderId: order['id']?.toString() ?? '',
      orderCode: order['orderCode']?.toString() ?? '',
    );
  }

  final String message;
  final String orderId;
  final String orderCode;
}
