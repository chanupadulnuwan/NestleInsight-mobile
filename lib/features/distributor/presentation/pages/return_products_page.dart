import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/distributor/data/services/distributor_service.dart';
import 'package:mobile/features/distributor/domain/delivery_assignment.dart';
import 'package:mobile/features/home/data/services/product_catalog_service.dart';
import 'package:mobile/features/home/domain/shop_catalog_product.dart';

const _returnReasons = <(String, String)>[
  ('EXPIRED', 'Expired'),
  ('DAMAGED', 'Damaged'),
  ('OTHER', 'Other'),
];

class ReturnProductsPage extends StatefulWidget {
  const ReturnProductsPage({
    super.key,
    required this.assignment,
    this.initialOrderId,
  });

  final DeliveryAssignment assignment;
  final String? initialOrderId;

  @override
  State<ReturnProductsPage> createState() => _ReturnProductsPageState();
}

class _ReturnProductsPageState extends State<ReturnProductsPage> {
  final _service = DistributorService();
  final _catalogService = ProductCatalogService();
  final List<ReturnItemInput> _items = [];
  final List<TextEditingController> _pinControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(6, (_) => FocusNode());

  bool _catalogLoading = true;
  bool _requestingPin = false;
  bool _pinSent = false;
  bool _submitting = false;
  bool _success = false;
  String? _error;
  String? _catalogError;
  String? _selectedOrderId;
  String? _selectedProductId;
  List<_CatalogChoice> _productChoices = const <_CatalogChoice>[];

  List<AssignmentOrder> get _assignedOrders {
    final orders = widget.assignment.orders
        .where((order) => order.orderId.trim().isNotEmpty)
        .toList();
    orders.sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    return orders;
  }

  AssignmentOrder? get _selectedOrder {
    final orderId = _selectedOrderId;
    if (orderId == null) {
      return null;
    }
    for (final order in _assignedOrders) {
      if (order.orderId == orderId) {
        return order;
      }
    }
    return null;
  }

  _CatalogChoice? get _selectedProduct {
    final productId = _selectedProductId;
    if (productId == null) {
      return null;
    }
    for (final product in _productChoices) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }

  String get _currentPin =>
      _pinControllers.map((controller) => controller.text).join();

  double get _totalReturnValue =>
      _items.fold(0, (sum, item) => sum + item.totalValue);

