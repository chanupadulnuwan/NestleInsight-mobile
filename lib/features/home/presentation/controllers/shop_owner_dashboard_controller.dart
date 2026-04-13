import 'package:flutter/foundation.dart';
import 'package:mobile/features/activity/data/services/activity_feed_service.dart';
import 'package:mobile/features/activity/domain/activity_entry.dart';
import 'package:mobile/features/home/data/services/product_catalog_service.dart';
import 'package:mobile/features/home/domain/shop_catalog_product.dart';
import 'package:mobile/features/orders/data/services/order_service.dart';
import 'package:mobile/features/orders/domain/shop_cart_item.dart';
import 'package:mobile/features/orders/domain/shop_order.dart';

class CartReplacementResult {
  const CartReplacementResult({
    required this.addedCount,
    required this.unavailableProductNames,
  });

  final int addedCount;
  final List<String> unavailableProductNames;

  bool get hasUnavailableProducts => unavailableProductNames.isNotEmpty;
}

class ShopOwnerDashboardController extends ChangeNotifier {
  ShopOwnerDashboardController({
    OrderService? orderService,
    ActivityFeedService? activityFeedService,
    ProductCatalogService? productCatalogService,
  }) : _orderService = orderService ?? OrderService(),
       _activityFeedService = activityFeedService ?? ActivityFeedService(),
       _productCatalogService = productCatalogService ?? ProductCatalogService();

  final OrderService _orderService;
  final ActivityFeedService _activityFeedService;
  final ProductCatalogService _productCatalogService;

  final Map<String, int> _selectedQuantities = <String, int>{};
  final Map<String, ShopCartItem> _cartItems = <String, ShopCartItem>{};

  List<ShopCatalogProduct> _catalogProducts = <ShopCatalogProduct>[];
  List<String> _catalogCategories = const <String>['All'];
  List<ShopOrder> _orders = <ShopOrder>[];
  List<ActivityEntry> _activities = <ActivityEntry>[];
  bool _isLoadingCatalog = false;
  bool _isLoadingOrders = false;
  bool _isLoadingActivities = false;
  bool _isPlacingOrder = false;
  bool _isSubmittingFeedback = false;
  String? _catalogError;
  String? _ordersError;
  String? _activitiesError;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<ShopCatalogProduct> get catalog {
    final normalizedQuery = _searchQuery.trim().toLowerCase();

    return _catalogProducts.where((product) {
      final matchesCategory = _selectedCategory == 'All' ||
          product.categoryName == _selectedCategory;
      final matchesQuery = normalizedQuery.isEmpty ||
          product.searchText.contains(normalizedQuery);
      return matchesCategory && matchesQuery;
    }).toList(growable: false);
  }

  List<ShopCatalogProduct> get allCatalogProducts =>
      List<ShopCatalogProduct>.unmodifiable(_catalogProducts);

  List<String> get catalogCategories => _catalogCategories;
  List<ShopOrder> get orders => _orders;
  List<ActivityEntry> get activities => _activities;
  List<ShopCartItem> get cartItems => _cartItems.values.toList(growable: false);
  bool get isLoadingCatalog => _isLoadingCatalog;
  bool get isLoadingOrders => _isLoadingOrders;
  bool get isLoadingActivities => _isLoadingActivities;
  bool get isPlacingOrder => _isPlacingOrder;
  bool get isSubmittingFeedback => _isSubmittingFeedback;
  String? get catalogError => _catalogError;
  String? get ordersError => _ordersError;
  String? get activitiesError => _activitiesError;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get hasCartItems => _cartItems.isNotEmpty;
  bool get hasCatalogProducts => _catalogProducts.isNotEmpty;
  int get cartQuantityTotal =>
      _cartItems.values.fold(0, (sum, item) => sum + item.quantity);
  double get cartTotal =>
      _cartItems.values.fold(0, (sum, item) => sum + item.lineTotal);
  ShopOrder? get latestOrder => _orders.isEmpty ? null : _orders.first;

  int selectedQuantityFor(String productId) => _selectedQuantities[productId] ?? 1;

  Future<void> loadCatalog() async {
    _isLoadingCatalog = true;
    _catalogError = null;
    notifyListeners();

    try {
      final result = await _productCatalogService.fetchCatalog();
      _catalogProducts = result.products.where((product) => product.isAvailable).toList(
            growable: false,
          );
      _catalogCategories = <String>[
        'All',
        ...result.categories.where((category) => category.trim().isNotEmpty),
      ];

      if (!_catalogCategories.contains(_selectedCategory)) {
        _selectedCategory = 'All';
      }

      for (final product in _catalogProducts) {
        _selectedQuantities.putIfAbsent(product.id, () => 1);
      }

      final activeIds = _catalogProducts.map((product) => product.id).toSet();
      _selectedQuantities.removeWhere((productId, _) => !activeIds.contains(productId));
    } on ProductCatalogServiceException catch (error) {
      _catalogError = error.message;
    } finally {
      _isLoadingCatalog = false;
      notifyListeners();
    }
  }

  void updateSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void resetCatalogFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    notifyListeners();
  }

  // TODO: Replace these fallback quantity limits with product-level min/max values from admin master data.
  void incrementSelection(String productId) {
    final current = selectedQuantityFor(productId);
    _selectedQuantities[productId] = current >= 99 ? 99 : current + 1;
    notifyListeners();
  }

  void decrementSelection(String productId) {
    final current = selectedQuantityFor(productId);
    _selectedQuantities[productId] = current <= 1 ? 1 : current - 1;
    notifyListeners();
  }

  void addToCart(ShopCatalogProduct product) {
    final currentItem = _cartItems[product.id];
    final selectedQuantity = selectedQuantityFor(product.id);
    final nextQuantity = currentItem == null
        ? selectedQuantity
        : (currentItem.quantity + selectedQuantity).clamp(1, 99);

    _cartItems[product.id] = ShopCartItem(
      product: product,
      quantity: nextQuantity,
    );
    notifyListeners();
  }

  CartReplacementResult replaceCartWithOrder(ShopOrder order) {
    final catalogById = <String, ShopCatalogProduct>{
      for (final product in _catalogProducts) product.id: product,
    };
    final unavailableProductNames = <String>[];

    _cartItems.clear();

    for (final item in order.items) {
      final productId = item.productId;
      final matchedProduct =
          productId == null ? null : catalogById[productId];

      if (matchedProduct == null || !item.isCurrentlyAvailable) {
        unavailableProductNames.add(item.productName);
        continue;
      }

      final existingItem = _cartItems[matchedProduct.id];
      final nextQuantity = existingItem == null
          ? item.quantity
          : (existingItem.quantity + item.quantity).clamp(1, 99);

      _cartItems[matchedProduct.id] = ShopCartItem(
        product: matchedProduct,
        quantity: nextQuantity,
      );
    }

    notifyListeners();

    return CartReplacementResult(
      addedCount: _cartItems.length,
      unavailableProductNames: unavailableProductNames,
    );
  }

  void updateCartQuantity(String productId, int quantity) {
    final item = _cartItems[productId];
    if (item == null) return;
    if (quantity <= 0) {
      _cartItems.remove(productId);
    } else {
      _cartItems[productId] = item.copyWith(quantity: quantity.clamp(1, 99));
    }
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
