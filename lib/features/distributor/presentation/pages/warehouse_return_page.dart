import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/distributor/data/services/distributor_service.dart';
import 'package:mobile/features/distributor/domain/delivery_assignment.dart';

class WarehouseReturnPage extends StatefulWidget {
  const WarehouseReturnPage({
    super.key,
    required this.assignment,
  });

  final DeliveryAssignment assignment;

  @override
  State<WarehouseReturnPage> createState() => _WarehouseReturnPageState();
}

class _WarehouseReturnPageState extends State<WarehouseReturnPage> {
  final _service = DistributorService();
  final _cashReturnedController = TextEditingController();
  final List<TextEditingController> _pinControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(6, (_) => FocusNode());

  bool _reviewRequested = false;
  bool _requestingReview = false;
  bool _submitting = false;
  bool _success = false;
  String? _error;
  String? _earlyClosureReason;

  String get _currentPin => _pinControllers.map((controller) => controller.text).join();

  List<_DisplayedReturnLine> get _shopReturnLines {
    return widget.assignment.shopReturns
        .expand((recordedReturn) {
          final shopLabel = recordedReturn.shopName ?? widget.assignment.distributorName;
          return recordedReturn.items.map(
            (item) => _DisplayedReturnLine(
              title: item.productName,
              quantityLabel:
                  '${item.quantity} ${_unitLabel(item.unitType)}',
              reasonLabel: _formatReason(item.reason, item.reasonNote),
              subtitle: [
                if (shopLabel.trim().isNotEmpty) shopLabel,
                if ((recordedReturn.orderCode ?? '').trim().isNotEmpty)
                  recordedReturn.orderCode!,
              ].join(' · '),
              accentColor: const Color(0xFFB86152),
            ),
          );
        })
        .toList();
  }

  List<_DisplayedReturnLine> get _unfinishedDeliveryLines {
    return widget.assignment.orders
        .where((order) => !order.isCompleted)
        .expand(
          (order) => order.items.map(
            (item) => _DisplayedReturnLine(
              title: item.productName,
              quantityLabel: '${item.quantity} case(s)',
              reasonLabel: 'Unfinished delivery',
              subtitle: '${order.shopName} · ${order.orderCode}',
              accentColor: AppTheme.proceedOrderOlive,
            ),
          ),
        )
        .toList();
  }

  double get _expectedCash => widget.assignment.expectedRouteCash;

  double get _cashReturnedAmount =>
      double.tryParse(_cashReturnedController.text.trim()) ?? -1;

  bool get _hasCashMismatch =>
      _cashReturnedAmount >= 0 &&
      (_cashReturnedAmount - _expectedCash).abs() >= 0.01;

