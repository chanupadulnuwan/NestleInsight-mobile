import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/product_image_box.dart';
import 'package:mobile/features/orders/domain/shop_cart_item.dart';

class OrderSummarySheet extends StatelessWidget {
  const OrderSummarySheet({
    super.key,
    required this.items,
    required this.isTablet,
    required this.isSubmitting,
    required this.onConfirm,
  });

  final List<ShopCartItem> items;
  final bool isTablet;
  final bool isSubmitting;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(
      0,
      (sum, item) => sum + item.lineTotal,
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          top: 12,
          right: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 56,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.outlineWarm,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Order summary',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Review all selected products before placing the order.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSoft,
                  ),
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.42,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWarm,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.outlineWarm.withAlpha(110),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: isTablet ? 76 : 64,
                                height: isTablet ? 76 : 64,
                                color: Colors.white,
                                padding: const EdgeInsets.all(8),
                                child: ProductImageBox(
                                  imageSource: item.product.imageUrl,
                                  fallbackLabel: item.product.badgeLabel,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    '${_formatCurrency(item.product.orderPrice)} x ${item.quantity}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppTheme.textSoft),
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
                const SizedBox(height: 18),
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
                        _formatCurrency(total),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.primaryBrownDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: isSubmitting ? null : onConfirm,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.proceedOrderOlive,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.1,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Place order'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
