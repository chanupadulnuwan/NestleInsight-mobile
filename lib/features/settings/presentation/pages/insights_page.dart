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

// ── Body ──────────────────────────────────────────────────────────────────────

class _InsightsBody extends StatelessWidget {
  const _InsightsBody({required this.insights});

  final ShopInsights insights;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Sales performance chart card
          _SectionLabel(
            title: 'Sales Performance',
            subtitle: 'Last 6 months · Dashed line shows average target',
          ),
          const SizedBox(height: 12),
          _ChartCard(monthlySales: insights.monthlySales),
          const SizedBox(height: 28),
          // Top products
          _SectionLabel(
            title: 'Top Trending Products',
            subtitle: 'Ranked by total cases ordered in the last 6 months',
          ),
          const SizedBox(height: 12),
          if (insights.topProducts.isEmpty)
            const _EmptyCard(message: 'No orders found in the last 6 months.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: insights.topProducts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _ProductCard(
                  rank: index + 1,
                  product: insights.topProducts[index],
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSoft,
          ),
        ),
      ],
    );
  }
}

// ── Chart card ────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.monthlySales});

  final List<MonthlySale> monthlySales;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(90)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryBrownDark.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Legend
          Row(
            children: <Widget>[
              _LegendDot(color: AppTheme.primaryBrown),
              const SizedBox(width: 6),
              Text(
                'Actual sales',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              _LegendDot(color: const Color(0xFF9B4B46), isDashed: true),
              const SizedBox(width: 6),
              Text(
                'Average target',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (monthlySales.isEmpty)
            const _EmptyCard(message: 'No sales data yet.')
          else
            _BarChart(monthlySales: monthlySales),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, this.isDashed = false});

  final Color color;
  final bool isDashed;

  @override
  Widget build(BuildContext context) {
    if (isDashed) {
      return SizedBox(
        width: 20,
        height: 3,
        child: CustomPaint(painter: _DashedLinePainter(color: color)),
      );
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  const _BarChart({required this.monthlySales});

  final List<MonthlySale> monthlySales;

  static const double _chartHeight = 160.0;

  @override
  Widget build(BuildContext context) {
    final maxActual = monthlySales.map((m) => m.actual).reduce(max).toDouble();
    final estimated = monthlySales.first.estimated.toDouble();
    final safeMax = max(maxActual, estimated) * 1.1; // 10% headroom

    final estimatedFraction = safeMax > 0 ? estimated / safeMax : 0.0;

    return Column(
      children: <Widget>[
        SizedBox(
          height: _chartHeight,
          child: Stack(
            children: <Widget>[
              // Bars
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: monthlySales.map((sale) {
                  final fraction = safeMax > 0 ? sale.actual / safeMax : 0.0;
                  final barH = fraction * _chartHeight;
                  final isAboveTarget = sale.actual >= sale.estimated;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          // Value label
                          if (sale.actual > 0)
                            Text(
                              _shortAmount(sale.actual),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isAboveTarget
                                    ? AppTheme.primaryBrownDark
                                    : AppTheme.textSoft,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                            ),
                          const SizedBox(height: 3),
                          // Bar
                          Container(
                            height: barH > 0 ? barH : 3,
                            decoration: BoxDecoration(
                              color: isAboveTarget
                                  ? AppTheme.primaryBrown
                                  : AppTheme.primaryBrown.withAlpha(100),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Estimated dashed line
              Positioned(
                left: 0,
                right: 0,
                bottom: estimatedFraction * _chartHeight,
                child: CustomPaint(
                  size: const Size(double.infinity, 1),
                  painter: _DashedLinePainter(color: const Color(0xFF9B4B46)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Month labels
        Row(
          children: monthlySales.map((sale) {
            return Expanded(
              child: Text(
                sale.month,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSoft,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _shortAmount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toString();
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

// ── Product card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.rank, required this.product});

  final int rank;
  final TopProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTopTwo = rank <= 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTopTwo ? const Color(0xFFFFF8F2) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTopTwo
              ? AppTheme.outlineWarm.withAlpha(160)
              : AppTheme.outlineWarm.withAlpha(90),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryBrownDark.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isTopTwo ? AppTheme.primaryBrown : AppTheme.surfaceTint,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: theme.textTheme.titleSmall?.copyWith(
                color: isTopTwo ? Colors.white : AppTheme.primaryBrownDark,
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                // Stats row
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: <Widget>[
                    _StatChip(
                      icon: Icons.inventory_2_outlined,
                      label: '${product.totalCases} cases ordered',
                    ),
                    _StatChip(
                      icon: Icons.payments_outlined,
                      label: _formatCurrency(product.totalRevenue),
                    ),
                    _StatChip(
                      icon: Icons.speed_outlined,
                      label: '~${product.sellOutCasesPerMonth} cases/month',
                      highlight: true,
                    ),
                    _StatChip(
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

  String _formatCurrency(int value) {
    final buffer = StringBuffer();
    final str = value.toString();
    for (var i = 0; i < str.length; i++) {
      final reverseIndex = str.length - i;
      buffer.write(str[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write(',');
    }
    return 'LKR ${buffer.toString()}';
  }

  String _formatDate(String raw) {
    if (raw.length < 10) return raw;
    final parts = raw.substring(0, 10).split('-');
    if (parts.length != 3) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = int.tryParse(parts[1]) ?? 1;
    return '${parts[2]} ${months[month - 1]} ${parts[0]}';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, this.highlight = false});

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.primaryBrown.withAlpha(20) : AppTheme.surfaceTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 13,
            color: highlight ? AppTheme.primaryBrown : AppTheme.textSoft,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: highlight ? AppTheme.primaryBrownDark : AppTheme.textSoft,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(110)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSoft,
        ),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF8B1A1A),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
