import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

enum VisitTab { osa, order, delivery, promotions }

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
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2E8DF), // Very light beige background
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildTab(VisitTab.osa, 'OSA', Icons.list_alt),
          _buildTab(VisitTab.order, 'Order', Icons.list_alt),
          if (hasDelivery) _buildTab(VisitTab.delivery, 'Delivery', Icons.directions_bus),
          _buildTab(VisitTab.promotions, 'Promotions', Icons.sentiment_satisfied_alt),
        ],
      ),
    );
  }

  Widget _buildTab(VisitTab tab, String label, IconData icon) {
    final isActive = activeTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(tab),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFC7B7A3) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? Colors.white : AppTheme.textSoft,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.textSoft,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
