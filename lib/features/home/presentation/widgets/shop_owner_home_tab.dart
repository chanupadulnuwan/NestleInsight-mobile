import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/home/domain/shop_catalog_product.dart';
import 'package:mobile/features/home/presentation/controllers/shop_owner_dashboard_controller.dart';
import 'package:mobile/features/profile/domain/shop_owner_profile.dart';

class ShopOwnerHomeTab extends StatelessWidget {
  const ShopOwnerHomeTab({
    super.key,
    required this.isTablet,
    required this.profile,
    required this.greetingText,
    required this.controller,
    required this.onProfileTap,
    required this.onProceedOrderTap,
    required this.onShowMessage,
  });

  final bool isTablet;
  final ShopOwnerProfile profile;
  final String greetingText;
  final ShopOwnerDashboardController controller;
  final VoidCallback onProfileTap;
  final VoidCallback onProceedOrderTap;
  final ValueChanged<String> onShowMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HeaderCard(
          greetingText: greetingText,
          shopName: profile.displayShopName,
          locationLabel: profile.locationLabel,
          isTablet: isTablet,
          onProfileTap: onProfileTap,
        ),
        SizedBox(height: isTablet ? 22 : 18),
        _SearchBar(
          isTablet: isTablet,
          onFilterTap: () =>
              onShowMessage('Filter options can be connected next.'),
        ),
        SizedBox(height: isTablet ? 22 : 18),
        _OfferBanner(isTablet: isTablet),
        SizedBox(height: isTablet ? 28 : 24),
        _ProductSection(
          controller: controller,
          isTablet: isTablet,
          onSeeAll: () => onShowMessage('Product catalog can be expanded next.'),
          onAddToCart: (productName) => onShowMessage(
            '$productName added to the cart.',
          ),
        ),
        SizedBox(height: isTablet ? 22 : 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: controller.hasCartItems ? onProceedOrderTap : null,
            style: FilledButton.styleFrom(
              // Proceed-order action uses a separate olive accent so it stays on-theme without matching the existing add-to-cart button.
              backgroundColor: AppTheme.proceedOrderOlive,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Proceed the order'),
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.greetingText,
    required this.shopName,
    required this.locationLabel,
    required this.isTablet,
    required this.onProfileTap,
  });

  final String greetingText;
  final String shopName;
  final String locationLabel;
  final bool isTablet;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // Header hero card styling.
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppTheme.headerGradientStart,
            AppTheme.headerGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -40,
            top: -34,
            child: Container(
              width: isTablet ? 190 : 140,
              height: isTablet ? 190 : 140,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -46,
            child: Container(
              width: isTablet ? 160 : 110,
              height: isTablet ? 160 : 110,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 26 : 20,
              isTablet ? 24 : 20,
              isTablet ? 24 : 18,
              isTablet ? 24 : 20,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '$greetingText  ',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withAlpha(230),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        shopName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: isTablet ? 34 : 24,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _InfoChip(
                        icon: Icons.home_outlined,
                        label: locationLabel,
                        isTablet: isTablet,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: onProfileTap,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: isTablet ? 62 : 48,
                    height: isTablet ? 62 : 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(200)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: isTablet ? 30 : 24,
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD94141),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.2),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.isTablet, required this.onFilterTap});

  final bool isTablet;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 18 : 14,
        vertical: isTablet ? 12 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(100)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryBrownDark.withAlpha(8),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.search,
            color: AppTheme.textSoft,
            size: isTablet ? 24 : 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Search Nestle products...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSoft,
                fontSize: isTablet ? 17 : 15,
              ),
            ),
          ),
          IconButton.filled(
            onPressed: onFilterTap,
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.surfaceTint,
              foregroundColor: AppTheme.primaryBrownDark,
            ),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
    );
  }
}

