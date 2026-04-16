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

class CreateSalesOrderRequest {
  final String routeId;
  final String shopId;
  final List<OrderItem> items;

  CreateSalesOrderRequest({
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
