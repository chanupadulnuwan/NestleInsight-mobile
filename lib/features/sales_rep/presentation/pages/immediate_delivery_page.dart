import 'package:flutter/material.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/product_image_box.dart';
import 'package:mobile/features/home/domain/shop_catalog_product.dart';
import 'package:mobile/features/orders/data/services/order_service.dart';

class ImmediateDeliveryPreviewLine {
  const ImmediateDeliveryPreviewLine({
    required this.product,
    required this.requestedCases,
    required this.availableCases,
  });

  final ShopCatalogProduct product;
  final int requestedCases;
  final int availableCases;

  int get deliveredCases =>
      requestedCases < availableCases ? requestedCases : availableCases;

  int get pendingCases => requestedCases - deliveredCases;
}

class ImmediateDeliveryPage extends StatefulWidget {
  const ImmediateDeliveryPage({
    super.key,
    required this.routeId,
    required this.orderId,
    required this.orderCode,
    required this.shopName,
    required this.lines,
  });

  final String routeId;
  final String orderId;
  final String orderCode;
  final String shopName;
  final List<ImmediateDeliveryPreviewLine> lines;

  @override
  State<ImmediateDeliveryPage> createState() => _ImmediateDeliveryPageState();
}

class _ImmediateDeliveryPageState extends State<ImmediateDeliveryPage> {
  final OrderService _orderService = OrderService();
  final TextEditingController _confirmationController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DateTime? _nextDeliveryDate;
  bool _isSubmitting = false;
  String? _error;

  bool get _isPartial => widget.lines.any((line) => line.pendingCases > 0);

  int get _deliveredCases =>
      widget.lines.fold<int>(0, (sum, line) => sum + line.deliveredCases);

  int get _pendingCases =>
      widget.lines.fold<int>(0, (sum, line) => sum + line.pendingCases);

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _pickNextDeliveryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 45)),
      initialDate: _nextDeliveryDate ?? now.add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _nextDeliveryDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_isPartial && _nextDeliveryDate == null) {
      setState(() {
        _error = 'Select the next delivery date for the pending balance.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final result = await _orderService.completeImmediateSalesRepDelivery(
        orderId: widget.orderId,
        routeId: widget.routeId,
        confirmationNote: _confirmationController.text.trim(),
        nextDeliveryDate: _nextDeliveryDate,
      );
      if (!mounted) return;

      final detail = result.backorderCode == null
          ? result.message
          : '${result.message} Backorder: ${result.backorderCode}.';
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_isPartial ? 'Partial delivery saved' : 'Delivery done'),
          content: Text(detail),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on OrderServiceException catch (error) {
      if (!mounted) return;
      if (error.code == 'DELIVERY_ENDPOINT_UNAVAILABLE') {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Order sent to TM approval'),
            content: Text(error.message),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        );
        if (mounted) {
          Navigator.of(context).pop(true);
        }
        return;
      }

      setState(() {
        _error = error.message;
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopName = widget.shopName.trim().isEmpty
        ? 'Selected shop'
        : widget.shopName.trim();

    return Scaffold(
      backgroundColor: AppTheme.surfaceWarm,
      appBar: AppBar(title: const Text('Delivery Now')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(
                shopName: shopName,
                orderCode: widget.orderCode.isEmpty
                    ? widget.orderId
                    : widget.orderCode,
                isPartial: _isPartial,
                deliveredCases: _deliveredCases,
                pendingCases: _pendingCases,
              ),
              const SizedBox(height: 14),
              ...widget.lines.map((line) => _DeliveryLineTile(line: line)),
              if (_isPartial) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _pickNextDeliveryDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    _nextDeliveryDate == null
                        ? 'Select next delivery date'
                        : 'Next delivery: ${_nextDeliveryDate!.day}/${_nextDeliveryDate!.month}/${_nextDeliveryDate!.year}',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBrown,
                    side: const BorderSide(color: AppTheme.primaryBrown),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmationController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Delivery confirmation',
                  hintText: 'Type the shop confirmation or proof note',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Enter the delivery confirmation.';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppTheme.promotionMutedRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.local_shipping_outlined),
                label: Text(
                  _isPartial
                      ? 'Complete Partial Delivery'
                      : 'Complete Delivery',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.proceedOrderOlive,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.shopName,
    required this.orderCode,
    required this.isPartial,
    required this.deliveredCases,
    required this.pendingCases,
  });

  final String shopName;
  final String orderCode;
  final bool isPartial;
  final int deliveredCases;
  final int pendingCases;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shopName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      (isPartial
                              ? AppTheme.promotionMutedRed
                              : AppTheme.proceedOrderOlive)
                          .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isPartial ? 'Partial' : 'Full',
                  style: TextStyle(
                    color: isPartial
                        ? AppTheme.promotionMutedRed
                        : AppTheme.proceedOrderOlive,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Order $orderCode',
            style: const TextStyle(
              color: AppTheme.textSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  label: 'Deliver now',
                  value: '$deliveredCases cases',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricPill(
                  label: 'Pending',
                  value: '$pendingCases cases',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.kCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSoft, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DeliveryLineTile extends StatelessWidget {
  const _DeliveryLineTile({required this.line});

  final ImmediateDeliveryPreviewLine line;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppTheme.kCream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ProductImageBox(
              imageSource: line.product.imageUrl,
              fallbackLabel: line.product.badgeLabel,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _TinyChip(label: 'Order ${line.requestedCases}'),
                    _TinyChip(label: 'Lorry ${line.availableCases}'),
                    _TinyChip(label: 'Deliver ${line.deliveredCases}'),
                    if (line.pendingCases > 0)
                      _TinyChip(
                        label: 'Pending ${line.pendingCases}',
                        color: AppTheme.promotionMutedRed,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyChip extends StatelessWidget {
  const _TinyChip({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primaryBrown;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
