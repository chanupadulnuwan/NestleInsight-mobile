import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class TerritoryOutlet {
  final String id;
  final String outletName;
  final String ownerName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isBeatPlanOutlet;
  final bool hasPendingDelivery;
  final int pendingDeliveryCount;
  final List<String> pendingDeliveryOrderIds;

  const TerritoryOutlet({
    required this.id,
    required this.outletName,
    required this.ownerName,
    this.address,
    this.latitude,
    this.longitude,
    this.isBeatPlanOutlet = false,
    this.hasPendingDelivery = false,
    this.pendingDeliveryCount = 0,
    this.pendingDeliveryOrderIds = const [],
  });

  TerritoryOutlet copyWith({
    String? outletName,
    String? ownerName,
    String? address,
    double? latitude,
    double? longitude,
    bool? isBeatPlanOutlet,
    bool? hasPendingDelivery,
    int? pendingDeliveryCount,
    List<String>? pendingDeliveryOrderIds,
  }) {
    return TerritoryOutlet(
      id: id,
      outletName: outletName ?? this.outletName,
      ownerName: ownerName ?? this.ownerName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isBeatPlanOutlet: isBeatPlanOutlet ?? this.isBeatPlanOutlet,
      hasPendingDelivery: hasPendingDelivery ?? this.hasPendingDelivery,
      pendingDeliveryCount: pendingDeliveryCount ?? this.pendingDeliveryCount,
      pendingDeliveryOrderIds:
          pendingDeliveryOrderIds ?? this.pendingDeliveryOrderIds,
    );
  }

  factory TerritoryOutlet.fromJson(Map<String, dynamic> json) {
    return TerritoryOutlet(
      id: (json['id'] ?? '').toString(),
      outletName: (json['outletName'] ?? '').toString(),
      ownerName: (json['ownerName'] ?? '').toString(),
      address: json['address']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isBeatPlanOutlet: json['isBeatPlanOutlet'] == true,
      hasPendingDelivery: json['hasPendingDelivery'] == true,
      pendingDeliveryCount: json['pendingDeliveryCount'] is num
          ? (json['pendingDeliveryCount'] as num).toInt()
          : 0,
      pendingDeliveryOrderIds:
          (json['pendingDeliveryOrderIds'] as List?)
              ?.map((item) => item?.toString())
              .whereType<String>()
              .where((item) => item.isNotEmpty)
              .toList() ??
          const [],
    );
  }
}

class OutletContext {
  final DateTime? lastVisitDate;
  final int orderCountSinceLastVisit;
  final List<Map<String, dynamic>> recentOrders;
  final Map<String, int> productQuantities;

  const OutletContext({
    this.lastVisitDate,
    required this.orderCountSinceLastVisit,
    required this.recentOrders,
    required this.productQuantities,
  });

  factory OutletContext.fromJson(Map<String, dynamic> json) {
    final rawQty = json['productQuantities'] as Map<String, dynamic>? ?? {};
    final rawOrders = json['recentOrders'] as List<dynamic>? ?? [];
    return OutletContext(
      lastVisitDate: json['lastVisitDate'] != null
          ? DateTime.tryParse(json['lastVisitDate'])
          : null,
      orderCountSinceLastVisit: json['orderCountSinceLastVisit'] ?? 0,
      recentOrders: rawOrders
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      productQuantities: rawQty.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }

  static OutletContext empty() => const OutletContext(
    orderCountSinceLastVisit: 0,
    recentOrders: [],
    productQuantities: {},
  );
}

class OutletVisitServiceException implements Exception {
  final String message;
  OutletVisitServiceException(this.message);

  @override
  String toString() => 'OutletVisitServiceException: $message';
}

class OutletVisitService {
  final Dio _dio = DioClient.instance.client;

  Future<List<TerritoryOutlet>> fetchMyOutlets() async {
    try {
      final response = await _dio.get('/outlets/my-territory');
      final data = response.data;
      final List list = data is List ? data : (data['data'] ?? []);
      return list.map((json) => TerritoryOutlet.fromJson(json)).toList();
    } on DioException catch (e) {
      throw OutletVisitServiceException(
        e.response?.data?['message'] ??
            e.message ??
            'Unknown error fetching outlets',
      );
    } catch (e) {
      throw OutletVisitServiceException('Failed to process outlets data: $e');
    }
  }

  Future<OutletContext> getOutletContext(String outletId) async {
    try {
      final response = await _dio.get('/store-visits/outlet-context/$outletId');
      return OutletContext.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      // Non-fatal — return empty context so visit can still proceed
      return OutletContext.empty();
    } catch (_) {
      return OutletContext.empty();
    }
  }
}
