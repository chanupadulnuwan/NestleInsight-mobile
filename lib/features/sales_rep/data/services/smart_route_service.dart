import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class SmartRouteSession {
  final String id;
  final String userId;
  final String status;
  final DateTime routeDate;

  SmartRouteSession({
    required this.id,
    required this.userId,
    required this.status,
    required this.routeDate,
  });

  factory SmartRouteSession.fromJson(Map<String, dynamic> json) {
    return SmartRouteSession(
      id: json['id'],
      userId: json['userId'],
      status: json['status'],
      routeDate: DateTime.parse(json['routeDate']),
    );
  }
}

class SmartRouteStop {
  final String id;
  final String routeSessionId;
  final String outletId;
  final int suggestedSeq;
  final String purpose;
  final String status;
  final double? priorityScore;
  final double? distanceKm;
  final int? etaMinutes;

  SmartRouteStop({
    required this.id,
    required this.routeSessionId,
    required this.outletId,
    required this.suggestedSeq,
    required this.purpose,
    required this.status,
    this.priorityScore,
    this.distanceKm,
    this.etaMinutes,
  });

  factory SmartRouteStop.fromJson(Map<String, dynamic> json) {
    return SmartRouteStop(
      id: json['id'],
      routeSessionId: json['routeSessionId'],
      outletId: json['outletId'],
      suggestedSeq: json['suggestedSeq'],
      purpose: json['purpose'],
      status: json['status'],
      priorityScore: json['priorityScore']?.toDouble(),
      distanceKm: json['distanceKm']?.toDouble(),
      etaMinutes: json['etaMinutes'],
    );
  }
}

class SmartRouteServiceException implements Exception {
  final String message;
  final String? code;
  SmartRouteServiceException(this.message, [this.code]);
  @override
  String toString() => 'SmartRouteServiceException: $message';
}

class SmartRouteService {
  final Dio _dio = DioClient.instance.client;

  Future<SmartRouteSession> getOrCreateSession() async {
    try {
      final response = await _dio.get('/smart-route/session');
      return SmartRouteSession.fromJson(response.data);
    } on DioException catch (e) {
      throw SmartRouteServiceException(
        e.response?.data?['message'] ?? e.message ?? 'Unknown error fetching session',
      );
    }
  }

  Future<SmartRouteStop?> getNextStop({required String sessionId, double? lat, double? lng}) async {
    try {
      final response = await _dio.get('/smart-route/next-stop', queryParameters: {
        'sessionId': sessionId,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      });
      if (response.statusCode == 204 || response.data == null || response.data == '') return null;
      return SmartRouteStop.fromJson(response.data);
    } on DioException catch (e) {
      throw SmartRouteServiceException(
        e.response?.data?['message'] ?? e.message ?? 'Unknown error fetching next stop',
      );
    }
  }

  Future<SmartRouteStop> startStop({required String stopId}) async {
    try {
      final response = await _dio.post('/smart-route/start', data: {'stopId': stopId});
      return SmartRouteStop.fromJson(response.data);
    } on DioException catch (e) {
      throw SmartRouteServiceException(
        e.response?.data?['message'] ?? e.message ?? 'Unknown error starting stop',
      );
    }
  }

  Future<SmartRouteStop> completeStop({required String stopId}) async {
    try {
      final response = await _dio.post('/smart-route/complete', data: {'stopId': stopId});
      return SmartRouteStop.fromJson(response.data);
    } on DioException catch (e) {
      throw SmartRouteServiceException(
        e.response?.data?['message'] ?? e.message ?? 'Unknown error completing stop',
      );
    }
  }

  Future<SmartRouteStop?> skipStop({
    required String stopId,
    required String reasonCode,
    required String freeText,
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await _dio.post('/smart-route/skip', data: {
        'stopId': stopId,
        'reasonCode': reasonCode,
        'freeText': freeText,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      });
      if (response.statusCode == 204 || response.data == null || response.data == '') return null;
      return SmartRouteStop.fromJson(response.data);
    } on DioException catch (e) {
      throw SmartRouteServiceException(
        e.response?.data?['message'] ?? e.message ?? 'Unknown error skipping stop',
      );
    }
  }
}
