import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class OSAFooter extends StatelessWidget {
  const OSAFooter({
    super.key,
    required this.issuesCount,
    required this.bringingToShelfCount,
    required this.onNext,
  });

  final int issuesCount;
  final int bringingToShelfCount;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        border: Border(top: BorderSide(color: AppTheme.outlineWarm)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'OSA Issues : ${issuesCount.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: AppTheme.textSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('|', style: TextStyle(color: AppTheme.outlineWarm)),
              ),
              Text(
                'Bring ing to Shell : $bringingToShelfCount',
                style: const TextStyle(
                  color: AppTheme.textSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7A614A),
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
