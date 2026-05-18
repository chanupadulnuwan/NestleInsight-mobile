import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/distributor/data/services/distributor_service.dart';
import 'package:mobile/features/distributor/domain/delivery_assignment.dart';

const _reasons = <(String, String)>[
  ('EXPIRED', 'Expired'),
  ('DAMAGED', 'Damaged'),
  ('OTHER', 'Other reason'),
];

class ShopReturnPage extends StatefulWidget {
  const ShopReturnPage({
    super.key,
    required this.order,
    required this.lorryInventory,
  });

  final AssignmentOrder order;
  final List<OrderItem> lorryInventory;

  @override
  State<ShopReturnPage> createState() => _ShopReturnPageState();
}

class _ShopReturnPageState extends State<ShopReturnPage> {
  final _service = DistributorService();
  final _searchController = TextEditingController();
  final List<ReturnItemInput> _items = [];
  final List<TextEditingController> _pinControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(6, (_) => FocusNode());

  bool _pinSent = false;
  bool _requestingPin = false;
  bool _submitting = false;
  String? _error;
  bool _success = false;

  String get _currentPin => _pinControllers.map((c) => c.text).join();

  List<OrderItem> get _filteredInventory {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return widget.lorryInventory;
    return widget.lorryInventory
        .where((i) => i.productName.toLowerCase().contains(q))
        .toList();
  }

  double get _totalValue => _items.fold(0, (sum, i) => sum + i.totalValue);

  @override
  void dispose() {
    _searchController.dispose();
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final f in _pinFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _addItem(OrderItem product) {
    final existing = _items.where(
      (i) =>
          (i.productId != null && i.productId == product.productId) ||
          i.productNameSnapshot == product.productName,
    );
    if (existing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${product.productName} is already in the list. Adjust the quantity below.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _items.add(
        ReturnItemInput(
          productId: product.productId,
          productNameSnapshot: product.productName,
          quantity: 1,
          unitType: 'CASE',
          reason: 'EXPIRED',
          unitPrice: product.unitPrice,
          itemUnitPrice: product.resolvedItemUnitPrice,
          productsPerCase: product.productsPerCase,
        ),
      );
    });
  }

  Future<void> _requestPin() async {
    if (_items.isEmpty) {
      setState(() {
        _error = 'Add at least one item to return.';
      });
      return;
    }
    setState(() {
      _requestingPin = true;
      _error = null;
    });
    try {
      await _service.requestShopReturnPin(orderId: widget.order.orderId);
      if (mounted) {
        setState(() {
          _pinSent = true;
          _requestingPin = false;
        });
      }
    } on DistributorServiceException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _requestingPin = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final pin = _currentPin;
    if (pin.length != 6) {
      setState(() {
        _error = 'Enter the 6-digit confirmation PIN.';
      });
      return;
    }
    for (final item in _items) {
      if (item.reason == 'OTHER' &&
          (item.reasonNote == null || item.reasonNote!.trim().isEmpty)) {
        setState(() {
          _error = 'Describe the reason for "${item.productNameSnapshot}".';
        });
        return;
      }
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _service.submitShopReturn(
        orderId: widget.order.orderId,
        pin: pin,
        items: _items,
      );
      if (mounted) {
        setState(() {
          _success = true;
          _submitting = false;
        });
      }
    } on DistributorServiceException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceWarm,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBrownDark,
        foregroundColor: Colors.white,
        title: const Text('Shop Return'),
      ),
      body: _success
          ? _SuccessView(onDone: () => Navigator.of(context).pop(true))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop info
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.outlineWarm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.store_outlined,
                          color: AppTheme.primaryBrown,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.order.shopName} · ${widget.order.orderCode}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Product search
                  Text(
                    'Select Products to Return',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Record items the shop owner is giving back from this delivery or older stock. Use Case for sealed cases and Item for loose products.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSoft,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search product on lorry…',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  if (_filteredInventory.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No matching products found on the lorry.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSoft,
                        ),
                      ),
                    )
                  else
                    ...(_filteredInventory.map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _ProductRow(
                          product: product,
                          onAdd: () => _addItem(product),
                        ),
                      ),
                    )),

                  if (_items.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Return List',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._items.asMap().entries.map(
                      (entry) => _ReturnItemCard(
                        index: entry.key,
                        item: entry.value,
                        onRemove: () =>
                            setState(() => _items.removeAt(entry.key)),
                        onChanged: () => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceTint,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.outlineWarm),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Estimated Return Value',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            'LKR ${_totalValue.toStringAsFixed(2)}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryBrownDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(color: AppTheme.outlineWarm),
                  const SizedBox(height: 16),

                  if (!_pinSent) ...[
                    Text(
                      'Confirm with Shop Owner',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'A confirmation PIN will be sent to the shop owner\'s app. They will share it with you to authorise the product pickup.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSoft,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _requestingPin ? null : _requestPin,
                      icon: _requestingPin
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_outlined),
                      label: const Text('Request Confirmation PIN'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryBrown,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FFF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF9FD4B2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF1E7A52),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'PIN sent to shop owner. Ask them to share the 6-digit code.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF1E5C3A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter Confirmation PIN',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        6,
                        (index) => SizedBox(
                          width: 44,
                          height: 54,
                          child: TextField(
                            controller: _pinControllers[index],
                            focusNode: _pinFocusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark,
                                ),
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.outlineWarm,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryBrown,
                                  width: 2,
                                ),
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (v) {
                              if (v.length == 1 && index < 5) {
                                _pinFocusNodes[index + 1].requestFocus();
                              } else if (v.isEmpty && index > 0) {
                                _pinFocusNodes[index - 1].requestFocus();
                              }
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _requestPin,
                        child: const Text('Resend PIN'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(Icons.inventory_2_outlined),
                      label: const Text(
                        'Record Return',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryBrownDark,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0A7A3)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFF9B4B46),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.onAdd});
  final OrderItem product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  '${product.quantity} case(s) on lorry · LKR ${product.unitPrice.toStringAsFixed(2)}/case',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.textSoft),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline),
            color: AppTheme.primaryBrown,
          ),
        ],
      ),
    );
  }
}

class _ReturnItemCard extends StatelessWidget {
  const _ReturnItemCard({
    required this.index,
    required this.item,
    required this.onRemove,
    required this.onChanged,
  });
  final int index;
  final ReturnItemInput item;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.productNameSnapshot,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFF9B4B46),
                ),
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: item.unitType,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'CASE', child: Text('Case')),
                    DropdownMenuItem(value: 'ITEM', child: Text('Item')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      item.unitType = v;
                      onChanged();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) {
                    item.quantity = int.tryParse(v) ?? 1;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: item.reason,
            decoration: const InputDecoration(
              labelText: 'Reason',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: _reasons
                .map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                item.reason = v;
                item.reasonNote = null;
                onChanged();
              }
            },
          ),
          if (item.reason == 'OTHER') ...[
            const SizedBox(height: 8),
            TextFormField(
              initialValue: item.reasonNote,
              decoration: const InputDecoration(
                labelText: 'Describe reason',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (v) {
                item.reasonNote = v;
                onChanged();
              },
            ),
          ],
          if (item.unitPrice != null && item.unitPrice! > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Value: LKR ${item.totalValue.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryBrownDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2, color: AppTheme.primaryBrown, size: 72),
            const SizedBox(height: 16),
            Text(
              'Return Recorded',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Products have been logged as returned. Your territory manager has been notified.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
