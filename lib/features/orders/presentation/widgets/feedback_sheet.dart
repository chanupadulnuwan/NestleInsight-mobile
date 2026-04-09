import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/activity/data/services/activity_feed_service.dart';
import 'package:mobile/features/activity/domain/order_feedback_request.dart';
import 'package:mobile/features/orders/domain/shop_order.dart';

/// Shows a bottom sheet allowing the shop owner to rate a completed order.
///
/// Usage:
/// ```dart
/// if (order.status == 'COMPLETED') {
///   showModalBottomSheet(
///     context: context,
///     isScrollControlled: true,
///     backgroundColor: Colors.transparent,
///     builder: (_) => FeedbackSheet(order: order),
///   );
/// }
/// ```
class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({super.key, required this.order});

  final ShopOrder order;

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  final _commentController = TextEditingController();
  final _activityService = ActivityFeedService();

  int _selectedRating = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      setState(() => _errorMessage = 'Please select a star rating before submitting.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _activityService.submitOrderFeedback(
        OrderFeedbackRequest(
          orderId: widget.order.id,
          rating: _selectedRating,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback! ⭐')),
      );
    } on ActivityFeedServiceException catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // ── Drag handle ───────────────────────────────────────────
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.outlineWarm,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Header ────────────────────────────────────────────────
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFE6A817),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Rate your order',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.order.orderCode,
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

                const SizedBox(height: 24),

                // ── Star picker ───────────────────────────────────────────
                Text(
                  'How was your experience?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    final isSelected = starValue <= _selectedRating;
                    return GestureDetector(
                      onTap: _isSubmitting
                          ? null
                          : () => setState(() => _selectedRating = starValue),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(4),
                        child: AnimatedScale(
                          scale: isSelected ? 1.18 : 1.0,
                          duration: const Duration(milliseconds: 160),
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 44,
                            color: isSelected
                                ? const Color(0xFFE6A817)
                                : AppTheme.outlineWarm,
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                // ── Rating label ──────────────────────────────────────────
                if (_selectedRating > 0) ...<Widget>[
                  const SizedBox(height: 8),
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _ratingLabel(_selectedRating),
                        key: ValueKey(_selectedRating),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _ratingColor(_selectedRating),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Comment field ─────────────────────────────────────────
                TextField(
                  controller: _commentController,
                  enabled: !_isSubmitting,
                  maxLines: 3,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Leave a comment (optional)',
                    alignLabelWithHint: true,
                    hintText: 'Share more about your experience…',
                  ),
                ),

                // ── Error banner ──────────────────────────────────────────
                if (_errorMessage != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0EE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE8C5BF)),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: Color(0xFFB94040),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFB94040),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Actions ───────────────────────────────────────────────
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: (_isSubmitting || _selectedRating == 0) ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE6A817),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFFE6A817).withAlpha(80),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Submit rating',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _ratingLabel(int rating) {
  switch (rating) {
    case 1:
      return 'Very dissatisfied 😞';
    case 2:
      return 'Dissatisfied 😕';
    case 3:
      return 'Neutral 😐';
    case 4:
      return 'Satisfied 😊';
    case 5:
      return 'Very satisfied 🌟';
    default:
      return '';
  }
}

Color _ratingColor(int rating) {
  if (rating <= 2) return const Color(0xFFB94040);
  if (rating == 3) return const Color(0xFF8C7663);
  return const Color(0xFF4D7A3A);
}
