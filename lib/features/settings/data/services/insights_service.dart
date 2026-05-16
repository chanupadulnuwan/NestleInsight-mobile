import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/network/network_error_helper.dart';

class InsightsServiceException implements Exception {
  const InsightsServiceException(this.message);

  final String message;
}

int _asInt(dynamic value) => (value as num?)?.round() ?? 0;

String _asString(dynamic value) => value as String? ?? '';

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }

  return value
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList();
}

class MonthlySale {
  const MonthlySale({
    required this.month,
    required this.actual,
    required this.estimated,
  });

  factory MonthlySale.fromJson(Map<String, dynamic> json) {
    return MonthlySale(
      month: _asString(json['month']),
      actual: _asInt(json['actual']),
      estimated: _asInt(json['estimated']),
    );
  }

  final String month;
  final int actual;
  final int estimated;
}

class TopProduct {
  const TopProduct({
    required this.productName,
    required this.totalCases,
    required this.totalRevenue,
    required this.sellOutCasesPerMonth,
    required this.lastOrderDate,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productName: _asString(json['productName']),
      totalCases: _asInt(json['totalCases']),
      totalRevenue: _asInt(json['totalRevenue']),
      sellOutCasesPerMonth: _asInt(json['sellOutCasesPerMonth']),
      lastOrderDate: _asString(json['lastOrderDate']),
    );
  }

  final String productName;
  final int totalCases;
  final int totalRevenue;
  final int sellOutCasesPerMonth;
  final String lastOrderDate;
}

class InsightPeriodOption {
  const InsightPeriodOption({
    required this.key,
    required this.label,
    required this.rangeLabel,
  });

  factory InsightPeriodOption.fromJson(Map<String, dynamic> json) {
    return InsightPeriodOption(
      key: _asString(json['key']),
      label: _asString(json['label']),
      rangeLabel: _asString(json['rangeLabel']),
    );
  }

  final String key;
  final String label;
  final String rangeLabel;
}

class InsightMetrics {
  const InsightMetrics({
    required this.totalRevenue,
    required this.totalCases,
    required this.totalOrders,
    required this.activeProducts,
    required this.averageOrderValue,
    required this.growthRate,
  });

  factory InsightMetrics.fromJson(Map<String, dynamic> json) {
    return InsightMetrics(
      totalRevenue: _asInt(json['totalRevenue']),
      totalCases: _asInt(json['totalCases']),
      totalOrders: _asInt(json['totalOrders']),
      activeProducts: _asInt(json['activeProducts']),
      averageOrderValue: _asInt(json['averageOrderValue']),
      growthRate: _asInt(json['growthRate']),
    );
  }

  final int totalRevenue;
  final int totalCases;
  final int totalOrders;
  final int activeProducts;
  final int averageOrderValue;
  final int growthRate;
}

class InsightSummary {
  const InsightSummary({
    required this.headline,
    required this.body,
    required this.highlights,
  });

  factory InsightSummary.fromJson(Map<String, dynamic> json) {
    final rawHighlights = json['highlights'];

    return InsightSummary(
      headline: _asString(json['headline']),
      body: _asString(json['body']),
      highlights: rawHighlights is List
          ? rawHighlights.whereType<String>().toList()
          : const <String>[],
    );
  }

  final String headline;
  final String body;
  final List<String> highlights;
}

class ProductMonthlyPoint {
  const ProductMonthlyPoint({
    required this.key,
    required this.label,
    required this.cases,
    required this.revenue,
  });

  factory ProductMonthlyPoint.fromJson(Map<String, dynamic> json) {
    return ProductMonthlyPoint(
      key: _asString(json['key']),
      label: _asString(json['label']),
      cases: _asInt(json['cases']),
      revenue: _asInt(json['revenue']),
    );
  }

  final String key;
  final String label;
  final int cases;
  final int revenue;
}

class PeriodProduct {
  const PeriodProduct({
    required this.productName,
    required this.totalCases,
    required this.totalRevenue,
    required this.sellOutCasesPerMonth,
    required this.lastOrderDate,
    required this.previousCases,
    required this.changePercent,
    required this.trendDirection,
    required this.movementType,
    required this.reorderUrgency,
    required this.reorderSuggestedCases,
    required this.reorderReason,
    required this.stockRiskLevel,
    required this.stockRiskReason,
    required this.daysSinceLastOrder,
    required this.lastOrderCases,
    required this.monthlyPoints,
  });

