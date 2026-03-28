import 'package:flutter/material.dart';
import 'package:mobile/core/widgets/product_image_box.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/home/presentation/controllers/shop_owner_dashboard_controller.dart';
import 'package:mobile/features/orders/domain/shop_order.dart';

class CartSideSheet extends StatelessWidget {
  const CartSideSheet({
    super.key,
    required this.controller,
    required this.isTablet,
    required this.onClose,
    required this.onProceedOrder,
    required this.onUsePreviousOrder,
  });

  final ShopOwnerDashboardController controller;
  final bool isTablet;
  final VoidCallback onClose;
  final VoidCallback onProceedOrder;
  final Future<void> Function(ShopOrder order) onUsePreviousOrder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final latestOrder = controller.latestOrder;

        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            child: Container(
              width: isTablet ? 440 : MediaQuery.of(context).size.width * 0.9,
              height: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  bottomLeft: Radius.circular(28),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 22,
                    offset: const Offset(-8, 0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Current cart',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Text(
                    'Review the products before you proceed to the order summary.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSoft,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (latestOrder != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => onUsePreviousOrder(latestOrder),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          'Order the previous order',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primaryBrownDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (latestOrder != null) const SizedBox(height: 18),
                  Expanded(
                    child: controller.cartItems.isEmpty
                        ? _EmptyCartState(isTablet: isTablet)
                        : ListView.separated(
                            itemCount: controller.cartItems.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = controller.cartItems[index];

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceWarm,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: AppTheme.outlineWarm.withAlpha(100),
                                  ),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                      width: 72,
                                      height: 72,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: ProductImageBox(
                                        imageSource: item.product.imageUrl,
                                        fallbackLabel: item.product.badgeLabel,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            item.product.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: AppTheme.textDark,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item.quantity} x ${_formatCurrency(item.product.orderPrice)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: AppTheme.textSoft,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(item.lineTotal),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppTheme.primaryBrownDark,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceTint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Total',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          _formatCurrency(controller.cartTotal),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryBrownDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: controller.cartItems.isEmpty ? null : onProceedOrder,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.proceedOrderOlive,
                      ),
                      child: const Text('Proceed the order'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState({required this.isTablet});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: isTablet ? 82 : 68,
              height: isTablet ? 82 : 68,
              decoration: BoxDecoration(
                color: AppTheme.surfaceTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                color: AppTheme.primaryBrownDark,
                size: isTablet ? 38 : 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Your cart is empty',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add products from the home screen or replace the cart with your previous order.',
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

String _formatCurrency(double value) {
  final normalized = value.toStringAsFixed(2);
  final parts = normalized.split('.');
  final whole = parts.first;
  final decimal = parts.last;
  final buffer = StringBuffer();

  for (var index = 0; index < whole.length; index++) {
    final reverseIndex = whole.length - index;
    buffer.write(whole[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return 'LKR ${buffer.toString()}.$decimal';
}
