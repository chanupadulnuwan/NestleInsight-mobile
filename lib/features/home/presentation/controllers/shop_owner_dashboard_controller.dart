import 'package:flutter/foundation.dart';
import 'package:mobile/features/activity/data/services/activity_feed_service.dart';
import 'package:mobile/features/activity/domain/activity_entry.dart';
import 'package:mobile/features/home/domain/shop_catalog_product.dart';
import 'package:mobile/features/orders/data/services/order_service.dart';
import 'package:mobile/features/orders/domain/shop_cart_item.dart';
import 'package:mobile/features/orders/domain/shop_order.dart';

class ShopOwnerDashboardController extends ChangeNotifier {
  ShopOwnerDashboardController({
    OrderService? orderService,
    ActivityFeedService? activityFeedService,
  }) : _orderService = orderService ?? OrderService(),
       _activityFeedService = activityFeedService ?? ActivityFeedService() {
    for (final product in ShopCatalogProduct.demoCatalog) {
      _selectedQuantities[product.code] = 1;
    }
  }

  final OrderService _orderService;
  final ActivityFeedService _activityFeedService;

  final Map<String, int> _selectedQuantities = <String, int>{};
  final Map<String, ShopCartItem> _cartItems = <String, ShopCartItem>{};

  List<ShopOrder> _orders = <ShopOrder>[];
  List<ActivityEntry> _activities = <ActivityEntry>[];
  bool _isLoadingOrders = false;
  bool _isLoadingActivities = false;
  bool _isPlacingOrder = false;
  bool _isSubmittingFeedback = false;
  String? _ordersError;
  String? _activitiesError;

  List<ShopCatalogProduct> get catalog => ShopCatalogProduct.demoCatalog;
  List<ShopOrder> get orders => _orders;
  List<ActivityEntry> get activities => _activities;
  List<ShopCartItem> get cartItems => _cartItems.values.toList(growable: false);
  bool get isLoadingOrders => _isLoadingOrders;
  bool get isLoadingActivities => _isLoadingActivities;
  bool get isPlacingOrder => _isPlacingOrder;
  bool get isSubmittingFeedback => _isSubmittingFeedback;
  String? get ordersError => _ordersError;
  String? get activitiesError => _activitiesError;
  bool get hasCartItems => _cartItems.isNotEmpty;
  int get cartQuantityTotal =>
      _cartItems.values.fold(0, (sum, item) => sum + item.quantity);
  double get cartTotal =>
      _cartItems.values.fold(0, (sum, item) => sum + item.lineTotal);
  ShopOrder? get latestOrder => _orders.isEmpty ? null : _orders.first;

  int selectedQuantityFor(String productCode) =>
      _selectedQuantities[productCode] ?? 1;

  // TODO: Replace these fallback limits with product min/max order quantities from master data.
  void incrementSelection(String productCode) {
    final current = selectedQuantityFor(productCode);
    _selectedQuantities[productCode] = current >= 99 ? 99 : current + 1;
    notifyListeners();
  }

  void decrementSelection(String productCode) {
    final current = selectedQuantityFor(productCode);
    _selectedQuantities[productCode] = current <= 1 ? 1 : current - 1;
    notifyListeners();
  }

  void addToCart(ShopCatalogProduct product) {
    final currentItem = _cartItems[product.code];
    final selectedQuantity = selectedQuantityFor(product.code);
    final nextQuantity = currentItem == null
        ? selectedQuantity
        : (currentItem.quantity + selectedQuantity).clamp(1, 99);

    _cartItems[product.code] = ShopCartItem(
      product: product,
      quantity: nextQuantity,
    );
    notifyListeners();
  }

  void replaceCartWithOrder(ShopOrder order) {
    final catalogByCode = <String, ShopCatalogProduct>{
      for (final product in catalog) product.code: product,
    };

    _cartItems
      ..clear()
      ..addEntries(
        order.items.map(
          (item) => MapEntry(
            item.productCode,
            item.toCartItem(catalogByCode),
          ),
        ),
      );
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  Future<void> loadOrders() async {
    _isLoadingOrders = true;
    _ordersError = null;
    notifyListeners();

    try {
      final result = await _orderService.fetchOrders();
      _orders = result.orders;
    } on OrderServiceException catch (error) {
      _ordersError = error.message;
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  Future<void> loadActivities() async {
    _isLoadingActivities = true;
    _activitiesError = null;
    notifyListeners();

    try {
      final result = await _activityFeedService.fetchActivities();
      _activities = result.activities;
    } on ActivityFeedServiceException catch (error) {
      _activitiesError = error.message;
    } finally {
      _isLoadingActivities = false;
      notifyListeners();
    }
  }

  Future<ShopOrder> placeCurrentOrder() async {
    _isPlacingOrder = true;
    notifyListeners();

    try {
      final result = await _orderService.placeOrder(cartItems);
      _cartItems.clear();
      _orders = <ShopOrder>[result.order, ..._orders];
      await loadActivities();
      return result.order;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }

  Future<String> submitFeedback(String message) async {
    _isSubmittingFeedback = true;
    notifyListeners();

    try {
      final result = await _activityFeedService.submitFeedback(message);
      await loadActivities();
      return result.message;
    } finally {
      _isSubmittingFeedback = false;
      notifyListeners();
    }
  }
}
