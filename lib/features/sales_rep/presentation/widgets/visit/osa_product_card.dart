import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/home/domain/shop_catalog_product.dart';
import 'osa_reason_picker.dart';

enum OSAStatus { inStock, outOfStock, none }

class OSAProductCard extends StatelessWidget {
  const OSAProductCard({
    super.key,
    required this.product,
    required this.status,
    this.reason,
    required this.onStatusChanged,
  });

  final ShopCatalogProduct product;
  final OSAStatus status;
  final String? reason;
  final Function(OSAStatus status, String? reason) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.outlineWarm),
            ),
            padding: const EdgeInsets.all(4),
            child: product.imageUrl != null
                ? Image.network(product.imageUrl!, fit: BoxFit.contain)
                : const Icon(Icons.inventory_2_outlined, color: AppTheme.textSoft),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (product.brand == 'HOT' || true) // Mocking 'Hot' tag for now
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC88243),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Hot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (status == OSAStatus.outOfStock && reason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Reason: $reason',
                      style: const TextStyle(
                        color: Color(0xFFC88243),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Toggle Actions
          _buildToggle(context),
        ],
      ),
    );
  }

  Widget _buildToggle(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7E2),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            label: 'In stock',
            isActive: status == OSAStatus.inStock,
            activeColor: const Color(0xFF88977F),
            onTap: () => onStatusChanged(OSAStatus.inStock, null),
          ),
          _buildToggleButton(
            label: 'Out of stock',
            isActive: status == OSAStatus.outOfStock,
            activeColor: const Color(0xFFD9B696),
            onTap: () async {
              final result = await showDialog<String>(
                context: context,
                builder: (context) => const OSAReasonPicker(),
              );
              if (result != null) {
                onStatusChanged(OSAStatus.outOfStock, result);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppTheme.textSoft,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
