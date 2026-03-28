import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/features/distributor/data/services/distributor_service.dart';
import 'package:mobile/features/distributor/domain/delivery_assignment.dart';

class CompleteOrderPage extends StatefulWidget {
  const CompleteOrderPage({super.key, required this.order});

  final AssignmentOrder order;

  @override
  State<CompleteOrderPage> createState() => _CompleteOrderPageState();
}

class _CompleteOrderPageState extends State<CompleteOrderPage> {
  final _service = DistributorService();
  final List<TextEditingController> _pinControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _submitting = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    for (final c in _pinControllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _currentPin =>
      _pinControllers.map((c) => c.text).join();

  Future<void> _submit() async {
    final pin = _currentPin;
    if (pin.length != 6) {
      setState(() { _error = 'Enter all 6 digits of the shop owner PIN.'; });
      return;
    }

    setState(() { _submitting = true; _error = null; });

    try {
      await _service.completeOrder(orderId: widget.order.orderId, pin: pin);
      if (mounted) setState(() { _success = true; _submitting = false; });
    } on DistributorServiceException catch (e) {
      if (mounted) setState(() { _error = e.message; _submitting = false; });
    }
  }

  void _onDigitEntered(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3D2E),
        foregroundColor: Colors.white,
        title: const Text('Complete Delivery'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order info card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD4EDDF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.store_outlined, color: Color(0xFF1E7A52), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.order.shopName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F3D2E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.order.orderCode,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF4A7A62),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (_success) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4FDE4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF9FD4B2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF1E7A52), size: 52),
                    const SizedBox(height: 12),
                    Text(
                      'Delivery Confirmed!',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF0F3D2E),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Order has been marked as completed.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF3A7A5C),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1E7A52),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Back to Deliveries'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                'Enter Shop Owner PIN',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F3D2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask the shop owner for their 6-digit delivery confirmation PIN.',
                style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF4A7A62)),
              ),
              const SizedBox(height: 32),

              // 6-digit PIN boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 46,
                    height: 56,
                    child: TextField(
                      controller: _pinControllers[index],
                      focusNode: _focusNodes[index],
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
                      onChanged: (v) => _onDigitEntered(index, v),
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

              const SizedBox(height: 32),

              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E7A52),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Confirm Delivery',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
