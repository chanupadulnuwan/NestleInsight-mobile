import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import '../../../activity/domain/activity_entry.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.activity});

  final ActivityEntry activity;

  @override
  Widget build(BuildContext context) {
    final orderCode = activity.metadata?['orderCode']?.toString();
    final pin = activity.metadata?['pin']?.toString();
    // Decision metadata for outlet approval
    final decision = activity.metadata?['decision']?.toString();

    final isApproved = decision == 'APPROVED';
    final isRejected = decision == 'REJECTED';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(95)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryBrownDark.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              if (isApproved || isRejected)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isApproved ? AppTheme.proceedOrderOlive : AppTheme.rejectOrderRed,
                  ),
                ),
              Expanded(
                child: Text(
                  activity.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            activity.message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSoft,
            ),
          ),
          if (pin != null && pin.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceTint,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.outlineWarm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Confirmation PIN',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSoft,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pin,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.primaryBrownDark,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ActivityMetaChip(label: _formatDate(activity.createdAt)),
              ActivityMetaChip(label: _formatTime(activity.createdAt)),
              if (orderCode != null && orderCode.isNotEmpty)
                ActivityMetaChip(label: 'Order: $orderCode'),
              if (decision != null)
                ActivityMetaChip(
                  label: decision,
                  color: isApproved ? AppTheme.proceedOrderOlive : AppTheme.rejectOrderRed,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class ActivityMetaChip extends StatelessWidget {
  const ActivityMetaChip({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color?.withAlpha(30) ?? AppTheme.surfaceTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color ?? AppTheme.primaryBrownDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