  factory PeriodProduct.fromJson(Map<String, dynamic> json) {
    return PeriodProduct(
      productName: _asString(json['productName']),
      totalCases: _asInt(json['totalCases']),
      totalRevenue: _asInt(json['totalRevenue']),
      sellOutCasesPerMonth: _asInt(json['sellOutCasesPerMonth']),
      lastOrderDate: _asString(json['lastOrderDate']),
      previousCases: _asInt(json['previousCases']),
      changePercent: _asInt(json['changePercent']),
      trendDirection: _asString(json['trendDirection']),
      movementType: _asString(json['movementType']),
      reorderUrgency: _asString(json['reorderUrgency']),
      reorderSuggestedCases: _asInt(json['reorderSuggestedCases']),
      reorderReason: _asString(json['reorderReason']),
      stockRiskLevel: _asString(json['stockRiskLevel']),
      stockRiskReason: _asString(json['stockRiskReason']),
      daysSinceLastOrder: _asInt(json['daysSinceLastOrder']),
      lastOrderCases: _asInt(json['lastOrderCases']),
      monthlyPoints: _asMapList(
        json['monthlyPoints'],
      ).map(ProductMonthlyPoint.fromJson).toList(),
    );
  }

  final String productName;
  final int totalCases;
  final int totalRevenue;
  final int sellOutCasesPerMonth;
  final String lastOrderDate;
  final int previousCases;
  final int changePercent;
  final String trendDirection;
  final String movementType;
  final String reorderUrgency;
  final int reorderSuggestedCases;
  final String reorderReason;
  final String stockRiskLevel;
  final String stockRiskReason;
  final int daysSinceLastOrder;
  final int lastOrderCases;
  final List<ProductMonthlyPoint> monthlyPoints;
}

class PeriodRecommendation {
  const PeriodRecommendation({
    required this.productName,
    required this.reason,
    required this.trendDirection,
    required this.totalCases,
    required this.totalRevenue,
  });

  factory PeriodRecommendation.fromJson(Map<String, dynamic> json) {
    return PeriodRecommendation(
      productName: _asString(json['productName']),
      reason: _asString(json['reason']),
      trendDirection: _asString(json['trendDirection']),
      totalCases: _asInt(json['totalCases']),
      totalRevenue: _asInt(json['totalRevenue']),
    );
  }

  final String productName;
  final String reason;
  final String trendDirection;
  final int totalCases;
  final int totalRevenue;
}

class ReorderSuggestion {
  const ReorderSuggestion({
    required this.productName,
    required this.urgency,
    required this.suggestedCases,
    required this.reason,
    required this.lastOrderDate,
  });

  factory ReorderSuggestion.fromJson(Map<String, dynamic> json) {
    return ReorderSuggestion(
      productName: _asString(json['productName']),
      urgency: _asString(json['urgency']),
      suggestedCases: _asInt(json['suggestedCases']),
      reason: _asString(json['reason']),
      lastOrderDate: _asString(json['lastOrderDate']),
    );
  }

  final String productName;
  final String urgency;
  final int suggestedCases;
  final String reason;
  final String lastOrderDate;
}

class StockRiskAlert {
  const StockRiskAlert({
    required this.productName,
    required this.severity,
    required this.message,
    required this.lastOrderDate,
    required this.totalCases,
  });

  factory StockRiskAlert.fromJson(Map<String, dynamic> json) {
    return StockRiskAlert(
      productName: _asString(json['productName']),
      severity: _asString(json['severity']),
      message: _asString(json['message']),
      lastOrderDate: _asString(json['lastOrderDate']),
      totalCases: _asInt(json['totalCases']),
    );
  }

  final String productName;
  final String severity;
  final String message;
  final String lastOrderDate;
  final int totalCases;
}

class SeasonalInsight {
  const SeasonalInsight({
    required this.title,
    required this.message,
    required this.emphasis,
  });

  factory SeasonalInsight.fromJson(Map<String, dynamic> json) {
    return SeasonalInsight(
      title: _asString(json['title']),
      message: _asString(json['message']),
      emphasis: _asString(json['emphasis']),
    );
  }

  final String title;
  final String message;
  final String emphasis;
}

class InsightPeriod {
  const InsightPeriod({
    required this.key,
    required this.label,
    required this.rangeLabel,
    required this.metrics,
    required this.summary,
    required this.products,
    required this.recommendations,
    required this.fastMoving,
    required this.slowMoving,
    required this.reorderSuggestions,
    required this.stockRiskAlerts,
    required this.seasonalInsights,
  });