  @override
  void initState() {
    super.initState();
    _cashReturnedController.text = _expectedCash.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _cashReturnedController.dispose();
    for (final controller in _pinControllers) {
      controller.dispose();
    }
    for (final focusNode in _pinFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _requestReview() async {
    final cashReturnedAmount = _cashReturnedAmount;
    if (cashReturnedAmount < 0) {
      setState(() {
        _error = 'Enter the cash amount you are returning today.';
      });
      return;
    }

    String? earlyClosureReason = _earlyClosureReason;
    if (widget.assignment.remainingStopsCount > 0) {
      final shouldContinue = await _confirmEarlyClosure();
      if (!shouldContinue || !mounted) {
        return;
      }

      earlyClosureReason = await _promptForReason(
        title: 'Why are you ending the route now?',
        hintText: 'Explain why the remaining shops could not be completed.',
        initialValue: _earlyClosureReason,
      );

      if (!mounted || earlyClosureReason == null) {
        return;
      }
    }

    setState(() {
      _requestingReview = true;
      _error = null;
      _earlyClosureReason = earlyClosureReason;
    });

    try {
      final message = await _service.requestWarehouseReturnPin(
        assignmentId: widget.assignment.id,
        cashReturnedAmount: cashReturnedAmount,
        earlyClosureReason: _earlyClosureReason,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _reviewRequested = true;
        _requestingReview = false;
      });

      _showMessage(message);
    } on DistributorServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.message;
        _requestingReview = false;
      });
    }
  }

  Future<void> _submit() async {
    final pin = _currentPin;
    if (pin.length != 6) {
      setState(() {
        _error = 'Enter the 6-digit end-route PIN from your Territory Manager.';
      });
      return;
    }

    final cashReturnedAmount = _cashReturnedAmount;
    if (cashReturnedAmount < 0) {
      setState(() {
        _error = 'Enter the cash amount you are returning today.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final message = await _service.submitReturn(
        assignmentId: widget.assignment.id,
        tmPin: pin,
        items: const <ReturnItemInput>[],
        cashReturnedAmount: cashReturnedAmount,
        earlyClosureReason: _earlyClosureReason,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _success = true;
        _submitting = false;
      });

      _showMessage(message);
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

  Future<bool> _confirmEarlyClosure() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remaining shops still need delivery'),
          content: Text(
            'There are ${widget.assignment.remainingStopsCount} pending stop(s) left on today\'s route. Are you sure you want to end the route now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Yes, continue'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<String?> _promptForReason({
    required String title,
    required String hintText,
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: hintText,
              alignLabelWithHint: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  return;
                }
                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Save reason'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return reason;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceWarm,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBrownDark,
        foregroundColor: Colors.white,
        title: const Text('End Route'),
      ),
      body: _success
          ? _SuccessView(onDone: () => Navigator.of(context).pop(true))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BannerCard(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Route close review',
                    message:
                        'Recorded shop-owner returns and unfinished deliveries are listed below so the Territory Manager can review the full route settlement before sharing the PIN.',
                  ),
                  const SizedBox(height: 20),
                  _SummaryStrip(
                    expectedCash: _expectedCash,
                    deliveredCount: widget.assignment.completedCount,
                    pendingCount: widget.assignment.remainingStopsCount,
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: 'Recorded shop returns',
                    subtitle:
                        'These are the products you already logged while delivering to shops.',
                  ),
                  const SizedBox(height: 10),
                  if (_shopReturnLines.isEmpty)
                    const _EmptyStateCard(
                      message:
                          'No shop-owner returns have been recorded on this route yet.',
                    )
                  else
                    ..._shopReturnLines.map(_ReturnLineCard.new),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: 'Undelivered orders returning to warehouse',
                    subtitle:
                        'Any remaining assigned orders are treated as unfinished delivery stock returning with the lorry.',
                  ),
                  const SizedBox(height: 10),
                  if (_unfinishedDeliveryLines.isEmpty)
                    const _EmptyStateCard(
                      message:
                          'All assigned deliveries are completed, so there are no unfinished-order returns.',
                    )
                  else
                    ..._unfinishedDeliveryLines.map(_ReturnLineCard.new),
                  const SizedBox(height: 24),
                  Text(
                    'Returning cash',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Expected today amount: LKR ${_expectedCash.toStringAsFixed(2)}. This already subtracts the recorded shop-owner return value from the completed-delivery cash total.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSoft,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cashReturnedController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Cash returned (LKR)',
                      hintText: _expectedCash.toStringAsFixed(2),
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_hasCashMismatch) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8B4AF)),
                      ),
                      child: Text(
                        'The system will flag this cash difference for your Territory Manager: LKR ${(_cashReturnedAmount - _expectedCash).toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.rejectOrderRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(color: AppTheme.outlineWarm),
                  const SizedBox(height: 16),
                  Text(
                    'Territory Manager review',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _reviewRequested
                        ? 'Your review request has been sent. Once the Territory Manager checks the order list, returned products, and returned cash, they can tell you the 6-digit end-route PIN.'
                        : 'Send the route-close review to your Territory Manager first. They will check the order list, returned products, and returned cash before generating the end-route PIN.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSoft,
                    ),
                  ),
                  if (_earlyClosureReason != null &&
                      _earlyClosureReason!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _BannerCard(
                      icon: Icons.info_outline,
                      title: 'Early closure reason',
                      message: _earlyClosureReason!,
                      color: const Color(0xFFF0FFF4),
                      borderColor: const Color(0xFFB7D9C2),
                      iconColor: const Color(0xFF1E7A52),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (!_reviewRequested)
                    FilledButton.icon(
                      onPressed: _requestingReview ? null : _requestReview,
                      icon: _requestingReview
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_outlined),
                      label: const Text('Send End Route Review to TM'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryBrown,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    )
                  else ...[
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
                              'Review request sent. Ask your Territory Manager for the 6-digit end-route PIN after they finish checking the settlement.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF1E5C3A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                        onPressed: _requestReview,
                        child: const Text('Resend review to TM'),
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
                        'End Route',
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

  String _unitLabel(String? unitType) {
    return unitType?.trim().toUpperCase() == 'ITEM' ? 'product(s)' : 'case(s)';
  }

  String _formatReason(String reason, String? note) {
    final normalized = reason
        .trim()
        .toLowerCase()
        .split(RegExp(r'[_\s]+'))
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
    if (note == null || note.trim().isEmpty) {
      return normalized;
    }
    return '$normalized · ${note.trim()}';
  }
}

class _DisplayedReturnLine {
  const _DisplayedReturnLine({
    required this.title,
    required this.quantityLabel,
    required this.reasonLabel,
    required this.subtitle,
    required this.accentColor,
  });

  final String title;
  final String quantityLabel;
  final String reasonLabel;
  final String subtitle;
  final Color accentColor;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSoft),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.icon,
    required this.title,
    required this.message,
    this.color = AppTheme.surfaceTint,
    this.borderColor = AppTheme.outlineWarm,
    this.iconColor = AppTheme.primaryBrown,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final Color borderColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(180),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.expectedCash,
    required this.deliveredCount,
    required this.pendingCount,
  });

  final double expectedCash;
  final int deliveredCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            label: 'Expected cash',
            value: 'LKR ${expectedCash.toStringAsFixed(2)}',
            accentColor: AppTheme.proceedOrderOlive,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            label: 'Delivered',
            value: '$deliveredCount',
            accentColor: AppTheme.primaryBrownDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            label: 'Remaining',
            value: '$pendingCount',
            accentColor: AppTheme.rejectOrderRed,
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnLineCard extends StatelessWidget {
  const _ReturnLineCard(this.line);

  final _DisplayedReturnLine line;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: line.accentColor.withAlpha(20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.keyboard_return_outlined,
              color: line.accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  line.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSoft,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TinyTag(label: line.quantityLabel, color: line.accentColor),
                    _TinyTag(label: line.reasonLabel, color: AppTheme.textSoft),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyTag extends StatelessWidget {
  const _TinyTag({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
            Icon(
              Icons.check_circle_outline,
              color: AppTheme.proceedOrderOlive,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              'Route closed successfully',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The end-route cash settlement is saved and the return review is complete.',
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
                minimumSize: const Size(220, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
