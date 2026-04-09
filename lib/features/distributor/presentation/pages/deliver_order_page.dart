import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/distributor/data/services/distributor_service.dart';
import 'package:mobile/features/distributor/domain/delivery_assignment.dart';

class DeliverOrderPage extends StatefulWidget {
  const DeliverOrderPage({super.key, required this.order});

  final AssignmentOrder order;

  @override
  State<DeliverOrderPage> createState() => _DeliverOrderPageState();
}

class _DeliverOrderPageState extends State<DeliverOrderPage> {
  final _service = DistributorService();
  final List<TextEditingController> _pinControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _pinSent = false;
  bool _requestingPin = false;
  bool _submitting = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    for (final c in _pinControllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _currentPin => _pinControllers.map((c) => c.text).join();

  Future<void> _requestPin() async {
    setState(() { _requestingPin = true; _error = null; });
    try {
      await _service.requestDeliveryPin(orderId: widget.order.orderId);
      if (mounted) setState(() { _pinSent = true; _requestingPin = false; });
    } on DistributorServiceException catch (e) {
      if (mounted) setState(() { _error = e.message; _requestingPin = false; });
    }
  }

  Future<void> _confirm() async {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceWarm,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBrownDark,
        foregroundColor: Colors.white,
        title: const Text('Complete Delivery'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _success ? _SuccessView(onDone: () => Navigator.of(context).pop(true)) : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.outlineWarm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.store_outlined, color: AppTheme.primaryBrown, size: 22),
                    const SizedBox(width: 8),
                    Expanded(child: Text(widget.order.shopName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textDark),
                    )),
                  ]),
                  const SizedBox(height: 4),
                  Text(widget.order.orderCode,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSoft, fontFamily: 'monospace'),
                  ),
                  if (widget.order.shopAddress != null) ...[
                    const SizedBox(height: 6),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSoft),
                      const SizedBox(width: 4),
                      Expanded(child: Text(widget.order.shopAddress!,
                        style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSoft),
                      )),
                    ]),
                  ],
                  const SizedBox(height: 8),
                  Text('LKR ${widget.order.totalAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.primaryBrown, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            if (!_pinSent) ...[
              Text('Step 1: Request Delivery PIN',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
              const SizedBox(height: 8),
              Text(
                'The system will send a confirmation PIN to the shop owner\'s activity center. Ask them to check their app and share the PIN with you.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _requestingPin ? null : _requestPin,
                  icon: _requestingPin
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                      : const Icon(Icons.send_outlined),
                  label: const Text('Send PIN to Shop Owner'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrown,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF9FD4B2)),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF1E7A52)),
                  const SizedBox(width: 10),
                  Expanded(child: Text('PIN sent to shop owner\'s activity center. Ask them to check their app.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF1E5C3A)),
                  )),
                ]),
              ),
              const SizedBox(height: 24),

              Text('Step 2: Enter Shop Owner PIN',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
              const SizedBox(height: 8),
              Text('Ask the shop owner to read the 6-digit PIN from their activity center.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
              ),
              const SizedBox(height: 24),

              // PIN boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => SizedBox(
                  width: 46, height: 56,
                  child: TextField(
                    controller: _pinControllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.textDark),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.outlineWarm, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.primaryBrown, width: 2),
                      ),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      if (v.length == 1 && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (v.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
                      setState(() {});
                    },
                  ),
                )),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _requestingPin ? null : _requestPin,
                  child: Text('Resend PIN', style: TextStyle(color: AppTheme.primaryBrown)),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _confirm,
                  icon: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Icon(Icons.check),
                  label: const Text('Confirm Delivery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrown,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EF),
                  borderRadius: BorderRadius.circular(14),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppTheme.primaryBrown, size: 72),
            const SizedBox(height: 16),
            Text('Delivery Confirmed!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Text('Order has been marked as completed for the shop owner and territory manager.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Back to Deliveries'),
            ),
          ],
        ),
      ),
    );
  }
}
