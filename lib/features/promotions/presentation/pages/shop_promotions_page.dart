import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/promotions/domain/promotion.dart';
import 'package:mobile/features/promotions/presentation/cubit/promotion_cubit.dart';
import 'package:mobile/features/promotions/presentation/cubit/promotion_state.dart';
import 'package:mobile/features/promotions/presentation/pages/shop_promotion_detail_page.dart';

/// Full-screen list of active promotions for the shop owner's territory.
///
/// Expects a [PromotionCubit] to be available in the widget tree, provided
/// by the caller via [BlocProvider.value] so that already-fetched data is
/// reused and no duplicate network call is made.
class ShopPromotionsPage extends StatelessWidget {
  const ShopPromotionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF8),
      appBar: AppBar(
        title: const Text(
          'Exclusive Deals',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryBrownDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.outlineWarm.withAlpha(80),
          ),
        ),
      ),
      body: BlocBuilder<PromotionCubit, PromotionState>(
        builder: (context, state) {
          if (state is PromotionLoading || state is PromotionInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PromotionError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<PromotionCubit>().loadPromotions(),
            );
          }

          if (state is PromotionLoaded) {
            if (state.promotions.isEmpty) {
              return _EmptyView(
                hasTerritory: state.territoryId.trim().isNotEmpty,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: state.promotions.length,
              itemBuilder: (context, index) {
                final promo = state.promotions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: InkWell(
                    onTap: () =>
                        showShopPromotionDetailSheet(context, promo),
                    borderRadius: BorderRadius.circular(24),
                    child: _PromotionCard(promotion: promo),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Promotion Card
// ---------------------------------------------------------------------------

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({required this.promotion});

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(90)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryBrownDark.withAlpha(8),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 6,
              color: AppTheme.promotionMutedRed,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Status chip + offer badge row.
                Row(
                  children: <Widget>[
                    _StatusChip(isActive: promotion.isActive),
                    const Spacer(),
                    _OfferBadge(label: promotion.offerSummary),
                  ],
                ),
                const SizedBox(height: 10),
                // Promotion name.
                Text(
                  promotion.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    height: 1.2,
                  ),
                ),
                // Description (optional).
                if (promotion.description != null &&
                    promotion.description!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    promotion.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSoft,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                // Date range row.
                _DateRangeRow(promotion: promotion),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card sub-widgets
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFE6F9F0)
            : AppTheme.outlineWarm.withAlpha(60),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF27AE60)
                  : AppTheme.textSoft,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? const Color(0xFF1E8449)
                  : AppTheme.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferBadge extends StatelessWidget {
  const _OfferBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.promotionMutedRed.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.promotionMutedRed.withAlpha(60),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.promotionMutedRed,
        ),
      ),
    );
  }
}

class _DateRangeRow extends StatelessWidget {
  const _DateRangeRow({required this.promotion});

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(Icons.calendar_today_outlined,
            size: 14, color: AppTheme.textSoft),
        const SizedBox(width: 6),
        Text(
          '${_fmt(promotion.startDate)}  →  ${_fmt(promotion.endDate)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSoft,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
        ),
      ],
    );
  }

  static String _fmt(DateTime dt) {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ---------------------------------------------------------------------------
// Empty / Error states
// ---------------------------------------------------------------------------

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.hasTerritory});

  final bool hasTerritory;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.local_offer_outlined,
              size: 64,
              color: AppTheme.outlineWarm.withAlpha(160),
            ),
            const SizedBox(height: 20),
            Text(
              hasTerritory ? 'No Active Deals' : 'Still Syncing Your Shop',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              hasTerritory
                  ? 'There are no active promotions for your territory right now.\nCheck back soon!'
                  : 'Your territory assignment is still syncing in the app, so deals cannot be matched yet.\nPlease reopen the app in a moment.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSoft,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: AppTheme.outlineWarm.withAlpha(160),
            ),
            const SizedBox(height: 20),
            Text(
              'Could Not Load Deals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSoft,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
