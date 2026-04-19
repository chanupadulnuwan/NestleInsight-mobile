import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/home/data/services/product_catalog_service.dart';
import 'package:mobile/features/home/domain/shop_catalog_product.dart';
import 'package:mobile/features/orders/domain/shop_cart_item.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/rep_order_cubit.dart';
import 'package:mobile/features/sales_rep/presentation/widgets/pin_confirmation_dialog.dart';

import 'order_success_screen.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({
    super.key,
    required this.routeId,
    required this.shopId,
    required this.shopName,
  });

  final String routeId;
  final String shopId;
  final String shopName;

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final ProductCatalogService _productCatalogService = ProductCatalogService();
  final Map<String, int> _cart = <String, int>{};

  List<ShopCatalogProduct> _products = const <ShopCatalogProduct>[];
  bool _isLoadingCatalog = true;
  bool _isPinDialogOpen = false;
  String? _catalogError;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoadingCatalog = true;
      _catalogError = null;
    });

    try {
      final result = await _productCatalogService.fetchCatalog();
      if (!mounted) {
        return;
      }

      setState(() {
        _products = result.products
            .where((product) => product.isAvailable)
            .toList(growable: false);
      });
    } on ProductCatalogServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _catalogError = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCatalog = false;
        });
      }
    }
  }

  double get _cartTotal {
    final productsById = <String, ShopCatalogProduct>{
      for (final product in _products) product.id: product,
    };

    return _cart.entries.fold<double>(0, (sum, entry) {
      final product = productsById[entry.key];
      if (product == null) {
        return sum;
      }

      return sum + (product.orderPrice * entry.value);
    });
  }

  int get _cartItemCount =>
      _cart.values.fold<int>(0, (sum, quantity) => sum + quantity);

  List<ShopCartItem> _buildCartItems() {
    final productsById = <String, ShopCatalogProduct>{
      for (final product in _products) product.id: product,
    };

    return _cart.entries
        .map((entry) {
          final product = productsById[entry.key];
          if (product == null) {
            return null;
          }

          return ShopCartItem(product: product, quantity: entry.value);
        })
        .whereType<ShopCartItem>()
        .toList(growable: false);
  }

  void _syncCubitCart() {
    context.read<RepOrderCubit>().syncCartItems(_buildCartItems());
  }

  void _updateQuantity(String productId, int nextQuantity) {
    setState(() {
      if (nextQuantity <= 0) {
        _cart.remove(productId);
      } else {
        _cart[productId] = nextQuantity.clamp(1, 99);
      }
    });
    _syncCubitCart();
  }

  Future<void> _submitOrderRequest() async {
    _syncCubitCart();
    await context.read<RepOrderCubit>().submitOrderRequest(widget.shopId);
  }

  Future<void> _openPinDialog(String orderId) async {
    if (_isPinDialogOpen) {
      return;
    }

    setState(() {
      _isPinDialogOpen = true;
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlocProvider.value(
        value: context.read<RepOrderCubit>(),
        child: PinConfirmationDialog(
          orderId: orderId,
          shopName: widget.shopName,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _isPinDialogOpen = false;
      });
    }
  }

  Future<void> _handleSuccess(RepOrderSuccess state) async {
    final totalAmount = _cartTotal;

    if (_isPinDialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        setState(() {
          _isPinDialogOpen = false;
        });
      }
    }

    setState(() {
      _cart.clear();
    });
    context.read<RepOrderCubit>().reset();

    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OrderSuccessScreen(
          orderId: state.orderId,
          orderCode: state.orderCode,
          shopName: widget.shopName,
          assistedReason: state.assistedReason,
          totalAmount: totalAmount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RepOrderCubit, RepOrderState>(
      listener: (context, state) async {
        if (state is RepOrderPendingPin) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.proceedOrderOlive,
            ),
          );
          await _openPinDialog(state.orderId);
          return;
        }

        if (state is RepOrderDraftSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.primaryBrown,
            ),
          );
          Future<void>.delayed(const Duration(milliseconds: 500), () {
            if (!context.mounted) {
              return;
            }
            Navigator.of(context).pop();
          });
          return;
        }

        if (state is RepOrderSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.orderCode.isEmpty
                    ? state.message
                    : '${state.message} (${state.orderCode})',
              ),
              backgroundColor: AppTheme.proceedOrderOlive,
            ),
          );
          await _handleSuccess(state);
          return;
        }

        if (state is RepOrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.promotionMutedRed,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.surfaceWarm,
        appBar: AppBar(title: const Text('Assisted Order')),
        body: _isLoadingCatalog
            ? const Center(child: CircularProgressIndicator())
            : _catalogError != null
            ? _ErrorState(message: _catalogError!, onRetry: _loadCatalog)
            : BlocBuilder<RepOrderCubit, RepOrderState>(
                builder: (context, state) {
                  final isLoading = state is RepOrderLoading;

                  return Column(
                    children: <Widget>[
                      Expanded(
                        child: _ProductSelectionView(
                          shopName: widget.shopName,
                          products: _products,
                          cart: _cart,
                          onQuantityChanged: _updateQuantity,
                        ),
                      ),
                      _BottomBar(
                        itemCount: _cartItemCount,
                        totalAmount: _cartTotal,
                        isLoading: isLoading,
                        onSubmit: _cart.isEmpty || isLoading
                            ? null
                            : _submitOrderRequest,
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _ProductSelectionView extends StatelessWidget {
  const _ProductSelectionView({
    required this.shopName,
    required this.products,
    required this.cart,
    required this.onQuantityChanged,
  });

  final String shopName;
  final List<ShopCatalogProduct> products;
  final Map<String, int> cart;
  final void Function(String productId, int nextQuantity) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const _EmptyState(
        title: 'No products available',
        message: 'The catalog is empty right now. Try again later.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _InfoCard(
          title: 'Create assisted order',
          message:
              'Select products for ${shopName.trim().isEmpty ? 'this outlet' : shopName}. When the order is submitted, the system sends a confirmation PIN to the shop owner before the assisted order is finalized.',
          icon: Icons.storefront_outlined,
          accentColor: AppTheme.primaryBrown,
        ),
        const SizedBox(height: 16),
        ...products.map((product) {
          final quantity = cart[product.id] ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outlineWarm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.displayDescription,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSoft,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Rs. ${product.orderPrice.toStringAsFixed(2)} / case',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryBrown,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _QuantityStepper(
                  quantity: quantity,
                  onDecrease: quantity <= 0
                      ? null
                      : () => onQuantityChanged(product.id, quantity - 1),
                  onIncrease: () => onQuantityChanged(product.id, quantity + 1),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.itemCount,
    required this.totalAmount,
    required this.isLoading,
    required this.onSubmit,
  });

  final int itemCount;
  final double totalAmount;
  final bool isLoading;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.outlineWarm)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Selected items',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$itemCount item(s)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryBrown,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Estimated total: Rs. ${totalAmount.toStringAsFixed(2)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Submit Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove),
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 34,
            child: Center(
              child: Text(
                '$quantity',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.message,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withAlpha(90)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.promotionMutedRed,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
            ),
          ],
        ),
      ),
    );
  }
}
