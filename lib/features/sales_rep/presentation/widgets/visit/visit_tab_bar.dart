import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

enum VisitTab { stock, expiry, issues, promotions, display, feedback, delivery }

extension VisitTabLabel on VisitTab {
  String get label {
    switch (this) {
      case VisitTab.stock:
        return 'Stock';
      case VisitTab.expiry:
        return 'Expiry';
      case VisitTab.issues:
        return 'Issues';
      case VisitTab.promotions:
        return 'Promos';
      case VisitTab.display:
        return 'Display';
      case VisitTab.feedback:
        return 'Feedback';
      case VisitTab.delivery:
        return 'Delivery';
    }
  }

  IconData get icon {
    switch (this) {
      case VisitTab.stock:
        return Icons.inventory_2_outlined;
      case VisitTab.expiry:
        return Icons.warning_amber_outlined;
      case VisitTab.issues:
        return Icons.report_problem_outlined;
      case VisitTab.promotions:
        return Icons.local_offer_outlined;
      case VisitTab.display:
        return Icons.grid_view_rounded;
      case VisitTab.feedback:
        return Icons.feedback_outlined;
      case VisitTab.delivery:
        return Icons.local_shipping_outlined;
    }
  }
}

class VisitTabBar extends StatelessWidget {
  const VisitTabBar({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.hasDelivery,
  });

  final VisitTab activeTab;
  final ValueChanged<VisitTab> onTabChanged;
  final bool hasDelivery;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      VisitTab.stock,
      VisitTab.expiry,
      VisitTab.issues,
      VisitTab.promotions,
      VisitTab.display,
      VisitTab.feedback,
      if (hasDelivery) VisitTab.delivery,
    ];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isActive = activeTab == tab;

          return GestureDetector(
            onTap: () => onTabChanged(tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primaryBrown
                    : const Color(0xFFF2E8DF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab.icon,
                    size: 15,
                    color: isActive ? Colors.white : AppTheme.textSoft,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    tab.label,
                    style: TextStyle(
                      color: isActive ? Colors.white : AppTheme.textSoft,
                      fontSize: 12,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
