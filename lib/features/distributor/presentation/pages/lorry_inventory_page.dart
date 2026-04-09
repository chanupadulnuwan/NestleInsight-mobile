import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/distributor/domain/delivery_assignment.dart';

class LorryInventoryPage extends StatefulWidget {
  const LorryInventoryPage({
    super.key,
    required this.assignment,
  });

  final DeliveryAssignment assignment;

  @override
  State<LorryInventoryPage> createState() => _LorryInventoryPageState();
}

class _LorryInventoryPageState extends State<LorryInventoryPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OrderItem> get _filteredInventory {
    final q = _searchController.text.trim().toLowerCase();
    final all = widget.assignment.lorryInventory;
    if (q.isEmpty) return all;
    return all.where((i) => i.productName.toLowerCase().contains(q)).toList();
  }

  double get _totalValue => widget.assignment.lorryInventory.fold(0, (sum, i) => sum + i.lineTotal);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inventory = _filteredInventory;

    return Scaffold(
      backgroundColor: AppTheme.surfaceWarm,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBrownDark,
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Lorry Inventory'),
          Text(widget.assignment.vehicleLabel ?? 'Vehicle',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ]),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceTint,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.outlineWarm),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${widget.assignment.lorryInventory.fold<int>(0, (s, i) => s + i.quantity)} cases',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.textDark),
                      ),
                      Text('Total on lorry', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSoft)),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('LKR ${_totalValue.toStringAsFixed(0)}',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.primaryBrown),
                      ),
                      Text('Est. value', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSoft)),
                    ]),
                  ]),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search product…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: inventory.isEmpty
                ? Center(
                    child: Text(
                      widget.assignment.lorryInventory.isEmpty
                          ? 'All deliveries complete! No products remaining on lorry.'
                          : 'No products match your search.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: inventory.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = inventory[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.outlineWarm),
                        ),
                        child: Row(children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceTint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryBrown, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.productName,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textDark),
                            ),
                            Text('LKR ${item.unitPrice.toStringAsFixed(2)} / case',
                              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSoft),
                            ),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('${item.quantity}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.primaryBrownDark)),
                            Text('cases', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSoft)),
                          ]),
                        ]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
