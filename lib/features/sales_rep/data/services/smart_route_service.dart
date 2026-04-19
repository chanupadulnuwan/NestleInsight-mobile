import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class SmartRouteSession {
  final String id;
  final String userId;
  final String status;
  final DateTime routeDate;
  final int totalStops;
  final int pendingStops;
  final int inProgressStops;
  final int completedStops;
  final int skippedStops;
  final List<SmartRouteOutletSummary> assignedOutlets;

  SmartRouteSession({
    required this.id,
    required this.userId,
    required this.status,
    required this.routeDate,
    required this.totalStops,
    required this.pendingStops,
    required this.inProgressStops,
    required this.completedStops,
    required this.skippedStops,
    required this.assignedOutlets,
  });

  factory SmartRouteSession.fromJson(Map<String, dynamic> json) {
    return SmartRouteSession(
      id: json['id'],
      userId: json['userId'],
      status: json['status'],
      routeDate: DateTime.parse(json['routeDate']),
      totalStops: json['totalStops'] ?? 0,
      pendingStops: json['pendingStops'] ?? 0,
      inProgressStops: json['inProgressStops'] ?? 0,
      completedStops: json['completedStops'] ?? 0,
      skippedStops: json['skippedStops'] ?? 0,
      assignedOutlets: (json['assignedOutlets'] as List? ?? [])
          .map((e) => SmartRouteOutletSummary.fromJson(e))
          .toList(),
    );
  }
}

class SmartRouteOutletSummary {
  final String id;
  final String outletName;
  final String ownerName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int suggestedSeq;
  final String stopStatus;

  SmartRouteOutletSummary({
    required this.id,
    required this.outletName,
    required this.ownerName,
    this.address,
    this.latitude,
    this.longitude,
    required this.suggestedSeq,
    required this.stopStatus,
  });

  factory SmartRouteOutletSummary.fromJson(Map<String, dynamic> json) {
    return SmartRouteOutletSummary(
      id: json['id'],
      outletName: json['outletName'],
      ownerName: json['ownerName'],
      address: json['address'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      suggestedSeq: json['suggestedSeq'] ?? 0,
      stopStatus: json['stopStatus'] ?? 'pending',
    );
  }
}

class SmartRouteStop {
  final String id;
  final String routeSessionId;
  final String outletId;
  final int suggestedSeq;
  final String status;
  final String purpose;
  final String outletName;
  final String ownerName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? priorityScore;
  final String priorityBand;
  final double? distanceKm;
  final int? etaMinutes;
  final String recommendation;

  SmartRouteStop({
    required this.id,
    required this.routeSessionId,
    required this.outletId,
    required this.suggestedSeq,
    required this.status,
    required this.purpose,
    required this.outletName,
    required this.ownerName,
    this.address,
    this.latitude,
    this.longitude,
    this.priorityScore,
    required this.priorityBand,
    this.distanceKm,
    this.etaMinutes,
    required this.recommendation,
  });

  SmartRouteStop copyWith({
    String? id,
    String? routeSessionId,
    String? outletId,
    int? suggestedSeq,
    String? status,
    String? purpose,
    String? outletName,
    String? ownerName,
    String? address,
    double? latitude,
    double? longitude,
    double? priorityScore,
    String? priorityBand,
    double? distanceKm,
    int? etaMinutes,
    String? recommendation,
  }) {
    return SmartRouteStop(
      id: id ?? this.id,
      routeSessionId: routeSessionId ?? this.routeSessionId,
      outletId: outletId ?? this.outletId,
      suggestedSeq: suggestedSeq ?? this.suggestedSeq,
      status: status ?? this.status,
      purpose: purpose ?? this.purpose,
      outletName: outletName ?? this.outletName,
      ownerName: ownerName ?? this.ownerName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      priorityScore: priorityScore ?? this.priorityScore,
      priorityBand: priorityBand ?? this.priorityBand,
      distanceKm: distanceKm ?? this.distanceKm,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      recommendation: recommendation ?? this.recommendation,
    );
  }

  factory SmartRouteStop.fromJson(Map<String, dynamic> json) {
    return SmartRouteStop(
      id: json['id'],
      routeSessionId: json['routeSessionId'],
      outletId: json['outletId'],
      suggestedSeq: json['suggestedSeq'],
      status: json['status'],
      purpose: json['purpose'] ?? 'Visit',
      outletName: json['outletName'] ?? 'Unknown outlet',
      ownerName: json['ownerName'] ?? 'Owner not set',
      address: json['address'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      priorityScore: json['priorityScore']?.toDouble(),
      priorityBand: json['priorityBand'] ?? 'Standard',
      distanceKm: json['distanceKm']?.toDouble(),
      etaMinutes: json['etaMinutes'],
      recommendation: json['recommendation'] ?? 'follow-sequence',
    );
  }
}

class SmartRouteProgress {
  final String sessionId;
  final int totalStops;
  final int pendingStops;
  final int inProgressStops;
  final int completedStops;
  final int skippedStops;
  final int currentStopNumber;

  SmartRouteProgress({
    required this.sessionId,
    required this.totalStops,
    required this.pendingStops,
    required this.inProgressStops,
    required this.completedStops,
    required this.skippedStops,
    required this.currentStopNumber,
  });

  factory SmartRouteProgress.fromJson(Map<String, dynamic> json) {
    return SmartRouteProgress(
      sessionId: json['sessionId'],
      totalStops: json['totalStops'] ?? 0,
      pendingStops: json['pendingStops'] ?? 0,
      inProgressStops: json['inProgressStops'] ?? 0,
      completedStops: json['completedStops'] ?? 0,
      skippedStops: json['skippedStops'] ?? 0,
      currentStopNumber: json['currentStopNumber'] ?? 0,
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

  Future<SmartRouteProgress> getProgress({required String sessionId}) async {
    try {
      final response = await _dio.get('/smart-route/progress', queryParameters: {'sessionId': sessionId});
      return SmartRouteProgress.fromJson(response.data);
    } on DioException catch (e) {
      throw SmartRouteServiceException(
        e.response?.data?['message'] ?? e.message ?? 'Unknown error fetching progress',
      );
    }
  }

  Future<SmartRouteStop?> getNextStop({required String sessionId, double? lat, double? lng}) async {
    try {
      final response = await _dio.get('/smart-route/next-stop', queryParameters: {
        'sessionId': sessionId,
        // ignore: use_null_aware_elements
        if (lat != null) 'lat': lat,
        // ignore: use_null_aware_elements
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
        // ignore: use_null_aware_elements
        if (lat != null) 'lat': lat,
        // ignore: use_null_aware_elements
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
