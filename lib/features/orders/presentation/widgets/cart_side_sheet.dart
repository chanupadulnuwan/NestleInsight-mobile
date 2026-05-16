import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/widgets/product_image_box.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/home/presentation/controllers/shop_owner_dashboard_controller.dart';
import 'package:mobile/features/orders/domain/shop_order.dart';
import 'package:mobile/features/orders/domain/shop_cart_item.dart';
import 'package:mobile/features/promotions/presentation/cubit/promotion_cubit.dart';
import 'package:mobile/features/promotions/presentation/cubit/promotion_state.dart';
import 'package:mobile/features/promotions/domain/promotion.dart';

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
                        : CustomScrollView(
                            slivers: [
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final item = controller.cartItems[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _CartItemRow(item: item, controller: controller),
                                    );
                                  },
                                  childCount: controller.cartItems.length,
                                ),
                              ),
                              const SliverToBoxAdapter(child: SizedBox(height: 24)),
                              const SliverToBoxAdapter(
                                child: Text(
                                  'Available Promotions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                              const SliverToBoxAdapter(child: SizedBox(height: 12)),
                              _PromotionsList(controller: controller),
                              const SliverToBoxAdapter(child: SizedBox(height: 40)),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  _PaymentMethodPanel(controller: controller),
                  const SizedBox(height: 16),
                  _PriceSummaryPanel(controller: controller, onProceed: onProceedOrder),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({required this.item, required this.controller});

  final ShopCartItem item;
  final ShopOwnerDashboardController controller;

  @override
  Widget build(BuildContext context) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(item.product.orderPrice),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSoft,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatCurrency(item.lineTotal),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryBrownDark,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      item.quantity == 1 ? Icons.delete_outline : Icons.remove_circle_outline,
                      color: item.quantity == 1 ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => controller.updateCartQuantity(item.product.id, item.quantity - 1),
                  ),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.kBrown),
                    onPressed: () => controller.updateCartQuantity(item.product.id, item.quantity + 1),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromotionsList extends StatelessWidget {
  const _PromotionsList({required this.controller});

  final ShopOwnerDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PromotionCubit, PromotionState>(
      builder: (context, state) {
        if (state is PromotionLoading) {
          return const SliverToBoxAdapter(
            child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
          );
        }

        if (state is PromotionLoaded) {
          if (state.promotions.isEmpty) {
            return const SliverToBoxAdapter(
              child: _NoPromosInfo(),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final promo = state.promotions[index];
                final isApplied = controller.appliedPromotion?.id == promo.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PromotionSelectableCard(
                    promotion: promo,
                    isApplied: isApplied,
                    onTap: () {
                      if (isApplied) {
                        controller.clearPromotion();
                      } else {
                        // In real dashboard, territoryId is available in state or passed.
                        // For now using empty string as fallback if we don't have access to context territory.
                        // But normally dashboard has it.
                        // I'll use a hack or just assume the controller has it if updated.
                        // Let's assume we can get it or use the one from cubit state.
                        controller.applyPromotion(promo, state.territoryId);
                      }
                    },
                  ),
                );
              },
              childCount: state.promotions.length,
            ),
          );
        }

        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }
}

class _PromotionSelectableCard extends StatelessWidget {
  const _PromotionSelectableCard({
    required this.promotion,
    required this.isApplied,
    required this.onTap,
  });

  final Promotion promotion;
  final bool isApplied;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isApplied ? const Color(0xFFF1F9F4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isApplied ? const Color(0xFF27AE60) : AppTheme.outlineWarm.withAlpha(100),
            width: isApplied ? 2 : 1,
          ),
          boxShadow: [
            if (isApplied)
              BoxShadow(
                color: const Color(0xFF27AE60).withAlpha(30),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isApplied ? const Color(0xFF27AE60) : AppTheme.surfaceWarm,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isApplied ? Icons.check : Icons.local_offer_outlined,
                size: 18,
                color: isApplied ? Colors.white : AppTheme.primaryBrownDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promotion.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isApplied ? const Color(0xFF1E8449) : AppTheme.textDark,
                    ),
                  ),
                  Text(
                    promotion.offerSummary,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isApplied ? const Color(0xFF27AE60) : AppTheme.textSoft,
                    ),
                  ),
                ],
              ),
            ),
            if (isApplied)
              const Text(
                'Applied',
                style: TextStyle(
                  color: Color(0xFF27AE60),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoPromosInfo extends StatelessWidget {
  const _NoPromosInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'No active promotions available for your territory at the moment.',
        style: TextStyle(fontSize: 13, color: AppTheme.textSoft),
      ),
    );
  }
}

class _PriceSummaryPanel extends StatelessWidget {
  const _PriceSummaryPanel({required this.controller, required this.onProceed});

  final ShopOwnerDashboardController controller;
  final VoidCallback onProceed;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = controller.promoDiscount > 0;

    return Column(
      children: [
        if (controller.promoError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.promoError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWarm,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.outlineWarm.withAlpha(100)),
          ),
          child: Column(
            children: [
              _PriceRow(label: 'Subtotal', value: controller.cartSubtotal),
              if (hasDiscount) ...[
                const SizedBox(height: 8),
                _PriceRow(
                  label: 'Promo Discount',
                  value: -controller.promoDiscount,
                  valueColor: Colors.red,
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Grand Total',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                    ),
                  ),
                  Text(
                    _formatCurrency(controller.cartTotal),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryBrownDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: controller.cartItems.isEmpty ? null : onProceed,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.proceedOrderOlive,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: controller.isPlacingOrder
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Proceed to Checkout', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodPanel extends StatelessWidget {
  const _PaymentMethodPanel({required this.controller});

  final ShopOwnerDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(100)),
      ),
      child: CheckboxListTile(
        value: controller.cashOnDeliveryEnabled,
        onChanged: controller.cartItems.isEmpty
            ? null
            : (value) => controller.setCashOnDeliveryEnabled(value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
        activeColor: AppTheme.proceedOrderOlive,
        title: const Text(
          'Cash on delivery',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: const Text(
          'Mark this order so the shop pays when the distributor delivers it.',
          style: TextStyle(
            color: AppTheme.textSoft,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value, this.valueColor});

  final String label;
  final double value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSoft),
          ),
        ),
        Text(
          _formatCurrency(value),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState({required this.isTablet});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: isTablet ? 82 : 68,
            height: isTablet ? 82 : 68,
            decoration: const BoxDecoration(color: AppTheme.surfaceTint, shape: BoxShape.circle),
            child: Icon(Icons.shopping_cart_outlined, color: AppTheme.primaryBrownDark, size: isTablet ? 38 : 32),
          ),
          const SizedBox(height: 14),
          const Text('Your cart is empty', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

String _formatCurrency(double value) {
  final normalized = value.abs().toStringAsFixed(2);
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

  final prefix = value < 0 ? '-' : '';
  return '$prefix LKR ${buffer.toString()}.$decimal';
}

