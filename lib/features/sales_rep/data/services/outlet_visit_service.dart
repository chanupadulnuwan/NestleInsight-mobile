import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class TerritoryOutlet {
  final String id;
  final String outletName;
  final String ownerName;
  final String? address;
  final double? latitude;
  final double? longitude;

  TerritoryOutlet({
    required this.id,
    required this.outletName,
    required this.ownerName,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory TerritoryOutlet.fromJson(Map<String, dynamic> json) {
    return TerritoryOutlet(
      id: json['id'],
      outletName: json['outletName'],
      ownerName: json['ownerName'],
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }
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
      
      // Backend returns either the array directly or wrapped in standard NestJS response
      final List list = data is List ? data : (data['data'] ?? []);
      
      return list.map((json) => TerritoryOutlet.fromJson(json)).toList();
    } on DioException catch (e) {
      throw OutletVisitServiceException(
        e.response?.data?['message'] ?? e.message ?? 'Unknown error fetching outlets',
      );
    } catch (e) {
      throw OutletVisitServiceException('Failed to process outlets data: $e');
    }
  }
}
