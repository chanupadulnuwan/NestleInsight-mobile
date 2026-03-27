import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/services/auth_service.dart';
import 'package:mobile/features/auth/presentation/pages/login_page.dart';
import 'package:mobile/features/profile/domain/shop_owner_profile.dart';
import 'package:mobile/features/profile/presentation/widgets/shop_owner_profile_sheet.dart';

class ShopOwnerHomePage extends StatefulWidget {
  const ShopOwnerHomePage({super.key, this.user});

  final Map<String, dynamic>? user;

  // Demo content for the UI until the real product catalog is connected.
  static const List<String> _categories = <String>[
    'All',
    'Beverages',
    'Dairy',
    'Confectionery',
    'Culinary',
  ];

  static const List<_ShopProduct> _products = <_ShopProduct>[
    _ShopProduct(
      name: 'NESCAFE 3in1',
      description: 'Original - 20g sachet',
      caseInfo: '1 case = 24 sachets',
      price: 'LKR 780',
      unitLabel: '/ case',
      imageAssetPath: 'assets/images/products/nescafe_3in1.png',
      badgeLabel: 'NC',
    ),
    _ShopProduct(
      name: 'MILO Powder',
      description: 'Activ-Go - 400g tin',
      caseInfo: '1 case = 12 tins',
      price: 'LKR 3,240',
      unitLabel: '/ case',
      imageAssetPath: 'assets/images/products/milo_400g.png',
      badgeLabel: 'MI',
    ),
    _ShopProduct(
      name: 'Nestle Everyday',
      description: 'Milk powder - 400g pack',
      caseInfo: '1 case = 24 packs',
      price: 'LKR 5,460',
      unitLabel: '/ case',
      imageAssetPath: 'assets/images/products/nestle_everyday.png',
      badgeLabel: 'ED',
    ),
    _ShopProduct(
      name: 'MAGGI Noodles',
      description: 'Chicken - 73g pack',
      caseInfo: '1 case = 30 packs',
      price: 'LKR 1,950',
      unitLabel: '/ case',
      imageAssetPath: 'assets/images/products/maggi_chicken.png',
      badgeLabel: 'MG',
    ),
  ];

  @override
  State<ShopOwnerHomePage> createState() => _ShopOwnerHomePageState();
}

class _ShopOwnerHomePageState extends State<ShopOwnerHomePage> {
  final AuthService _authService = AuthService();

  late ShopOwnerProfile _profile;
  late DateTime _currentTime;
  Timer? _greetingTimer;