class _OfferBanner extends StatelessWidget {
  const _OfferBanner({required this.isTablet});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 22 : 16,
      ),
      decoration: BoxDecoration(
        // Promotion banner uses a softer muted red so it stays close to the mockup without clashing with the rest of the brown theme.
        color: AppTheme.promotionMutedRed,
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.promotionMutedRed.withAlpha(45),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Limited Time Offer',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: isTablet ? 15 : 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Buy 5 Cases, Get\n1 Case Free',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: isTablet ? 28 : 18,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withAlpha(180)),
            ),
            child: const Text('View Deal'),
          ),
        ],
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  const _ProductSection({
    required this.controller,
    required this.isTablet,
    required this.onSeeAll,
    required this.onAddToCart,
  });

  final ShopOwnerDashboardController controller;
  final bool isTablet;
  final VoidCallback onSeeAll;
  final ValueChanged<String> onAddToCart;

  @override
  Widget build(BuildContext context) {
    final products = controller.catalog;
    final crossAxisCount = isTablet ? 2 : 1;
    const categories = <String>[
      'All',
      'Beverages',
      'Dairy',
      'Confectionery',
      'Culinary',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Nestle Products',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 34 : 23,
                ),
              ),
            ),
            TextButton(onPressed: onSeeAll, child: const Text('See all')),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final isSelected = index == 0;
              return ChoiceChip(
                label: Text(categories[index]),
                selected: isSelected,
                onSelected: (_) {},
                selectedColor: AppTheme.primaryBrown,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.primaryBrownDark,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                side: BorderSide(color: AppTheme.outlineWarm.withAlpha(120)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: isTablet ? 428 : 408,
          ),
          itemBuilder: (context, index) {
            final product = products[index];

            return _ProductCard(
              product: product,
              isTablet: isTablet,
              quantity: controller.selectedQuantityFor(product.code),
              onIncrease: () => controller.incrementSelection(product.code),
              onDecrease: () => controller.decrementSelection(product.code),
              onAddToCart: () {
                controller.addToCart(product);
                onAddToCart(product.name);
              },
            );
          },
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isTablet,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
    required this.onAddToCart,
  });

  final ShopCatalogProduct product;
  final bool isTablet;
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // Product card shell styling: border, shadow, and corner radius.
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
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 18 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Product image size control lives here.
            Center(
              child: SizedBox(
                width: isTablet ? 176 : 138,
                height: isTablet ? 140 : 110,
                child: Image.asset(
                  product.imageAssetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        product.badgeLabel,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryBrownDark,
                          fontWeight: FontWeight.w700,
                          fontSize: isTablet ? 28 : 20,
                          letterSpacing: 1.1,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryBrown.withAlpha(230),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                product.caseInfo,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 12 : 11,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: isTablet ? 21 : 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSoft,
                fontSize: isTablet ? 15 : 14,
              ),
            ),
            const Spacer(),
            // Keep price and quantity close together to avoid visual gaps.
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: _PriceBlock(product: product, isTablet: isTablet),
                ),
                const SizedBox(width: 8),
                _QuantityPill(
                  quantity: quantity,
                  isTablet: isTablet,
                  onIncrease: onIncrease,
                  onDecrease: onDecrease,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Theme(
                data: theme.copyWith(
                  filledButtonTheme: FilledButtonThemeData(
                    style: FilledButton.styleFrom(
                      // Add-to-cart color: warm clay tone so it differs from the feedback button but stays on-theme.
                      backgroundColor: AppTheme.addToCartClay,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
                child: FilledButton.icon(
                  onPressed: onAddToCart,
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: Text(
                    'Add to Cart',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: isTablet ? 18 : 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.product, required this.isTablet});

  final ShopCatalogProduct product;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _formatCurrency(product.unitPrice, showDecimals: false),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.primaryBrownDark,
            fontWeight: FontWeight.w700,
            fontSize: isTablet ? 28 : 22,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          product.unitLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSoft,
            fontSize: isTablet ? 15 : 13,
          ),
        ),
      ],
    );
  }
}

class _QuantityPill extends StatelessWidget {
  const _QuantityPill({
    required this.quantity,
    required this.isTablet,
    required this.onIncrease,
    required this.onDecrease,
  });

  final int quantity;
  final bool isTablet;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // Quantity stepper styling.
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 7,
        vertical: isTablet ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _CounterButton(label: '-', isTablet: isTablet, onTap: onDecrease),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 14),
            child: Text(
              '$quantity',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: isTablet ? 18 : 15,
              ),
            ),
          ),
          _CounterButton(label: '+', isTablet: isTablet, onTap: onIncrease),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.label,
    required this.isTablet,
    required this.onTap,
  });

  final String label;
  final bool isTablet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: isTablet ? 28 : 24,
        height: isTablet ? 28 : 24,
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryBrownDark,
              fontWeight: FontWeight.w700,
              fontSize: isTablet ? 18 : 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isTablet,
  });

  final IconData icon;
  final String label;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // Header location chip styling.
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14 : 12,
        vertical: isTablet ? 10 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: isTablet ? 18 : 15),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 260 : 170),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 15 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(double value, {bool showDecimals = true}) {
  final normalized = value.toStringAsFixed(2);
  final parts = normalized.split('.');
  final whole = parts.first;
  final decimal = parts.last;
  final buffer = StringBuffer();

  for (var index = 0; index < whole.length; index++) {
    final reverseIndex = whole.length - index;
    buffer.write(whole[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return showDecimals ? 'LKR ${buffer.toString()}.$decimal' : 'LKR ${buffer.toString()}';
}
