import 'package:mobile/features/home/domain/shop_catalog_product.dart';

class ShopCartItem {
  const ShopCartItem({required this.product, required this.quantity});

  final ShopCatalogProduct product;
  final int quantity;

  double get lineTotal => product.orderPrice * quantity;

  ShopCartItem copyWith({ShopCatalogProduct? product, int? quantity}) {
    return ShopCartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
