import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/home/data/services/product_catalog_service.dart';
import 'package:mobile/features/home/domain/shop_catalog_product.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/place_order_cubit.dart';

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
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  List<ShopCatalogProduct> _products = const <ShopCatalogProduct>[];
  bool _isLoadingCatalog = true;
  String? _catalogError;
  String? _assistedOrderRequestId;
  DateTime? _pinExpiresAt;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _reasonController.dispose();
    super.dispose();
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

  void _updateQuantity(String productId, int nextQuantity) {
    setState(() {
      if (nextQuantity <= 0) {
        _cart.remove(productId);
      } else {
        _cart[productId] = nextQuantity.clamp(1, 99);
      }
    });
  }

  void _resetPinStep() {
    context.read<PlaceOrderCubit>().reset();
    setState(() {
      _assistedOrderRequestId = null;
      _pinExpiresAt = null;
      _pinController.clear();
      _reasonController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlaceOrderCubit, PlaceOrderState>(
      listener: (context, state) {
        if (state is PlaceOrderAwaitingPin) {
          setState(() {
            _assistedOrderRequestId = state.assistedOrderRequestId;
            _pinExpiresAt = state.expiresAt;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.proceedOrderOlive,
            ),
          );
        } else if (state is PlaceOrderDraftSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.primaryBrown,
            ),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        } else if (state is PlaceOrderSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.orderCode.isEmpty
                    ? state.message
                    : '${state.message} (${state.orderCode})',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        } else if (state is PlaceOrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.surfaceWarm,
        appBar: AppBar(
          title: const Text('Assisted Order'),
          actions: [
            if (_assistedOrderRequestId != null)
              TextButton(
                onPressed: _resetPinStep,
                child: const Text('Edit Order'),
              ),
          ],
        ),
        body: _isLoadingCatalog
            ? const Center(child: CircularProgressIndicator())
            : _catalogError != null
                ? _ErrorState(message: _catalogError!, onRetry: _loadCatalog)
                : BlocBuilder<PlaceOrderCubit, PlaceOrderState>(
                    builder: (context, state) {
                      final isLoading = state is PlaceOrderLoading;

                      return Column(
                        children: [
                          Expanded(
                            child: _assistedOrderRequestId == null
                                ? _ProductSelectionView(
                                    shopName: widget.shopName,
                                    products: _products,
                                    cart: _cart,
                                    onQuantityChanged: _updateQuantity,
                                  )
                                : _PinConfirmationView(
                                    shopName: widget.shopName,
                                    cart: _cart,
                                    products: _products,
                                    pinController: _pinController,
                                    reasonController: _reasonController,
                                    pinExpiresAt: _pinExpiresAt,
                                    onResendPin: isLoading
                                        ? null
                                        : () {
                                            context
                                                .read<PlaceOrderCubit>()
                                                .requestOrderPin(
                                                  routeId: widget.routeId,
                                                  shopId: widget.shopId,
                                                  cart: _cart,
                                                );
                                          },
                                  ),
                          ),
                          _BottomBar(
                            itemCount: _cartItemCount,
                            totalAmount: _cartTotal,
                            isLoading: isLoading,
                            isAwaitingPin: _assistedOrderRequestId != null,
                            onSubmit: _cart.isEmpty || isLoading
                                ? null
                                : () {
                                    if (_assistedOrderRequestId == null) {
                                      context
                                          .read<PlaceOrderCubit>()
                                          .requestOrderPin(
                                            routeId: widget.routeId,
                                            shopId: widget.shopId,
                                            cart: _cart,
                                          );
                                      return;
                                    }

                                    context
                                        .read<PlaceOrderCubit>()
                                        .confirmOrderPin(
                                          assistedOrderRequestId:
                                              _assistedOrderRequestId!,
                                          pin: _pinController.text,
                                          assistedReason:
                                              _reasonController.text,
                                        );
                                  },
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
      children: [
        _InfoCard(
          title: 'Create assisted order',
          message:
              'Select the case quantities for ${shopName.trim().isEmpty ? 'this outlet' : shopName}. We will send a confirmation PIN to the shop owner activity center before the order is created.',
          icon: Icons.storefront_outlined,
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

class _PinConfirmationView extends StatelessWidget {
  const _PinConfirmationView({
    required this.shopName,
    required this.cart,
    required this.products,
    required this.pinController,
    required this.reasonController,
    required this.pinExpiresAt,
    required this.onResendPin,
  });

  final String shopName;
  final Map<String, int> cart;
  final List<ShopCatalogProduct> products;
  final TextEditingController pinController;
  final TextEditingController reasonController;
  final DateTime? pinExpiresAt;
  final VoidCallback? onResendPin;

  @override
  Widget build(BuildContext context) {
    final productsById = <String, ShopCatalogProduct>{
      for (final product in products) product.id: product,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(
          title: 'Enter confirmation PIN',
          message:
              'The shop owner can now open their activity center, read the 6-digit PIN, and share it with the sales rep to complete the assisted order.',
          icon: Icons.lock_clock_outlined,
          accentColor: AppTheme.securitySlate,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineWarm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shopName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              if (pinExpiresAt != null)
                Text(
                  'PIN expires at ${TimeOfDay.fromDateTime(pinExpiresAt!.toLocal()).format(context)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.securitySlate,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              const SizedBox(height: 16),
              ...cart.entries.map((entry) {
                final product = productsById[entry.key];
                if (product == null) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppTheme.textDark),
                        ),
                      ),
                      Text(
                        '${entry.value} case(s)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primaryBrownDark,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Shop Owner PIN',
            hintText: 'Enter 6-digit PIN',
            counterText: '',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason for assisted order',
            hintText:
                'Briefly explain why the sales rep is placing this order on behalf of the outlet.',
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onResendPin,
            icon: const Icon(Icons.refresh),
            label: const Text('Resend PIN'),
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.itemCount,
    required this.totalAmount,
    required this.isLoading,
    required this.isAwaitingPin,
    required this.onSubmit,
  });

  final int itemCount;
  final double totalAmount;
  final bool isLoading;
  final bool isAwaitingPin;
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSoft,
                ),
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
                  : Text(
                      isAwaitingPin
                          ? 'Confirm Assisted Order'
                          : 'Request Confirmation PIN',
                      style: const TextStyle(
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
        children: [
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
    this.accentColor = AppTheme.proceedOrderOlive,
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
        children: [
          Icon(icon, color: accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSoft,
                      ),
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
          children: [
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
          children: [
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSoft,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
