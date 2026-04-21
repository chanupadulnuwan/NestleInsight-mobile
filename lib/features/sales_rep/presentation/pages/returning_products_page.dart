import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/product_image_box.dart';
import 'package:mobile/features/home/data/services/product_catalog_service.dart';
import 'package:mobile/features/home/domain/shop_catalog_product.dart';
import '../../data/services/sales_return_service.dart';
import '../cubit/sales_return_cubit.dart';

class ReturningProductsPage extends StatelessWidget {
  final String routeId;

  const ReturningProductsPage({super.key, required this.routeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SalesReturnCubit(),
      child: Scaffold(
        backgroundColor: AppTheme.surfaceWarm,
        appBar: AppBar(title: const Text('Returning Products')),
        body: BlocConsumer<SalesReturnCubit, SalesReturnState>(
          listener: (context, state) {
            if (state is SalesReturnSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.proceedOrderOlive,
                ),
              );
              Navigator.of(context).pop();
            } else if (state is SalesReturnError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.promotionMutedRed,
                ),
              );
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                _ReturningProductsForm(routeId: routeId),
                if (state is SalesReturnSubmitting)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _ReturnQuantityMode { cases, units }

class _ReturnRowData {
  _ReturnRowData(this.product);

  final ShopCatalogProduct product;
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  String reason = 'DAMAGED';
  _ReturnQuantityMode mode = _ReturnQuantityMode.cases;

  void dispose() {
    quantityController.dispose();
    notesController.dispose();
  }
}

class _ReturningProductsForm extends StatefulWidget {
  final String routeId;

  const _ReturningProductsForm({required this.routeId});

  @override
  State<_ReturningProductsForm> createState() => _ReturningProductsFormState();
}

class _ReturningProductsFormState extends State<_ReturningProductsForm> {
  final _formKey = GlobalKey<FormState>();
  final _catalogService = ProductCatalogService();
  final _searchController = TextEditingController();
  final Map<String, _ReturnRowData> _selected = {};

  List<ShopCatalogProduct> _products = const [];
  bool _isLoadingCatalog = true;
  String? _catalogError;

  final List<String> _reasons = [
    'DAMAGED',
    'EXPIRED',
    'CUSTOMER_REFUSED',
    'OVERSTOCK',
    'OTHER',
  ];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final row in _selected.values) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoadingCatalog = true;
      _catalogError = null;
    });

    try {
      final catalog = await _catalogService.fetchCatalog();
      if (!mounted) return;
      setState(() {
        _products = catalog.products
            .where((product) => product.isAvailable)
            .toList();
        _isLoadingCatalog = false;
      });
    } on ProductCatalogServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _catalogError = error.message;
        _isLoadingCatalog = false;
      });
    }
  }

  List<ShopCatalogProduct> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _products.take(40).toList();
    }
    return _products
        .where((product) => product.searchText.contains(query))
        .take(40)
        .toList();
  }

  void _toggleProduct(ShopCatalogProduct product, bool selected) {
    setState(() {
      if (selected) {
        _selected.putIfAbsent(product.id, () => _ReturnRowData(product));
      } else {
        final removed = _selected.remove(product.id);
        removed?.dispose();
      }
    });
  }

  void _submit() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one return product.')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final items = _selected.values.map((row) {
      final quantity = int.parse(row.quantityController.text.trim());
      final isCaseMode = row.mode == _ReturnQuantityMode.cases;
      final notes = row.notesController.text.trim();

      return ReturnItemLog(
        productId: row.product.id,
        productName: row.product.name,
        quantityCases: isCaseMode ? quantity : 0,
        quantityUnits: isCaseMode ? 0 : quantity,
        unitType: isCaseMode ? 'CASE' : 'UNIT',
        reason: row.reason,
        notes: notes.isEmpty ? null : notes,
      );
    }).toList();

    context.read<SalesReturnCubit>().submitReturn(
      routeId: widget.routeId,
      items: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedRows = _selected.values.toList();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Tick the products being returned from this route, then enter the quantity by cases or by individual product units.',
            style: TextStyle(
              color: AppTheme.textSoft,
              fontSize: 15,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Search products',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCatalogList(),
          if (selectedRows.isNotEmpty) ...[
            const SizedBox(height: 22),
            _SectionTitle(
              title: 'Selected Return Items',
              subtitle: '${selectedRows.length} product(s) ready to submit',
            ),
            const SizedBox(height: 12),
            ...selectedRows.map(
              (row) => _ReturnItemEditor(
                row: row,
                reasons: _reasons,
                onChanged: () => setState(() {}),
                onRemove: () => _toggleProduct(row.product, false),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.assignment_turned_in_outlined),
            label: const Text(
              'Submit Returns',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogList() {
    if (_isLoadingCatalog) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_catalogError != null) {
      return _InfoPanel(
        icon: Icons.warning_amber_rounded,
        message: _catalogError!,
        actionLabel: 'Retry',
        onAction: _loadCatalog,
      );
    }

    final products = _filteredProducts;
    if (products.isEmpty) {
      return const _InfoPanel(
        icon: Icons.inventory_2_outlined,
        message: 'No products match your search.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Product List',
          subtitle: 'Tick products to add them to the return list',
        ),
        const SizedBox(height: 10),
        ...products.map(
          (product) => _ProductReturnTile(
            product: product,
            selected: _selected.containsKey(product.id),
            onChanged: (selected) => _toggleProduct(product, selected),
          ),
        ),
      ],
    );
  }
}

class _ProductReturnTile extends StatelessWidget {
  const _ProductReturnTile({
    required this.product,
    required this.selected,
    required this.onChanged,
  });

  final ShopCatalogProduct product;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: selected ? AppTheme.kCream : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppTheme.primaryBrown : AppTheme.outlineWarm,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!selected),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: (value) => onChanged(value ?? false),
              ),
              const SizedBox(width: 6),
              Container(
                width: 54,
                height: 54,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.outlineWarm),
                ),
                child: ProductImageBox(
                  imageSource: product.imageUrl,
                  fallbackLabel: product.badgeLabel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        product.sku,
                        product.packSize,
                      ].where((item) => item.trim().isNotEmpty).join(' - '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReturnItemEditor extends StatelessWidget {
  const _ReturnItemEditor({
    required this.row,
    required this.reasons,
    required this.onChanged,
    required this.onRemove,
  });

  final _ReturnRowData row;
  final List<String> reasons;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final quantityLabel = row.mode == _ReturnQuantityMode.cases
        ? 'Number of cases'
        : 'Number of products';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.outlineWarm),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.remove_circle_outline_rounded,
                    color: AppTheme.promotionMutedRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_ReturnQuantityMode>(
              initialValue: row.mode,
              decoration: const InputDecoration(
                labelText: 'Quantity type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: _ReturnQuantityMode.cases,
                  child: Text('Cases'),
                ),
                DropdownMenuItem(
                  value: _ReturnQuantityMode.units,
                  child: Text('Products'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                row.mode = value;
                onChanged();
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: row.quantityController,
              decoration: InputDecoration(
                labelText: quantityLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                final quantity = int.tryParse(value?.trim() ?? '');
                if (quantity == null || quantity <= 0) {
                  return 'Enter a quantity greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: row.reason,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              items: reasons
                  .map(
                    (reason) =>
                        DropdownMenuItem(value: reason, child: Text(reason)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                row.reason = value;
                onChanged();
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: row.notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryBrown),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
