import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/distributor/data/services/distributor_service.dart';
import 'package:mobile/features/distributor/domain/delivery_assignment.dart';

class WarehouseReturnPage extends StatefulWidget {
  const WarehouseReturnPage({
    super.key,
    required this.assignmentId,
    required this.lorryInventory,
  });

  final String assignmentId;
  final List<OrderItem> lorryInventory;

  @override
  State<WarehouseReturnPage> createState() => _WarehouseReturnPageState();
}

class _WarehouseReturnPageState extends State<WarehouseReturnPage> {
  final _service = DistributorService();
  final _searchController = TextEditingController();
  final List<ReturnItemInput> _items = [];
  final List<TextEditingController> _pinControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(6, (_) => FocusNode());

  bool _pinRequested = false;
  bool _requestingPin = false;
  bool _submitting = false;
  String? _error;
  bool _success = false;

  String get _currentPin => _pinControllers.map((c) => c.text).join();

  List<OrderItem> get _filteredInventory {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return widget.lorryInventory;
    return widget.lorryInventory.where((i) => i.productName.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final c in _pinControllers) { c.dispose(); }
    for (final f in _pinFocusNodes) { f.dispose(); }
    super.dispose();
  }

  void _addItem(OrderItem product) {
    final alreadyAdded = _items.any((i) => (i.productId != null && i.productId == product.productId) || i.productNameSnapshot == product.productName);
    if (alreadyAdded) return;
    setState(() {
      _items.add(ReturnItemInput(
        productId: product.productId,
        productNameSnapshot: product.productName,
        quantity: product.quantity,
        unitType: 'CASE',
        reason: 'EXPIRED',
        unitPrice: product.unitPrice,
      ));
    });
  }

  Future<void> _requestPin() async {
    setState(() { _requestingPin = true; _error = null; });
    try {
      await _service.requestWarehouseReturnPin(assignmentId: widget.assignmentId);
      if (mounted) setState(() { _pinRequested = true; _requestingPin = false; });
    } on DistributorServiceException catch (e) {
      if (mounted) setState(() { _error = e.message; _requestingPin = false; });
    }
  }

  Future<void> _submit() async {
    if (_items.isEmpty) {
      setState(() { _error = 'Add at least one item to return.'; });
      return;
    }
    final pin = _currentPin;
    if (pin.length != 6) {
      setState(() { _error = 'Enter the 6-digit PIN from your Territory Manager.'; });
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      await _service.submitReturn(assignmentId: widget.assignmentId, tmPin: pin, items: _items);
      if (mounted) setState(() { _success = true; _submitting = false; });
    } on DistributorServiceException catch (e) {
      if (mounted) setState(() { _error = e.message; _submitting = false; });
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
        title: const Text('Return to Warehouse'),
      ),
      body: _success
          ? _SuccessView(onDone: () => Navigator.of(context).pop(true))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceTint,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.outlineWarm),
                    ),
                    child: Row(children: [
                      Icon(Icons.warehouse_outlined, color: AppTheme.primaryBrown),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Select unsold or returned products from the lorry to bring back to the warehouse.',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textDark),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  Text('Products on Lorry', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search product…',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),

                  if (widget.lorryInventory.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('No products remaining on lorry.', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSoft)),
                    )
                  else
                    ...(_filteredInventory.map((product) {
                      final alreadyAdded = _items.any((i) => (i.productId != null && i.productId == product.productId) || i.productNameSnapshot == product.productName);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: alreadyAdded ? AppTheme.surfaceTint : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: alreadyAdded ? AppTheme.primaryBrown.withAlpha(180) : AppTheme.outlineWarm),
                          ),
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(product.productName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                              Text('${product.quantity} case(s)', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSoft)),
                            ])),
                            if (alreadyAdded)
                              const Icon(Icons.check_circle, color: AppTheme.primaryBrown, size: 22)
                            else
                              IconButton(
                                onPressed: () => _addItem(product),
                                icon: const Icon(Icons.add_circle_outline),
                                color: AppTheme.primaryBrown,
                              ),
                          ]),
                        ),
                      );
                    })),

                  if (_items.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Return List', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                    const SizedBox(height: 8),
                    ..._items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.outlineWarm),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Expanded(child: Text(item.productNameSnapshot, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textDark))),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Color(0xFF9B4B46)),
                              onPressed: () => setState(() => _items.removeAt(i)),
                              visualDensity: VisualDensity.compact,
                            ),
                          ]),
                          Row(children: [
                            Expanded(child: TextFormField(
                              initialValue: item.quantity.toString(),
                              decoration: const InputDecoration(labelText: 'Qty (cases)', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (v) { item.quantity = int.tryParse(v) ?? 1; setState(() {}); },
                            )),
                          ]),
                        ]),
                      );
                    }),
                  ],

                  const SizedBox(height: 24),
                  const Divider(color: AppTheme.outlineWarm),
                  const SizedBox(height: 16),

                  Text('Territory Manager Verification', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                  const SizedBox(height: 6),
                  Text('Request a PIN — it will be sent to your territory manager\'s activity center. They will share the 6-digit code with you to confirm the return.',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSoft),
                  ),
                  const SizedBox(height: 14),

                  if (!_pinRequested) ...[
                    FilledButton.icon(
                      onPressed: _requestingPin ? null : _requestPin,
                      icon: _requestingPin
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.key_outlined),
                      label: const Text('Request Warehouse Return PIN'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryBrown,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FFF4), borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF9FD4B2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFF1E7A52), size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('PIN sent to your Territory Manager. Ask them for the 6-digit code.',
                          style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF1E5C3A)),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) => SizedBox(
                        width: 44, height: 54,
                        child: TextField(
                          controller: _pinControllers[index],
                          focusNode: _pinFocusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.textDark),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            filled: true, fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.outlineWarm, width: 1.5)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryBrown, width: 2)),
                          ),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (v) {
                            if (v.length == 1 && index < 5) {
                              _pinFocusNodes[index + 1].requestFocus();
                            } else if (v.isEmpty && index > 0) _pinFocusNodes[index - 1].requestFocus();
                            setState(() {});
                          },
                        ),
                      )),
                    ),
                    const SizedBox(height: 8),
                    Center(child: TextButton(onPressed: _requestPin, child: const Text('Resend to TM'))),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Icon(Icons.check_outlined),
                      label: const Text('Submit Return & Close Trip', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryBrownDark,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EF), borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0A7A3)),
                      ),
                      child: Text(_error!, style: const TextStyle(color: Color(0xFF9B4B46), fontSize: 13)),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.warehouse, color: AppTheme.primaryBrown, size: 72),
          const SizedBox(height: 16),
          Text('Trip Closed Successfully', textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Text('All returned products have been logged and your trip has been marked as completed.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: onDone,
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryBrown, minimumSize: const Size(220, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('Back to Home'),
          ),
        ]),
      ),
    );
  }
}