  @override
  void initState() {
    super.initState();
    _profile = ShopOwnerProfile.fromJson(widget.user);
    _currentTime = DateTime.now();
    // Greeting syncs with time of day and refreshes automatically while the screen stays open.
    _greetingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  String get _greetingText {
    final hour = _currentTime.hour;
    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.logout();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _openProfileSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShopOwnerProfileSheet(
        initialProfile: _profile,
        onProfileSaved: (profile) {
          if (!mounted) {
            return;
          }

          setState(() {
            _profile = profile;
          });
        },
        onLogoutRequested: () => _logout(context),
      ),
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width >= 700;
        final horizontalPadding = isTablet ? 28.0 : 14.0;
        // Extra bottom space keeps the fixed feedback button from covering cards.
        final contentBottomPadding = isTablet ? 240.0 : 224.0;

        return Scaffold(
          backgroundColor: Colors.white,
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: Padding(
            padding: EdgeInsets.only(left: isTablet ? 12 : 0, bottom: 2),
            child: FilledButton.icon(
              onPressed: () =>
                  _showToast(context, 'Feedback module can be connected next.'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBrownDark,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 20 : 16,
                  vertical: isTablet ? 14 : 12,
                ),
                minimumSize: Size(isTablet ? 138 : 112, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline, size: 17),
              label: Text(
                'Feedback',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          bottomNavigationBar: _BottomBar(isTablet: isTablet),
          body: Container(
            // Page background wash.
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Colors.white, Color(0xFFFFFCF8)],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  10,
                  horizontalPadding,
                  contentBottomPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isTablet ? 980 : 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _HeaderCard(
                          greetingText: _greetingText,
                          shopName: _profile.displayShopName,
                          locationLabel: _profile.locationLabel,
                          isTablet: isTablet,
                          onProfileTap: _openProfileSheet,
                        ),
                        SizedBox(height: isTablet ? 22 : 18),
                        _SearchBar(
                          isTablet: isTablet,
                          onFilterTap: () => _showToast(
                            context,
                            'Filter options can be connected next.',
                          ),
                        ),
                        SizedBox(height: isTablet ? 22 : 18),
                        _OfferBanner(isTablet: isTablet),
                        SizedBox(height: isTablet ? 28 : 24),
                        _ProductSection(
                          categories: ShopOwnerHomePage._categories,
                          products: ShopOwnerHomePage._products,
                          isTablet: isTablet,
                          onSeeAll: () => _showToast(
                            context,
                            'Product catalog can be expanded next.',
                          ),
                          onAddToCart: (productName) => _showToast(
                            context,
                            '$productName added to cart.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
      height: isTablet ? 230 : 198,
      // Header visual controls: gradient, radius, and decorative circles.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // Header color changed to its own reusable theme tones so it no longer matches the add-to-cart button too closely.
          colors: <Color>[
            AppTheme.headerGradientStart,
            AppTheme.headerGradientEnd,
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -52,
            right: -42,
            child: Container(
              width: isTablet ? 220 : 170,
              height: isTablet ? 220 : 170,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -24,
            bottom: -34,
            child: Container(
              width: isTablet ? 150 : 116,
              height: isTablet ? 150 : 116,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(28),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 28 : 20,
              isTablet ? 18 : 16,
              isTablet ? 28 : 20,
              isTablet ? 24 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Align(
                  alignment: Alignment.topRight,
                  child: Material(
                    color: Colors.transparent,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        InkWell(
                          onTap: onProfileTap,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: isTablet ? 56 : 48,
                            height: isTablet ? 56 : 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withAlpha(220),
                                width: 1.3,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.person_outline,
                              color: Colors.white,
                              size: isTablet ? 28 : 24,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 1,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDA2F3D),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  greetingText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withAlpha(235),
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 20 : 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  shopName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: isTablet ? 36 : 27,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 14),
                _InfoChip(
                  icon: Icons.home_outlined,
                  label: locationLabel,
                  isTablet: isTablet,
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
    final theme = Theme.of(context);

    return Container(
      // Search box styling lives here.
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 18 : 14,
        vertical: isTablet ? 12 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(110)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryBrownDark.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.search,
            color: AppTheme.textSoft,
            size: isTablet ? 26 : 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search Nestle products...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSoft,
                fontSize: isTablet ? 20 : 16,
              ),
            ),
          ),
          Material(
            color: AppTheme.surfaceTint,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onFilterTap,
              child: SizedBox(
                width: isTablet ? 54 : 46,
                height: isTablet ? 54 : 46,
                child: Icon(
                  Icons.tune,
                  color: AppTheme.primaryBrownDark,
                  size: isTablet ? 24 : 20,
                ),
              ),
            ),
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
      width: double.infinity,
      // Promo banner styling and spacing.
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 22 : 16,
        vertical: isTablet ? 18 : 14,
      ),
      decoration: BoxDecoration(
        // Promotion card color: softened red so it still feels promotional but matches the warm theme better.
        color: AppTheme.promotionMutedRed,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x22C85C53),
            blurRadius: 22,
            offset: Offset(0, 12),
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withAlpha(225),
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 15 : 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Buy 5 Cases, Get\n1 Case Free',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: isTablet ? 26 : 19,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 14,
                vertical: isTablet ? 13 : 10,
              ),
              minimumSize: Size(isTablet ? 118 : 100, 0),
            ),
            child: Text(
              'View Deal',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: isTablet ? 17 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  const _ProductSection({
    required this.categories,
    required this.products,
    required this.isTablet,
    required this.onSeeAll,
    required this.onAddToCart,
  });

  final List<String> categories;
  final List<_ShopProduct> products;
  final bool isTablet;
  final VoidCallback onSeeAll;
  final ValueChanged<String> onAddToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final crossAxisCount = isTablet ? 2 : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Section heading row.
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Nestle Products',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 30 : 24,
                ),
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'See all',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryBrown,
                  fontWeight: FontWeight.w600,
                  fontSize: isTablet ? 18 : 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Category chips.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List<Widget>.generate(categories.length, (index) {
              final isSelected = index == 0;
              return Padding(
                padding: EdgeInsets.only(
                  right: index == categories.length - 1 ? 0 : 10,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 20 : 16,
                    vertical: isTablet ? 12 : 9,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryBrown : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryBrown
                          : AppTheme.outlineWarm.withAlpha(130),
                    ),
                  ),
                  child: Text(
                    categories[index],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.primaryBrownDark,
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 17 : 14,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            // Increase this if card content grows again.
            mainAxisExtent: isTablet ? 408 : 392,
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            return _ProductCard(
              product: product,
              isTablet: isTablet,
              onAddToCart: () => onAddToCart(product.name),
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
    required this.onAddToCart,
  });

  final _ShopProduct product;
  final bool isTablet;
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
                width: isTablet ? 166 : 132,
                height: isTablet ? 132 : 102,
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
                _QuantityPill(isTablet: isTablet),
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

  final _ShopProduct product;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          product.price,
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
  const _QuantityPill({required this.isTablet});

  final bool isTablet;

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
          _CounterButton(label: '-', isTablet: isTablet),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 14),
            child: Text(
              '1',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: isTablet ? 18 : 15,
              ),
            ),
          ),
          _CounterButton(label: '+', isTablet: isTablet),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({required this.label, required this.isTablet});

  final String label;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.isTablet});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label, bool active})>[
      (icon: Icons.home_outlined, label: 'Home', active: true),
      (icon: Icons.inventory_2_outlined, label: 'Orders', active: false),
      (icon: Icons.show_chart_outlined, label: 'Activity', active: false),
      (icon: Icons.settings_outlined, label: 'Settings', active: false),
    ];

    return SafeArea(
      top: false,
      child: Container(
        // Bottom navigation styling.
        padding: EdgeInsets.fromLTRB(
          isTablet ? 18 : 14,
          10,
          isTablet ? 18 : 14,
          isTablet ? 14 : 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppTheme.outlineWarm.withAlpha(90)),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.primaryBrownDark.withAlpha(10),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            final color = item.active
                ? AppTheme.primaryBrown
                : AppTheme.textSoft;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(item.icon, color: color, size: isTablet ? 28 : 24),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: item.active ? FontWeight.w700 : FontWeight.w500,
                    fontSize: isTablet ? 13 : 11,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: item.active
                        ? AppTheme.primaryBrown
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ShopProduct {
  const _ShopProduct({
    required this.name,
    required this.description,
    required this.caseInfo,
    required this.price,
    required this.unitLabel,
    required this.imageAssetPath,
    required this.badgeLabel,
  });

  final String name;
  final String description;
  final String caseInfo;
  final String price;
  final String unitLabel;
  final String imageAssetPath;
  final String badgeLabel;
}
