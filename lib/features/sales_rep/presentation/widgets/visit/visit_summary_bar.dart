import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class VisitSummaryBar extends StatefulWidget {
  const VisitSummaryBar({
    super.key,
    required this.suggestedOrder,
    required this.lastOrderDate,
    required this.startTime,
  });

  final String suggestedOrder;
  final String lastOrderDate;
  final DateTime startTime;

  @override
  State<VisitSummaryBar> createState() => _VisitSummaryBarState();
}

class _VisitSummaryBarState extends State<VisitSummaryBar> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.startTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(widget.startTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineWarm, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWarm,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_outline, color: AppTheme.primaryBrown, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: AppTheme.textDark, fontSize: 13),
                    children: [
                      const TextSpan(
                        text: 'Suggested Order: ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: widget.suggestedOrder,
                        style: const TextStyle(fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last Order date : ${widget.lastOrderDate}',
                  style: TextStyle(color: AppTheme.textSoft, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6B5848), // Darker brown for timer
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              _formatDuration(_elapsed),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
