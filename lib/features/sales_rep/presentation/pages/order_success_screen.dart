import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.orderCode,
    required this.shopName,
    required this.assistedReason,
    required this.totalAmount,
  });

  final String orderId;
  final String orderCode;
  final String shopName;
  final String assistedReason;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    final displayShopName = shopName.trim().isEmpty ? 'Selected shop' : shopName;

    return Scaffold(
      backgroundColor: AppTheme.surfaceWarm,
      appBar: AppBar(title: const Text('Order Created')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.outlineWarm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.proceedOrderOlive,
                      size: 42,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Assisted order confirmed',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The order has been created and routed with the sales rep as the assisted-order source.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSoft,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _DetailCard(
                label: 'Shop',
                value: displayShopName,
              ),
              const SizedBox(height: 12),
              _DetailCard(
                label: 'Order code',
                value: orderCode.isEmpty ? orderId : orderCode,
              ),
              const SizedBox(height: 12),
              _DetailCard(
                label: 'Estimated total',
                value: 'Rs. ${totalAmount.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 12),
              _DetailCard(
                label: 'Assisted reason',
                value: assistedReason,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrown,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSoft,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
