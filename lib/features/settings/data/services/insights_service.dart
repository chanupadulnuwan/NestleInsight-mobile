import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/network/network_error_helper.dart';

class InsightsServiceException implements Exception {
  const InsightsServiceException(this.message);
  final String message;
}

class MonthlySale {
  const MonthlySale({
    required this.month,
    required this.actual,
    required this.estimated,
  });

  factory MonthlySale.fromJson(Map<String, dynamic> json) {
    return MonthlySale(
      month: json['month'] as String? ?? '',
      actual: (json['actual'] as num?)?.toInt() ?? 0,
      estimated: (json['estimated'] as num?)?.toInt() ?? 0,
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
      productName: json['productName'] as String? ?? '',
      totalCases: (json['totalCases'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toInt() ?? 0,
      sellOutCasesPerMonth: (json['sellOutCasesPerMonth'] as num?)?.toInt() ?? 0,
      lastOrderDate: json['lastOrderDate'] as String? ?? '',
    );
  }

  final String productName;
  final int totalCases;
  final int totalRevenue;
  final int sellOutCasesPerMonth;
  final String lastOrderDate;
}

class ShopInsights {
  const ShopInsights({
    required this.monthlySales,
    required this.topProducts,
  });

  factory ShopInsights.fromJson(Map<String, dynamic> json) {
    final rawSales = json['monthlySales'];
    final rawProducts = json['topProducts'];

    return ShopInsights(
      monthlySales: rawSales is List
          ? rawSales
                .whereType<Map>()
                .map((e) => MonthlySale.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      topProducts: rawProducts is List
          ? rawProducts
                .whereType<Map>()
                .map((e) => TopProduct.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }

  final List<MonthlySale> monthlySales;
  final List<TopProduct> topProducts;
}

class InsightsService {
  final _client = DioClient.instance;

  Future<ShopInsights> fetchMyInsights() async {
    try {
      final response = await _client.client.get<Map<String, dynamic>>('/shop-insights/my');
      final data = response.data;
      if (data == null) throw const InsightsServiceException('Empty response from server.');
      return ShopInsights.fromJson(data);
    } on DioException catch (e) {
      throw InsightsServiceException(
        extractBackendErrorMessage(e, fallbackMessage: 'Failed to load insights.'),
      );
    }
  }
}