  @override
  void initState() {
    super.initState();
    final orders = _assignedOrders;
    if (orders.isNotEmpty) {
      final initialOrderId = widget.initialOrderId;
      final hasInitial =
          initialOrderId != null &&
          orders.any((order) => order.orderId == initialOrderId);
      _selectedOrderId = hasInitial ? initialOrderId : orders.first.orderId;
    }
    _loadCatalog();
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

  Future<void> _loadCatalog() async {
    final fallbackChoices =
        widget.assignment.lorryInventory
            .map(_CatalogChoice.fromOrderItem)
            .toList()
          ..sort((left, right) => left.name.compareTo(right.name));

    try {
      final result = await _catalogService.fetchCatalog();
      final products =
          result.products
              .where((product) => product.name.trim().isNotEmpty)
              .map(_CatalogChoice.fromCatalog)
              .toList()
            ..sort((left, right) => left.name.compareTo(right.name));

      if (!mounted) {
        return;
      }

      setState(() {
        _productChoices = products;
        _catalogLoading = false;
        _catalogError = null;
        if (_selectedProductId == null && products.isNotEmpty) {
          _selectedProductId = products.first.id;
        }
      });
    } on ProductCatalogServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _productChoices = fallbackChoices;
        _catalogLoading = false;
        _catalogError = error.message;
        if (_selectedProductId == null && fallbackChoices.isNotEmpty) {
          _selectedProductId = fallbackChoices.first.id;
        }
      });
    }
  }

  void _resetPinState() {
    _pinSent = false;
    for (final controller in _pinControllers) {
      controller.clear();
    }
  }

  void _onOrderChanged(String? value) {
    setState(() {
      _selectedOrderId = value;
      _error = null;
      _resetPinState();
    });
  }

  void _onProductChanged(String? value) {
    setState(() {
      _selectedProductId = value;
      _error = null;
    });
  }

  void _addSelectedProduct() {
    final product = _selectedProduct;
    if (product == null) {
      setState(() {
        _error = 'Select a product first.';
      });
      return;
    }

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
    if (_selectedOrder == null) {
      setState(() {
        _error = 'Select the shop first.';
      });
      return;
    }
    if (_items.isEmpty) {
      setState(() {
        _error = 'Add at least one product to the return list.';
      });
      return;
    }

    setState(() {
      _requestingPin = true;
      _error = null;
    });

    try {
      await _service.requestShopReturnPin(orderId: _selectedOrder!.orderId);
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
    final selectedOrder = _selectedOrder;
    if (selectedOrder == null) {
      setState(() {
        _error = 'Select the shop first.';
      });
      return;
    }
    if (_items.isEmpty) {
      setState(() {
        _error = 'Add at least one product to the return list.';
      });
      return;
    }

    final pin = _currentPin;
    if (pin.length != 6) {
      setState(() {
        _error = 'Enter the 6-digit confirmation PIN from the shop owner.';
      });
      return;
    }

    for (final item in _items) {
      if (item.reason == 'OTHER' &&
          (item.reasonNote == null || item.reasonNote!.trim().isEmpty)) {
        setState(() {
          _error =
              'Explain the "Other" reason for ${item.productNameSnapshot}.';
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
        orderId: selectedOrder.orderId,
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
                  Text(
                    'Return Products',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose the shop first, then choose products from the full system catalog and add them to the return list below.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSoft,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedOrderId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Assigned shop',
                      prefixIcon: Icon(Icons.store_outlined),
                    ),
                    items: _assignedOrders
                        .map(
                          (order) => DropdownMenuItem<String>(
                            value: order.orderId,
                            child: Text(
                              '${order.shopName} - ${order.orderCode}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    selectedItemBuilder: (context) => _assignedOrders
                        .map(
                          (order) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${order.shopName} - ${order.orderCode}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _onOrderChanged,
                  ),
                  const SizedBox(height: 12),
                  if (_catalogLoading)
                    const _LoadingCard(message: 'Loading all products...')
                  else if (_productChoices.isEmpty)
                    _LoadingCard(
                      message:
                          _catalogError ??
                          'No active products are available in the system right now.',
                    )
                  else ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProductId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Product',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      items: _productChoices
                          .map(
                            (product) => DropdownMenuItem<String>(
                              value: product.id,
                              child: Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      selectedItemBuilder: (context) => _productChoices
                          .map(
                            (product) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _onProductChanged,
                    ),
                    if (_catalogError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Catalog note: $_catalogError',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSoft,
                        ),
                      ),
                    ],
                    if (_selectedProduct != null) ...[
                      const SizedBox(height: 12),
                      _ProductSummaryCard(product: _selectedProduct!),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _addSelectedProduct,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add product'),
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
                  if (_items.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Selected Products',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._items.asMap().entries.map(
                      (entry) => _ReturnItemCard(
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
                            '-LKR ${_totalReturnValue.toStringAsFixed(2)}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.rejectOrderRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Once this return is confirmed, the amount above is deducted from the end-route handover amount automatically.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSoft,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(color: AppTheme.outlineWarm),
                  const SizedBox(height: 16),
                  Text(
                    'Shop Owner Return Money Confirm',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _pinSent
                        ? 'The shop owner should now see the PIN in their Activity Center. Enter it below to complete the return.'
                        : 'Request the PIN from the selected shop owner. They will receive it in their Activity Center.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSoft,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (!_pinSent)
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
                    )
                  else ...[
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
                          : const Icon(Icons.check_circle_outline),
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

class _CatalogChoice {
  const _CatalogChoice({
    required this.id,
    required this.productId,
    required this.name,
    required this.packSize,
    required this.productsPerCase,
    required this.casePrice,
    required this.unitPrice,
  });

  factory _CatalogChoice.fromCatalog(ShopCatalogProduct product) {
    final productsPerCase = product.productsPerCase > 0
        ? product.productsPerCase
        : 1;
    final casePrice = product.casePrice > 0
        ? product.casePrice
        : product.unitPrice * productsPerCase;
    final unitPrice = product.unitPrice > 0
        ? product.unitPrice
        : (productsPerCase > 0 ? casePrice / productsPerCase : casePrice);

    return _CatalogChoice(
      id: product.id,
      productId: product.id,
      name: product.name,
      packSize: product.packSize,
      productsPerCase: productsPerCase,
      casePrice: casePrice,
      unitPrice: unitPrice,
    );
  }

  factory _CatalogChoice.fromOrderItem(OrderItem item) {
    final productsPerCase = item.productsPerCase > 0 ? item.productsPerCase : 1;
    return _CatalogChoice(
      id: item.productId ?? item.productName,
      productId: item.productId,
      name: item.productName,
      packSize: item.packSize ?? '',
      productsPerCase: productsPerCase,
      casePrice: item.unitPrice,
      unitPrice: item.resolvedItemUnitPrice,
    );
  }

  final String id;
  final String? productId;
  final String name;
  final String packSize;
  final int productsPerCase;
  final double casePrice;
  final double unitPrice;
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.message});

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
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AppTheme.primaryBrown,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textSoft),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSummaryCard extends StatelessWidget {
  const _ProductSummaryCard({required this.product});

  final _CatalogChoice product;

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
            product.packSize.isEmpty
                ? 'Pack size not available'
                : product.packSize,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSoft),
          ),
          const SizedBox(height: 2),
          Text(
            '${product.productsPerCase} unit(s) per case',
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
                    DropdownMenuItem(value: 'CASE', child: Text('Case')),
                    DropdownMenuItem(
                      value: 'ITEM',
                      child: Text('Individual unit'),
                    ),
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
                    labelText: 'Return count',
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
            items: _returnReasons
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
            '-LKR ${item.totalValue.toStringAsFixed(2)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.rejectOrderRed,
              fontWeight: FontWeight.w800,
            ),
          ),
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
              'The shop-owner return was confirmed successfully. This value is now deducted from the route handover amount.',
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