  factory InsightPeriod.fromJson(Map<String, dynamic> json) {
    return InsightPeriod(
      key: _asString(json['key']),
      label: _asString(json['label']),
      rangeLabel: _asString(json['rangeLabel']),
      metrics: InsightMetrics.fromJson(
        json['metrics'] is Map<String, dynamic>
            ? json['metrics'] as Map<String, dynamic>
            : const <String, dynamic>{},
      ),
      summary: InsightSummary.fromJson(
        json['summary'] is Map<String, dynamic>
            ? json['summary'] as Map<String, dynamic>
            : const <String, dynamic>{},
      ),
      products: _asMapList(
        json['products'],
      ).map(PeriodProduct.fromJson).toList(),
      recommendations: _asMapList(
        json['recommendations'],
      ).map(PeriodRecommendation.fromJson).toList(),
      fastMoving: _asMapList(
        json['fastMoving'],
      ).map(PeriodProduct.fromJson).toList(),
      slowMoving: _asMapList(
        json['slowMoving'],
      ).map(PeriodProduct.fromJson).toList(),
      reorderSuggestions: _asMapList(
        json['reorderSuggestions'],
      ).map(ReorderSuggestion.fromJson).toList(),
      stockRiskAlerts: _asMapList(
        json['stockRiskAlerts'],
      ).map(StockRiskAlert.fromJson).toList(),
      seasonalInsights: _asMapList(
        json['seasonalInsights'],
      ).map(SeasonalInsight.fromJson).toList(),
    );
  }

  factory InsightPeriod.fromLegacy(
    List<MonthlySale> monthlySales,
    List<TopProduct> topProducts,
  ) {
    final totalRevenue = monthlySales.fold<int>(
      0,
      (sum, month) => sum + month.actual,
    );
    final totalCases = topProducts.fold<int>(
      0,
      (sum, product) => sum + product.totalCases,
    );

    final products = topProducts.asMap().entries.map((entry) {
      final index = entry.key;
      final product = entry.value;
      final movementType = index == 0
          ? 'fast'
          : index == topProducts.length - 1
          ? 'slow'
          : 'steady';

      return PeriodProduct(
        productName: product.productName,
        totalCases: product.totalCases,
        totalRevenue: product.totalRevenue,
        sellOutCasesPerMonth: product.sellOutCasesPerMonth,
        lastOrderDate: product.lastOrderDate,
        previousCases: 0,
        changePercent: 0,
        trendDirection: index == 0 ? 'up' : 'steady',
        movementType: movementType,
        reorderUrgency: index == 0 ? 'medium' : 'none',
        reorderSuggestedCases: product.sellOutCasesPerMonth,
        reorderReason: index == 0
            ? 'This product is one of the fastest movers in the available sales data.'
            : '',
        stockRiskLevel: index == 0 ? 'medium' : 'none',
        stockRiskReason: index == 0
            ? 'This product leads recent ordering, so it is worth checking stock levels.'
            : '',
        daysSinceLastOrder: 0,
        lastOrderCases: product.totalCases,
        monthlyPoints: monthlySales
            .map(
              (month) => ProductMonthlyPoint(
                key: month.month,
                label: month.month,
                cases: 0,
                revenue: 0,
              ),
            )
            .toList(),
      );
    }).toList();

    final recommendations = products.take(3).map((product) {
      return PeriodRecommendation(
        productName: product.productName,
        reason:
            '${product.productName} is among the strongest products in the currently available insight data.',
        trendDirection: product.trendDirection,
        totalCases: product.totalCases,
        totalRevenue: product.totalRevenue,
      );
    }).toList();

    final reorderSuggestions = products
        .where((product) => product.reorderUrgency != 'none')
        .take(2)
        .map(
          (product) => ReorderSuggestion(
            productName: product.productName,
            urgency: product.reorderUrgency,
            suggestedCases: product.reorderSuggestedCases,
            reason: product.reorderReason,
            lastOrderDate: product.lastOrderDate,
          ),
        )
        .toList();

    final stockRiskAlerts = products
        .where((product) => product.stockRiskLevel != 'none')
        .take(2)
        .map(
          (product) => StockRiskAlert(
            productName: product.productName,
            severity: product.stockRiskLevel,
            message: product.stockRiskReason,
            lastOrderDate: product.lastOrderDate,
            totalCases: product.totalCases,
          ),
        )
        .toList();

    return InsightPeriod(
      key: '180d',
      label: '6M',
      rangeLabel: 'Last 6 months',
      metrics: InsightMetrics(
        totalRevenue: totalRevenue,
        totalCases: totalCases,
        totalOrders: 0,
        activeProducts: topProducts.length,
        averageOrderValue: 0,
        growthRate: 0,
      ),
      summary: InsightSummary(
        headline: 'Available insight summary',
        body:
            'This view is built from the currently available top-product and monthly sales data. Product trends, reorder signals, and alerts are estimated until the richer insights payload is available.',
        highlights: recommendations.map((item) => item.reason).toList(),
      ),
      products: products,
      recommendations: recommendations,
      fastMoving: products
          .where((product) => product.movementType == 'fast')
          .toList(),
      slowMoving: products
          .where((product) => product.movementType == 'slow')
          .toList(),
      reorderSuggestions: reorderSuggestions,
      stockRiskAlerts: stockRiskAlerts,
      seasonalInsights: const <SeasonalInsight>[
        SeasonalInsight(
          title: 'Limited seasonal history',
          message:
              'Seasonal insight cards will improve once the API returns full period-by-period product history.',
          emphasis: 'steady',
        ),
      ],
    );
  }

