import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/distributor/data/services/distributor_service.dart';
import 'package:mobile/features/distributor/domain/delivery_assignment.dart';
import 'package:mobile/features/home/data/services/product_catalog_service.dart';
import 'package:mobile/features/home/domain/shop_catalog_product.dart';

const _reasons = <(String, String)>[
  ('EXPIRED', 'Expired'),
  ('DAMAGED', 'Damaged'),
  ('OTHER', 'Other'),
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
  final _catalogService = ProductCatalogService();
  final List<ReturnItemInput> _items = [];
  final List<TextEditingController> _pinControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(6, (_) => FocusNode());

  bool _pinSent = false;
  bool _requestingPin = false;
  bool _submitting = false;
  bool _success = false;
  bool _catalogLoading = true;
  String? _error;
  String? _catalogError;
  String? _selectedProductKey;
  List<_SelectableReturnProduct> _availableProducts =
      const <_SelectableReturnProduct>[];

  String get _currentPin => _pinControllers.map((controller) => controller.text).join();

  _SelectableReturnProduct? get _selectedProduct {
    final key = _selectedProductKey;
    if (key == null) {
      return null;
    }
    for (final product in _availableProducts) {
      if (_productKey(product) == key) {
        return product;
      }
    }
    return null;
  }

  double get _totalValue => _items.fold(0, (sum, item) => sum + item.totalValue);

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    for (final controller in _pinControllers) {
      controller.dispose();
    }
    for (final focusNode in _pinFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _productKey(_SelectableReturnProduct product) => product.id;

  Future<void> _loadProducts() async {
    final lorryByProductId = <String, OrderItem>{
      for (final item in widget.lorryInventory)
        if ((item.productId ?? '').trim().isNotEmpty) item.productId!: item,
    };
    final lorryByName = <String, OrderItem>{
      for (final item in widget.lorryInventory) item.productName: item,
    };

    try {
      final result = await _catalogService.fetchCatalog();
      final options = result.products
          .where((product) => product.name.trim().isNotEmpty)
          .map(
            (product) => _SelectableReturnProduct.fromCatalog(
              product,
              lorryByProductId[product.id] ?? lorryByName[product.name],
            ),
          )
          .toList()
        ..sort((left, right) => left.name.compareTo(right.name));

      if (!mounted) {
        return;
      }

      setState(() {
        _availableProducts = options;
        _catalogLoading = false;
        _catalogError = null;
        if (_selectedProductKey == null && options.isNotEmpty) {
          _selectedProductKey = _productKey(options.first);
        }
      });
    } on ProductCatalogServiceException catch (error) {
      final fallback = widget.lorryInventory
          .map(_SelectableReturnProduct.fromOrderItem)
          .toList()
        ..sort((left, right) => left.name.compareTo(right.name));

      if (!mounted) {
        return;
      }

      setState(() {
        _availableProducts = fallback;
        _catalogLoading = false;
        _catalogError = error.message;
        if (_selectedProductKey == null && fallback.isNotEmpty) {
          _selectedProductKey = _productKey(fallback.first);
        }
      });
    }
  }

  void _addSelectedProduct() {
    final product = _selectedProduct;
    if (product == null) {
      setState(() {
        _error = 'Select a product first.';
      });
      return;
    }
    _addItem(product);
  }

  void _addItem(_SelectableReturnProduct product) {
    final exists = _items.any(
      (item) =>
          (item.productId != null && item.productId == product.productId) ||
          item.productNameSnapshot == product.name,
    );
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${product.name} is already in the return list. Adjust the count below.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _items.add(
        ReturnItemInput(
          productId: product.productId,
          productNameSnapshot: product.name,
          quantity: 1,
          unitType: 'CASE',
          reason: 'EXPIRED',
          unitPrice: product.casePrice,
          itemUnitPrice: product.unitPrice,
          productsPerCase: product.productsPerCase,
        ),
      );
      _error = null;
    });
  }

  Future<void> _requestPin() async {
    if (_items.isEmpty) {
      setState(() {
        _error = 'Add at least one return product first.';
      });
      return;
    }

    setState(() {
      _requestingPin = true;
      _error = null;
    });

    try {
      await _service.requestShopReturnPin(orderId: widget.order.orderId);
      if (!mounted) {
        return;
      }
      setState(() {
        _pinSent = true;
        _requestingPin = false;
      });
    } on DistributorServiceException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _requestingPin = false;
      });
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
          _error = 'Explain the "Other" reason for ${item.productNameSnapshot}.';
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
      if (!mounted) {
        return;
      }
      setState(() {
        _success = true;
        _submitting = false;
      });
    } on DistributorServiceException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _submitting = false;
      });
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
        title: const Text('Return Products'),
      ),
      body: _success
          ? _SuccessView(onDone: () => Navigator.of(context).pop(true))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Return Products',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose a product from the dropdown, add it to the list, then record the returned amount by cases or units with the reason.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSoft,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_catalogLoading)
                    const _MessageCard(message: 'Loading product list...')
                  else if (_availableProducts.isEmpty)
                    const _MessageCard(
                      message: 'No products are available for returns right now.',
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.outlineWarm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _selectedProductKey,
                            decoration: const InputDecoration(
                              labelText: 'Product',
                              prefixIcon: Icon(Icons.inventory_2_outlined),
                            ),
                            items: _availableProducts
                                .map(
                                  (product) => DropdownMenuItem<String>(
                                    value: _productKey(product),
                                    child: Text(product.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedProductKey = value;
                              });
                            },
                          ),
                          if (_selectedProduct != null) ...[
                            const SizedBox(height: 12),
                            _ProductSummaryCard(product: _selectedProduct!),
                            if (_catalogError != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Catalog note: $_catalogError',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSoft,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _addSelectedProduct,
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Add product to return list'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primaryBrown,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (_items.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Return List',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._items.asMap().entries.map(
                      (entry) => _ReturnItemCard(
                        item: entry.value,
                        onRemove: () => setState(() => _items.removeAt(entry.key)),
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
                        color: const Color(0xFFFFF3F1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE6B9B3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total return amount',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            '-LKR ${_totalValue.toStringAsFixed(2)}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.rejectOrderRed,
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
                      'Shop Owner Return Money Confirm',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'When you press the button below, the shop owner receives a confirmation PIN in their Activity Center. Enter that PIN here to complete the return.',
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
                      label: const Text('Shop Owner Return Money Confirm'),
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
                              'PIN sent to the shop owner. Ask them to read the 6-digit code from their Activity Center.',
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
                        fontWeight: FontWeight.w800,
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
                            style: theme.textTheme.headlineMedium?.copyWith(
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
                            onChanged: (value) {
                              if (value.length == 1 && index < 5) {
                                _pinFocusNodes[index + 1].requestFocus();
                              } else if (value.isEmpty && index > 0) {
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
                        'Complete Return',
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

class _SelectableReturnProduct {
  const _SelectableReturnProduct({
    required this.id,
    required this.productId,
    required this.name,
    required this.packSize,
    required this.productsPerCase,
    required this.casePrice,
    required this.unitPrice,
    required this.lorryCases,
  });

  factory _SelectableReturnProduct.fromCatalog(
    ShopCatalogProduct product,
    OrderItem? lorryMatch,
  ) {
    return _SelectableReturnProduct(
      id: product.id,
      productId: product.id,
      name: product.name,
      packSize: product.packSize,
      productsPerCase: product.productsPerCase > 0 ? product.productsPerCase : 1,
      casePrice: product.casePrice,
      unitPrice: product.unitPrice > 0
          ? product.unitPrice
          : (product.productsPerCase > 0
              ? product.casePrice / product.productsPerCase
              : product.casePrice),
      lorryCases: lorryMatch?.quantity ?? 0,
    );
  }

  factory _SelectableReturnProduct.fromOrderItem(OrderItem item) {
    return _SelectableReturnProduct(
      id: item.productId ?? item.productName,
      productId: item.productId,
      name: item.productName,
      packSize: item.packSize ?? '',
      productsPerCase: item.productsPerCase > 0 ? item.productsPerCase : 1,
      casePrice: item.unitPrice,
      unitPrice: item.resolvedItemUnitPrice,
      lorryCases: item.quantity,
    );
  }

  final String id;
  final String? productId;
  final String name;
  final String packSize;
  final int productsPerCase;
  final double casePrice;
  final double unitPrice;
  final int lorryCases;
}

class _ProductSummaryCard extends StatelessWidget {
  const _ProductSummaryCard({required this.product});

  final _SelectableReturnProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product.packSize.isEmpty ? 'Pack size not available' : product.packSize,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSoft),
          ),
          const SizedBox(height: 2),
          Text(
            'Cases on lorry: ${product.lorryCases} · ${product.productsPerCase} units per case',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSoft),
          ),
          const SizedBox(height: 2),
          Text(
            'Case price: LKR ${product.casePrice.toStringAsFixed(2)} · Unit price: LKR ${product.unitPrice.toStringAsFixed(2)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSoft),
          ),
        ],
      ),
    );
  }
}

class _ReturnItemCard extends StatelessWidget {
  const _ReturnItemCard({
    required this.item,
    required this.onRemove,
    required this.onChanged,
  });

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
                onPressed: onRemove,
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFF9B4B46),
                ),
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
                    labelText: 'Count by',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'CASE', child: Text('Cases')),
                    DropdownMenuItem(value: 'ITEM', child: Text('Units')),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    item.unitType = value;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Count',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    item.quantity = int.tryParse(value) ?? 1;
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
                .map(
                  (reason) => DropdownMenuItem<String>(
                    value: reason.$1,
                    child: Text(reason.$2),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              item.reason = value;
              item.reasonNote = null;
              onChanged();
            },
          ),
          if (item.reason == 'OTHER') ...[
            const SizedBox(height: 8),
            TextFormField(
              initialValue: item.reasonNote,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Explain reason',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (value) {
                item.reasonNote = value;
                onChanged();
              },
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Amount: -LKR ${item.totalValue.toStringAsFixed(2)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.rejectOrderRed,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppTheme.textSoft),
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
              'The return has been confirmed with the shop owner and recorded successfully.',
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
