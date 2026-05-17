import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/home/domain/shop_catalog_product.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/outlet_visit_cubit.dart';
import 'osa_reason_picker.dart';

export 'osa_reason_picker.dart';

enum OSAStatus { inStock, outOfStock, none }

class OSAProductCard extends StatelessWidget {
  const OSAProductCard({
    super.key,
    required this.product,
    required this.status,
    this.reason,
    required this.onStatusChanged,
    this.stockEntry,
    this.historicalQty = 0,
    this.onStockChanged,
  });

  final ShopCatalogProduct product;
  final OSAStatus status;
  final String? reason;
  final Function(OSAStatus status, String? reason) onStatusChanged;

  /// Shelf + backroom counts (for Stock tab mode)
  final StockEntry? stockEntry;

  /// Expected stock in base units since the outlet's latest completed visit.
  final int historicalQty;

  final Function(int shelfCount, int backroomCount)? onStockChanged;

  bool get _showStockInputs => onStockChanged != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(),
              const SizedBox(width: 12),
              Expanded(child: _buildProductInfo()),
              _buildToggle(context),
            ],
          ),
          if (_showStockInputs && status != OSAStatus.outOfStock) ...[
            const SizedBox(height: 10),
            _buildStockInputRow(),
          ],
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      padding: const EdgeInsets.all(4),
      child: product.imageUrl != null
          ? Image.network(
              product.imageUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.inventory_2_outlined,
                color: AppTheme.textSoft,
              ),
            )
          : const Icon(Icons.inventory_2_outlined, color: AppTheme.textSoft),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: const TextStyle(
            color: AppTheme.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        if (status == OSAStatus.outOfStock && reason != null)
          Text(
            'OOS: $reason',
            style: const TextStyle(
              color: Color(0xFFC88243),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        if (_showStockInputs &&
            historicalQty > 0 &&
            status != OSAStatus.outOfStock) ...[
          const SizedBox(height: 2),
          Text(
            'Expected before count: $historicalQty units',
            style: const TextStyle(color: AppTheme.textSoft, fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _buildToggle(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7E2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            label: '✓',
            isActive: status == OSAStatus.inStock,
            activeColor: const Color(0xFF88977F),
            onTap: () => onStatusChanged(OSAStatus.inStock, null),
          ),
          _buildToggleButton(
            label: '✗',
            isActive: status == OSAStatus.outOfStock,
            activeColor: const Color(0xFFD9B696),
            onTap: () async {
              final result = await showDialog<String>(
                context: context,
                builder: (context) => const OSAReasonPicker(),
              );
              if (result != null) {
                onStatusChanged(OSAStatus.outOfStock, result);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppTheme.textSoft,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildStockInputRow() {
    final entry = stockEntry ?? const StockEntry();
    final estimated = entry.estimatedSales(historicalQty);

    return Row(
      children: [
        const SizedBox(width: 68), // align under product info
        Expanded(
          child: _StockCountField(
            label: 'Shelf',
            initialValue: entry.shelfCount,
            onChanged: (val) => onStockChanged?.call(val, entry.backroomCount),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StockCountField(
            label: 'Backroom',
            initialValue: entry.backroomCount,
            onChanged: (val) => onStockChanged?.call(entry.shelfCount, val),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F0E8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.outlineWarm),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Est. Sales (units)',
                  style: TextStyle(fontSize: 9, color: AppTheme.textSoft),
                ),
                Text(
                  '$estimated',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBrown,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StockCountField extends StatefulWidget {
  const _StockCountField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  final String label;
  final int initialValue;
  final ValueChanged<int> onChanged;

  @override
  State<_StockCountField> createState() => _StockCountFieldState();
}

class _StockCountFieldState extends State<_StockCountField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.initialValue > 0 ? '${widget.initialValue}' : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(fontSize: 10, color: AppTheme.textSoft),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.outlineWarm),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.outlineWarm),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppTheme.primaryBrown,
            width: 1.5,
          ),
        ),
      ),
      onChanged: (v) => widget.onChanged(int.tryParse(v) ?? 0),
    );
  }
}