  final String key;
  final String label;
  final String rangeLabel;
  final InsightMetrics metrics;
  final InsightSummary summary;
  final List<PeriodProduct> products;
  final List<PeriodRecommendation> recommendations;
  final List<PeriodProduct> fastMoving;
  final List<PeriodProduct> slowMoving;
  final List<ReorderSuggestion> reorderSuggestions;
  final List<StockRiskAlert> stockRiskAlerts;
  final List<SeasonalInsight> seasonalInsights;
}

class ShopInsights {
  const ShopInsights({
    required this.monthlySales,
    required this.topProducts,
    required this.availablePeriods,
    required this.periods,
    required this.generatedAt,
  });

  factory ShopInsights.fromJson(Map<String, dynamic> json) {
    final monthlySales = _asMapList(
      json['monthlySales'],
    ).map(MonthlySale.fromJson).toList();
    final topProducts = _asMapList(
      json['topProducts'],
    ).map(TopProduct.fromJson).toList();
    final periods = _asMapList(json['periods'])
        .map(InsightPeriod.fromJson)
        .where(
          (period) =>
              period.products.isNotEmpty || period.summary.body.isNotEmpty,
        )
        .toList();

    final availablePeriods = _asMapList(
      json['availablePeriods'],
    ).map(InsightPeriodOption.fromJson).toList();

    if (periods.isEmpty) {
      final legacyPeriod = InsightPeriod.fromLegacy(monthlySales, topProducts);
      return ShopInsights(
        monthlySales: monthlySales,
        topProducts: topProducts,
        availablePeriods: const <InsightPeriodOption>[
          InsightPeriodOption(
            key: '180d',
            label: '6M',
            rangeLabel: 'Last 6 months',
          ),
        ],
        periods: <InsightPeriod>[legacyPeriod],
        generatedAt: _asString(json['generatedAt']),
      );
    }

    return ShopInsights(
      monthlySales: monthlySales,
      topProducts: topProducts,
      availablePeriods: availablePeriods,
      periods: periods,
      generatedAt: _asString(json['generatedAt']),
    );
  }

  final List<MonthlySale> monthlySales;
  final List<TopProduct> topProducts;
  final List<InsightPeriodOption> availablePeriods;
  final List<InsightPeriod> periods;
  final String generatedAt;

  InsightPeriod get defaultPeriod {
    return periods.firstWhere(
      (period) => period.key == '180d',
      orElse: () => periods.first,
    );
  }

  InsightPeriod? periodByKey(String key) {
    for (final period in periods) {
      if (period.key == key) {
        return period;
      }
    }
    return null;
  }
}

class InsightsService {
  final _client = DioClient.instance;

  Future<ShopInsights> fetchMyInsights() async {
    try {
      final response = await _client.client.get<Map<String, dynamic>>(
        '/shop-insights/my',
      );
      final data = response.data;
      if (data == null) {
        throw const InsightsServiceException('Empty response from server.');
      }
      return ShopInsights.fromJson(data);
    } on DioException catch (e) {
      throw InsightsServiceException(
        extractBackendErrorMessage(
          e,
          fallbackMessage: 'Failed to load insights.',
        ),
      );
    }
  }
}
