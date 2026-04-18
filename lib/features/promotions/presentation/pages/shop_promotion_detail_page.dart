import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/promotions/domain/promotion.dart';

/// Full-screen detail view for a specific promotion.
class ShopPromotionDetailPage extends StatelessWidget {
  const ShopPromotionDetailPage({super.key, required this.promotion});

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF8),
      appBar: AppBar(
        title: const Text('Promotion Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryBrownDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Header Card ──────────────────────────────────────────────────
            _HeaderCard(promotion: promotion),
            const SizedBox(height: 28),

            // ── Description ──────────────────────────────────────────────────
            if (promotion.description != null &&
                promotion.description!.trim().isNotEmpty) ...<Widget>[
              Text(
                'About this Promotion',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                promotion.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSoft,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
            ],

            // ── Campaign Rules ────────────────────────────────────────────────
            Text(
              'Campaign Rules',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            ...promotion.rules.map((rule) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle,
                            size: 6, color: AppTheme.promotionMutedRed),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rule,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSoft,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 28),

            // ── Eligible Products List ─────────────────────────────────────────
            Text(
              'Eligible Products',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            if (promotion.eligibleProductNames.isEmpty)
              Text(
                'This promotion applies to all items in your store catatlog.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSoft,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outlineWarm.withAlpha(80)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: promotion.eligibleProductNames.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: AppTheme.outlineWarm.withAlpha(60),
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: const CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(0xFFFDF1E7),
                        child: Icon(Icons.inventory_2_outlined,
                            size: 14, color: AppTheme.primaryBrownDark),
                      ),
                      title: Text(
                        promotion.eligibleProductNames[index],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.promotion});

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.promotionMutedRed,
        borderRadius: BorderRadius.circular(32),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.promotionMutedRed.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              promotion.offerSummary,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            promotion.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Icon(Icons.timer_outlined, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Ends on ${promotion.formattedEndDate}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
