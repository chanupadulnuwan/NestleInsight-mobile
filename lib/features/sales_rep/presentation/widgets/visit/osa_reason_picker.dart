import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class OSAReasonPicker extends StatelessWidget {
  const OSAReasonPicker({super.key});

  static const List<String> reasons = [
    'Backroom only',
    'Not listed',
    'Competitor blocked',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select a reason...',
                  style: TextStyle(
                    color: AppTheme.textSoft,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...reasons.map((reason) => _buildReasonOption(context, reason)),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonOption(BuildContext context, String reason) {
    return InkWell(
      onTap: () => Navigator.pop(context, reason),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.outlineWarm, width: 2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              reason,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
