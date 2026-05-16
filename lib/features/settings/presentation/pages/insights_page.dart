import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/settings/data/services/insights_service.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  final InsightsService _service = InsightsService();

  ShopInsights? _insights;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final insights = await _service.fetchMyInsights();
      if (!mounted) return;
      setState(() {
        _insights = insights;
        _isLoading = false;
      });
    } on InsightsServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppTheme.textDark,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Shop Insights',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            color: AppTheme.primaryBrown,
            onPressed: _load,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : _InsightsBody(insights: _insights!),
    );
  }
}

class _InsightsBody extends StatefulWidget {
  const _InsightsBody({required this.insights});

  final ShopInsights insights;

  @override
  State<_InsightsBody> createState() => _InsightsBodyState();
}

class _InsightsBodyState extends State<_InsightsBody> {
  late String _selectedPeriodKey;

  @override
  void initState() {
    super.initState();
    _selectedPeriodKey = widget.insights.defaultPeriod.key;
  }

  @override
  void didUpdateWidget(covariant _InsightsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final exists = widget.insights.periodByKey(_selectedPeriodKey) != null;
    if (!exists) {
      _selectedPeriodKey = widget.insights.defaultPeriod.key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final period =
        widget.insights.periodByKey(_selectedPeriodKey) ??
        widget.insights.defaultPeriod;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SummaryHeroCard(period: period),
          const SizedBox(height: 24),
          _SectionLabel(
            title: 'Sales Performance',
            subtitle:
                'Product sales view for ${period.rangeLabel.toLowerCase()}',
          ),
          const SizedBox(height: 12),
          if (widget.insights.availablePeriods.length > 1) ...<Widget>[
            _PeriodFilter(
              periods: widget.insights.availablePeriods,
              selectedKey: period.key,
              onSelected: (key) {
                setState(() {
                  _selectedPeriodKey = key;
                });
              },
            ),
            const SizedBox(height: 12),
          ],
          _MetricGrid(metrics: period.metrics),
          const SizedBox(height: 12),
          _ProductSalesChartCard(period: period),
          const SizedBox(height: 28),
          _SectionLabel(
            title: 'Top Trending Products',
            subtitle:
                'Sorted by cases sold in ${period.rangeLabel.toLowerCase()}',
          ),
          const SizedBox(height: 12),
          if (period.products.isEmpty)
            const _EmptyCard(
              message: 'No product sales found for the selected time period.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: period.products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _TrendingProductCard(
                  rank: index + 1,
                  product: period.products[index],
                );
              },
            ),
          if (period.recommendations.isNotEmpty) ...<Widget>[
            const SizedBox(height: 28),
            const _SectionLabel(
              title: 'Personalized Recommendations',
              subtitle:
                  'Products worth watching based on recent demand signals',
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: period.recommendations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _RecommendationCard(
                  recommendation: period.recommendations[index],
                );
              },
            ),
          ],
          if (period.fastMoving.isNotEmpty ||
              period.slowMoving.isNotEmpty) ...<Widget>[
            const SizedBox(height: 28),
            const _SectionLabel(
              title: 'Inventory Movement',
              subtitle:
                  'Fast-moving and slow-moving products based on the selected period',
            ),
            const SizedBox(height: 12),
            _MovementSection(period: period),
          ],
          if (period.reorderSuggestions.isNotEmpty) ...<Widget>[
            const SizedBox(height: 28),
            const _SectionLabel(
              title: 'Smart Reorder Suggestions',
              subtitle: 'Suggested restocking actions using recent sales pace',
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: period.reorderSuggestions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _ReorderCard(
                  suggestion: period.reorderSuggestions[index],
                );
              },
            ),
          ],
          if (period.seasonalInsights.isNotEmpty) ...<Widget>[
            const SizedBox(height: 28),
            const _SectionLabel(
              title: 'Seasonal Demand Insights',
              subtitle: 'Signals from month-by-month movement patterns',
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: period.seasonalInsights.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _SeasonalInsightCard(
                  insight: period.seasonalInsights[index],
                );
              },
            ),
          ],
          if (period.stockRiskAlerts.isNotEmpty) ...<Widget>[
            const SizedBox(height: 28),
            const _SectionLabel(
              title: 'Stock Risk Alerts',
              subtitle: 'Frequently sold products that may need a stock check',
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: period.stockRiskAlerts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _RiskAlertCard(alert: period.stockRiskAlerts[index]);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryHeroCard extends StatelessWidget {
  const _SummaryHeroCard({required this.period});

  final InsightPeriod period;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFF5EA), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(120)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryBrownDark.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBrown.withAlpha(18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.primaryBrownDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Performance Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      period.rangeLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            period.summary.headline,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            period.summary.body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSoft,
              height: 1.45,
            ),
          ),
          if (period.summary.highlights.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            ...period.summary.highlights
                .take(3)
                .map(
                  (highlight) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: const BoxDecoration(
                            color: AppTheme.proceedOrderOlive,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            highlight,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _PeriodFilter extends StatelessWidget {
  const _PeriodFilter({
    required this.periods,
    required this.selectedKey,
    required this.onSelected,
  });

  final List<InsightPeriodOption> periods;
  final String selectedKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: periods.map((period) {
        final selected = period.key == selectedKey;
        return ChoiceChip(
          label: Text(period.label),
          selected: selected,
          showCheckmark: false,
          selectedColor: AppTheme.primaryBrown.withAlpha(20),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: selected ? AppTheme.primaryBrown : AppTheme.outlineWarm,
            width: selected ? 1.4 : 1,
          ),
          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected ? AppTheme.primaryBrownDark : AppTheme.textSoft,
            fontWeight: FontWeight.w700,
          ),
          onSelected: (_) => onSelected(period.key),
        );
      }).toList(),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final InsightMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final items = <_MetricItem>[
      _MetricItem(
        label: 'Revenue',
        value: _formatCurrency(metrics.totalRevenue),
        accent: AppTheme.primaryBrown,
      ),
      _MetricItem(
        label: 'Cases Sold',
        value: '${metrics.totalCases}',
        accent: AppTheme.addToCartClay,
      ),
      _MetricItem(
        label: 'Active SKUs',
        value: '${metrics.activeProducts}',
        accent: AppTheme.proceedOrderOlive,
      ),
      _MetricItem(
        label: 'Vs Previous',
        value: _formatGrowth(metrics.growthRate),
        accent: metrics.growthRate >= 0
            ? AppTheme.proceedOrderOlive
            : AppTheme.rejectOrderRed,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = max(0.0, (constraints.maxWidth - 12) / 2);
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: itemWidth,
              child: _MetricCard(item: item),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MetricItem {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(95)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 24,
            height: 4,
            decoration: BoxDecoration(
              color: item.accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSalesChartCard extends StatelessWidget {
  const _ProductSalesChartCard({required this.period});

  final InsightPeriod period;

  static const List<Color> _palette = <Color>[
    AppTheme.primaryBrown,
    AppTheme.addToCartClay,
    AppTheme.proceedOrderOlive,
    AppTheme.securitySlate,
    AppTheme.rejectOrderRed,
  ];

  @override
  Widget build(BuildContext context) {
    final products = period.products.take(5).toList();
    final maxCases = products.fold<int>(
      0,
      (best, product) => product.totalCases > best ? product.totalCases : best,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(95)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryBrownDark.withAlpha(8),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.bar_chart_rounded,
                color: AppTheme.primaryBrown,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cases sold by product',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'The chart now uses product case counts instead of large revenue totals.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSoft,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          if (products.isEmpty)
            const _EmptyCard(message: 'No product sales available to plot yet.')
          else
            Column(
              children: products.asMap().entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key == products.length - 1 ? 0 : 16,
                  ),
                  child: _ProductChartRow(
                    product: entry.value,
                    color: _palette[entry.key % _palette.length],
                    maxCases: maxCases,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _ProductChartRow extends StatelessWidget {
  const _ProductChartRow({
    required this.product,
    required this.color,
    required this.maxCases,
  });

  final PeriodProduct product;
  final Color color;
  final int maxCases;

  @override
  Widget build(BuildContext context) {
    final widthFactor = maxCases <= 0
        ? 0.0
        : max(0.08, product.totalCases / maxCases);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                product.productName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${product.totalCases} cases',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryBrownDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 14,
            color: AppTheme.surfaceTint,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widthFactor,
              child: Container(color: color),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _InfoChip(
              icon: _trendIcon(product.trendDirection),
              label: _trendLabel(product.trendDirection, product.changePercent),
              color: _trendColor(product.trendDirection),
            ),
            _InfoChip(
              icon: Icons.payments_outlined,
              label: _formatCurrency(product.totalRevenue),
            ),
            _InfoChip(
              icon: Icons.calendar_today_outlined,
              label: _formatDate(product.lastOrderDate),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrendingProductCard extends StatelessWidget {
  const _TrendingProductCard({required this.rank, required this.product});

  final int rank;
  final PeriodProduct product;

  @override
  Widget build(BuildContext context) {
    final highlighted = rank <= 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFF8F2) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlighted
              ? AppTheme.outlineWarm.withAlpha(150)
              : AppTheme.outlineWarm.withAlpha(95),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryBrownDark.withAlpha(8),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: highlighted ? AppTheme.primaryBrown : AppTheme.surfaceTint,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: highlighted ? Colors.white : AppTheme.primaryBrownDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  product.productName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: <Widget>[
                    _InfoChip(
                      icon: Icons.inventory_2_outlined,
                      label: '${product.totalCases} cases sold',
                    ),
                    _InfoChip(
                      icon: Icons.payments_outlined,
                      label: _formatCurrency(product.totalRevenue),
                    ),
                    _InfoChip(
                      icon: Icons.speed_rounded,
                      label: '${product.sellOutCasesPerMonth}/month',
                      color: _movementColor(product.movementType),
                    ),
                    _InfoChip(
                      icon: _trendIcon(product.trendDirection),
                      label: _trendLabel(
                        product.trendDirection,
                        product.changePercent,
                      ),
                      color: _trendColor(product.trendDirection),
                    ),
                    _InfoChip(
                      icon: Icons.local_shipping_outlined,
                      label: _movementLabel(product.movementType),
                      color: _movementColor(product.movementType),
                    ),
                    _InfoChip(
                      icon: Icons.calendar_today_outlined,
                      label: 'Last: ${_formatDate(product.lastOrderDate)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});

  final PeriodRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(95)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _trendColor(recommendation.trendDirection).withAlpha(20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _trendIcon(recommendation.trendDirection),
              color: _trendColor(recommendation.trendDirection),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  recommendation.productName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  recommendation.reason,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSoft,
                    height: 1.4,
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

class _MovementSection extends StatelessWidget {
  const _MovementSection({required this.period});

  final InsightPeriod period;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (period.fastMoving.isNotEmpty)
          _MovementGroupCard(
            title: 'Fast-moving products',
            subtitle: 'Products selling the quickest in this period',
            accent: AppTheme.proceedOrderOlive,
            products: period.fastMoving,
          ),
        if (period.fastMoving.isNotEmpty && period.slowMoving.isNotEmpty)
          const SizedBox(height: 12),
        if (period.slowMoving.isNotEmpty)
          _MovementGroupCard(
            title: 'Slow-moving products',
            subtitle: 'Products with lighter movement in this period',
            accent: AppTheme.rejectOrderRed,
            products: period.slowMoving,
          ),
      ],
    );
  }
}

class _MovementGroupCard extends StatelessWidget {
  const _MovementGroupCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.products,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final List<PeriodProduct> products;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(95)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSoft),
          ),
          const SizedBox(height: 14),
          ...products.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == products.length - 1 ? 0 : 14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          entry.value.productName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.value.totalCases} cases · ${_movementLabel(entry.value.movementType)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.textSoft,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 92,
                    child: _MiniMovementBars(
                      points: entry.value.monthlyPoints,
                      color: accent,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MiniMovementBars extends StatelessWidget {
  const _MiniMovementBars({required this.points, required this.color});

  final List<ProductMonthlyPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final visiblePoints = points.length > 6
        ? points.sublist(points.length - 6)
        : points;
    final maxValue = visiblePoints.fold<int>(
      0,
      (best, point) => point.cases > best ? point.cases : best,
    );

    return SizedBox(
      height: 42,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: visiblePoints.map((point) {
          final ratio = maxValue <= 0
              ? 0.12
              : max(0.12, point.cases / maxValue);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 34 * ratio,
                  decoration: BoxDecoration(
                    color: color.withAlpha(point.cases > 0 ? 220 : 70),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReorderCard extends StatelessWidget {
  const _ReorderCard({required this.suggestion});

  final ReorderSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _urgencyColor(suggestion.urgency).withAlpha(110),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  suggestion.productName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusBadge(
                label: _urgencyLabel(suggestion.urgency),
                color: _urgencyColor(suggestion.urgency),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              _InfoChip(
                icon: Icons.shopping_cart_checkout_rounded,
                label: 'Suggested: ${suggestion.suggestedCases} cases',
                color: _urgencyColor(suggestion.urgency),
              ),
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                label: _formatDate(suggestion.lastOrderDate),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            suggestion.reason,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSoft,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskAlertCard extends StatelessWidget {
  const _RiskAlertCard({required this.alert});

  final StockRiskAlert alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _riskColor(alert.severity).withAlpha(120)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _riskColor(alert.severity).withAlpha(20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: _riskColor(alert.severity),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        alert.productName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    _StatusBadge(
                      label: _riskLabel(alert.severity),
                      color: _riskColor(alert.severity),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  alert.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSoft,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: <Widget>[
                    _InfoChip(
                      icon: Icons.inventory_2_outlined,
                      label: '${alert.totalCases} cases',
                    ),
                    _InfoChip(
                      icon: Icons.calendar_today_outlined,
                      label: _formatDate(alert.lastOrderDate),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonalInsightCard extends StatelessWidget {
  const _SeasonalInsightCard({required this.insight});

  final SeasonalInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = _seasonalColor(insight.emphasis);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withAlpha(110)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.insights_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  insight.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  insight.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSoft,
                    height: 1.4,
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppTheme.textSoft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color != null ? accent.withAlpha(18) : AppTheme.surfaceTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color != null ? accent : AppTheme.textSoft,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSoft),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(110)),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF8B1A1A)),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

String _formatCurrency(num value) {
  final str = value.round().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < str.length; index++) {
    final reverseIndex = str.length - index;
    buffer.write(str[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return 'LKR ${buffer.toString()}';
}

String _formatDate(String raw) {
  if (raw.length < 10) return raw;
  final parts = raw.substring(0, 10).split('-');
  if (parts.length != 3) return raw;

  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final monthIndex = int.tryParse(parts[1]) ?? 1;
  return '${parts[2]} ${months[monthIndex - 1]} ${parts[0]}';
}

String _formatGrowth(int growthRate) {
  if (growthRate > 0) return '+$growthRate%';
  if (growthRate < 0) return '$growthRate%';
  return '0%';
}

String _trendLabel(String direction, int changePercent) {
  switch (direction) {
    case 'new':
      return 'New demand';
    case 'up':
      return 'Rising ${changePercent > 0 ? '+$changePercent%' : ''}'.trim();
    case 'down':
      return 'Cooling ${changePercent < 0 ? '$changePercent%' : ''}'.trim();
    default:
      return 'Steady';
  }
}

IconData _trendIcon(String direction) {
  switch (direction) {
    case 'new':
      return Icons.new_releases_rounded;
    case 'up':
      return Icons.trending_up_rounded;
    case 'down':
      return Icons.trending_down_rounded;
    default:
      return Icons.horizontal_rule_rounded;
  }
}

Color _trendColor(String direction) {
  switch (direction) {
    case 'new':
      return AppTheme.addToCartClay;
    case 'up':
      return AppTheme.proceedOrderOlive;
    case 'down':
      return AppTheme.rejectOrderRed;
    default:
      return AppTheme.securitySlate;
  }
}

String _movementLabel(String movementType) {
  switch (movementType) {
    case 'fast':
      return 'Fast-moving';
    case 'slow':
      return 'Slow-moving';
    default:
      return 'Steady movement';
  }
}

Color _movementColor(String movementType) {
  switch (movementType) {
    case 'fast':
      return AppTheme.proceedOrderOlive;
    case 'slow':
      return AppTheme.rejectOrderRed;
    default:
      return AppTheme.securitySlate;
  }
}

Color _urgencyColor(String urgency) {
  switch (urgency) {
    case 'high':
      return AppTheme.rejectOrderRed;
    case 'medium':
      return AppTheme.addToCartClay;
    case 'low':
      return AppTheme.proceedOrderOlive;
    default:
      return AppTheme.securitySlate;
  }
}

String _urgencyLabel(String urgency) {
  switch (urgency) {
    case 'high':
      return 'Reorder soon';
    case 'medium':
      return 'Plan reorder';
    case 'low':
      return 'Watch stock';
    default:
      return 'Stable';
  }
}

Color _riskColor(String severity) {
  switch (severity) {
    case 'high':
      return AppTheme.rejectOrderRed;
    case 'medium':
      return AppTheme.addToCartClay;
    default:
      return AppTheme.securitySlate;
  }
}

String _riskLabel(String severity) {
  switch (severity) {
    case 'high':
      return 'High risk';
    case 'medium':
      return 'Watch item';
    default:
      return 'Stable';
  }
}

Color _seasonalColor(String emphasis) {
  switch (emphasis) {
    case 'high':
      return AppTheme.proceedOrderOlive;
    case 'watch':
      return AppTheme.addToCartClay;
    default:
      return AppTheme.securitySlate;
  }
}
