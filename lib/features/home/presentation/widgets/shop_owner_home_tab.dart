import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/product_image_box.dart';
import 'package:mobile/features/home/domain/shop_catalog_product.dart';
import 'package:mobile/features/home/presentation/controllers/shop_owner_dashboard_controller.dart';
import 'package:mobile/features/profile/domain/shop_owner_profile.dart';
import 'package:mobile/features/promotions/presentation/cubit/promotion_cubit.dart';
import 'package:mobile/features/promotions/presentation/cubit/promotion_state.dart';
import 'package:mobile/features/promotions/presentation/pages/shop_promotions_page.dart';

class ShopOwnerHomeTab extends StatelessWidget {
  const ShopOwnerHomeTab({
    super.key,
    required this.isTablet,
    required this.profile,
    required this.greetingText,
    required this.controller,
    required this.territoryId,
    required this.onProfileTap,
    required this.onProceedOrderTap,
    required this.onShowMessage,
  });

  final bool isTablet;
  final ShopOwnerProfile profile;
  final String greetingText;
  final ShopOwnerDashboardController controller;
  final String territoryId;
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
          query: controller.searchQuery,
          onChanged: controller.updateSearchQuery,
          onTrailingAction: () {
            if (controller.searchQuery.isNotEmpty ||
                controller.selectedCategory != 'All') {
              controller.resetCatalogFilters();
              return;
            }

            controller.loadCatalog();
          },
          trailingIcon:
              controller.searchQuery.isNotEmpty ||
                  controller.selectedCategory != 'All'
              ? Icons.close
              : Icons.refresh,
        ),
        SizedBox(height: isTablet ? 22 : 18),
        _OfferBanner(isTablet: isTablet),
        SizedBox(height: isTablet ? 28 : 24),
        _ProductSection(
          controller: controller,
          isTablet: isTablet,
          onSeeAll: () => _showAllProductsSheet(context),
          onAddToCart: (productName) =>
              onShowMessage('$productName added to the cart.'),
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

  Future<void> _showAllProductsSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AllProductsSheet(
        isTablet: isTablet,
        products: controller.allCatalogProducts,
      ),
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
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: isTablet ? 30 : 24,
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

class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.isTablet,
    required this.query,
    required this.onChanged,
    required this.onTrailingAction,
    required this.trailingIcon,
  });

  final bool isTablet;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onTrailingAction;
  final IconData trailingIcon;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _SearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query == _textController.text) {
      return;
    }

    _textController.value = TextEditingValue(
      text: widget.query,
      selection: TextSelection.collapsed(offset: widget.query.length),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 18 : 14,
        vertical: widget.isTablet ? 12 : 10,
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
            size: widget.isTablet ? 24 : 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _textController,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search Nestle products...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSoft,
                  fontSize: widget.isTablet ? 17 : 15,
                ),
              ),
            ),
          ),
          IconButton.filled(
            onPressed: widget.onTrailingAction,
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.surfaceTint,
              foregroundColor: AppTheme.primaryBrownDark,
            ),
            icon: Icon(widget.trailingIcon),
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
        // Promotion banner uses a softer muted red so it stays close to the
        // mockup without clashing with the rest of the brown theme.
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Promotions',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: isTablet ? 15 : 12,
                  ),
                ),
                const SizedBox(height: 6),
                // Subtitle is driven by PromotionCubit state.
                BlocBuilder<PromotionCubit, PromotionState>(
                  builder: (context, state) {
                    final String subtitle;
                    if (state is PromotionLoading) {
                      subtitle = 'Fetching deals...';
                    } else if (state is PromotionError) {
                      subtitle = 'Deals unavailable right now.';
                    } else if (state is PromotionLoaded &&
                        state.firstPromotion != null) {
                      subtitle = state.firstPromotion!.name;
                    } else if (state is PromotionLoaded &&
                        state.territoryId.trim().isEmpty) {
                      subtitle = 'Syncing your territory...';
                    } else {
                      subtitle = 'No active deals right now.';
                    }
                    return Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: isTablet ? 28 : 18,
                        height: 1.1,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {
              // Share the existing cubit so ShopPromotionsPage reuses
              // already-fetched data without an extra network call.
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider.value(
                    value: context.read<PromotionCubit>(),
                    child: const ShopPromotionsPage(),
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withAlpha(180)),
            ),
            child: const Text('View Deals'),
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
    final categories = controller.catalogCategories;
    final crossAxisCount = isTablet ? 2 : 1;

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
        if (controller.catalogError != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4F2),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE8C4BE)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.error_outline, color: Color(0xFF9B5A52)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      controller.catalogError!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF8A4D46),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      controller.loadCatalog();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Row(
              children: List<Widget>.generate(categories.length, (index) {
                final category = categories[index];
                final isSelected = category == controller.selectedCategory;

                return Padding(
                  padding: EdgeInsets.only(
                    right: index == categories.length - 1 ? 0 : 10,
                  ),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => controller.selectCategory(category),
                    selectedColor: AppTheme.primaryBrown,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.primaryBrownDark,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: AppTheme.outlineWarm.withAlpha(120),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (controller.isLoadingCatalog && !controller.hasCatalogProducts)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (products.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWarm,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.outlineWarm.withAlpha(100)),
            ),
            child: Text(
              controller.searchQuery.trim().isEmpty &&
                      controller.selectedCategory == 'All'
                  ? 'No active products are available right now.'
                  : 'No active products matched the current search or category.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
            ),
          )
        else
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
                quantity: controller.selectedQuantityFor(product.id),
                onIncrease: () => controller.incrementSelection(product.id),
                onDecrease: () => controller.decrementSelection(product.id),
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
                child: ProductImageBox(
                  imageSource: product.imageUrl,
                  fallbackLabel: product.badgeLabel,
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
              product.displayDescription,
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
              child: _AnimatedAddToCartButton(
                onPressed: onAddToCart,
                labelStyle: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 18 : 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedAddToCartButton extends StatefulWidget {
  const _AnimatedAddToCartButton({
    required this.labelStyle,
    required this.onPressed,
  });

  final TextStyle? labelStyle;
  final VoidCallback onPressed;

  @override
  State<_AnimatedAddToCartButton> createState() =>
      _AnimatedAddToCartButtonState();
}

class _AnimatedAddToCartButtonState extends State<_AnimatedAddToCartButton> {
  bool _isPressed = false;
  bool _isRunningTapAnimation = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() {
      _isPressed = value;
    });
  }

  Future<void> _handleTap() async {
    if (_isRunningTapAnimation) {
      return;
    }

    _isRunningTapAnimation = true;
    _setPressed(true);
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) {
      return;
    }

    widget.onPressed();
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) {
      return;
    }

    _setPressed(false);
    _isRunningTapAnimation = false;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isPressed
        ? AppTheme.primaryBrownDark
        : AppTheme.addToCartClay;

    return AnimatedScale(
      scale: _isPressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.white.withValues(alpha: 0.10),
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  'Add to Cart',
                  style: widget.labelStyle?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
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
          _formatCurrency(product.orderPrice, showDecimals: false),
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

class _AllProductsSheet extends StatelessWidget {
  const _AllProductsSheet({required this.isTablet, required this.products});

  final bool isTablet;
  final List<ShopCatalogProduct> products;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 56,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.outlineWarm,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'All Products',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${products.length} active products available',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.65,
                  ),
                  child: products.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No active products are available right now.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.textSoft),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: products.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final product = products[index];
                            final packSizeLabel =
                                product.packSize.trim().isEmpty
                                ? product.categoryName
                                : '${product.categoryName} • ${product.packSize}';

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceWarm,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: AppTheme.outlineWarm.withAlpha(100),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  SizedBox(
                                    width: isTablet ? 92 : 72,
                                    height: isTablet ? 92 : 72,
                                    child: ProductImageBox(
                                      imageSource: product.imageUrl,
                                      fallbackLabel: product.badgeLabel,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          product.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: AppTheme.textDark,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          packSizeLabel,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppTheme.textSoft,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          product.caseInfo,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color:
                                                    AppTheme.primaryBrownDark,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatCurrency(
                                            product.orderPrice,
                                            showDecimals: false,
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color:
                                                    AppTheme.primaryBrownDark,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
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

  return showDecimals
      ? 'LKR ${buffer.toString()}.$decimal'
      : 'LKR ${buffer.toString()}';
}
