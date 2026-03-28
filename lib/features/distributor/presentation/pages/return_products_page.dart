import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/features/distributor/data/services/distributor_service.dart';
import 'package:mobile/features/distributor/domain/delivery_assignment.dart';

class ReturnProductsPage extends StatefulWidget {
  const ReturnProductsPage({super.key, required this.assignmentId});

  final String assignmentId;

  @override
  State<ReturnProductsPage> createState() => _ReturnProductsPageState();
}

class _ReturnProductsPageState extends State<ReturnProductsPage> {
  final _service = DistributorService();

  final List<ReturnItemInput> _items = [];
  final List<TextEditingController> _pinControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(6, (_) => FocusNode());

  bool _submitting = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    for (final c in _pinControllers) { c.dispose(); }
    for (final f in _pinFocusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _currentPin => _pinControllers.map((c) => c.text).join();

  void _addItem() {
    setState(() {
      _items.add(ReturnItemInput(
        productNameSnapshot: '',
        quantity: 1,
        reason: '',
      ));
    });
  }

  void _removeItem(int index) => setState(() => _items.removeAt(index));

  Future<void> _submit() async {
    if (_items.isEmpty) {
      setState(() { _error = 'Add at least one returned item.'; });
      return;
    }
    for (final item in _items) {
      if (item.productNameSnapshot.trim().isEmpty) {
        setState(() { _error = 'Fill in the product name for all items.'; });
        return;
      }
      if (item.reason.trim().isEmpty) {
        setState(() { _error = 'Provide a return reason for all items.'; });
        return;
      }
    }
    final pin = _currentPin;
    if (pin.length != 6) {
      setState(() { _error = 'Enter the 6-digit territory manager PIN.'; });
      return;
    }

    setState(() { _submitting = true; _error = null; });
    try {
      await _service.submitReturn(
        assignmentId: widget.assignmentId,
        tmPin: pin,
        items: _items,
      );
      if (mounted) setState(() { _success = true; _submitting = false; });
    } on DistributorServiceException catch (e) {
      if (mounted) setState(() { _error = e.message; _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3D2E),
        foregroundColor: Colors.white,
        title: const Text('Return Products'),
      ),
      body: _success
          ? _SuccessView(onDone: () => Navigator.of(context).pop())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Returned Items',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F3D2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'List all products being returned to the warehouse.',
                    style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF4A7A62)),
                  ),
                  const SizedBox(height: 16),

                  ..._items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return _ReturnItemCard(
                      index: i,
                      item: item,
                      onRemove: () => _removeItem(i),
                      onChanged: () => setState(() {}),
                    );
                  }),

                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E7A52),
                      side: const BorderSide(color: Color(0xFFD4EDDF)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(double.infinity, 46),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFFD4EDDF)),
                  const SizedBox(height: 16),

                  Text(
                    'Territory Manager Verification PIN',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F3D2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter the 6-digit PIN provided by your territory manager to close this trip.',
                    style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF4A7A62)),
                  ),
                  const SizedBox(height: 20),

                  // PIN boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 46,
                        height: 56,
                        child: TextField(
                          controller: _pinControllers[index],
                          focusNode: _pinFocusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F3D2E),
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFD4EDDF), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF1E7A52), width: 2),
                            ),
                          ),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (v) {
                            if (v.length == 1 && index < 5) {
                              _pinFocusNodes[index + 1].requestFocus();
                            } else if (v.isEmpty && index > 0) {
                              _pinFocusNodes[index - 1].requestFocus();
                            }
                            setState(() {});
                          },
                        ),
                      );
                    }),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0A7A3)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFF9B4B46), fontSize: 13),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: const Icon(Icons.check_outlined),
                    label: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('Submit Return & Close Trip',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F3D2E),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4EDDF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item ${index + 1}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F3D2E),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Color(0xFF9B4B46)),
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: _inputDecoration('Product Name'),
            onChanged: (v) { item.productNameSnapshot = v; onChanged(); },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: _inputDecoration('Quantity'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) { item.quantity = int.tryParse(v) ?? 1; onChanged(); },
                  controller: TextEditingController(text: item.quantity.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: _inputDecoration('Return reason'),
            maxLines: 2,
            onChanged: (v) { item.reason = v; onChanged(); },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF4A7A62), fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFF5FBF8),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4EDDF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E7A52), width: 1.5),
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
            const Icon(Icons.check_circle, color: Color(0xFF1E7A52), size: 72),
            const SizedBox(height: 16),
            Text(
              'Trip Closed Successfully',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F3D2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All returned products have been logged and your trip has been marked as completed.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF4A7A62)),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E7A52),
                minimumSize: const Size(220, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
