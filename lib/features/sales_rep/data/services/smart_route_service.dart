import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

class SmartRouteSession {
  SmartRouteSession({
    required this.id,
    required this.userId,
    required this.status,
    required this.routeDate,
    this.startTime,
    this.endTime,
    required this.totalStops,
    required this.pendingStops,
    required this.inProgressStops,
    required this.completedStops,
    required this.skippedStops,
    required this.assignedOutlets,
  });

  factory SmartRouteSession.fromJson(Map<String, dynamic> json) {
    final rawAssignedOutlets = json['assignedOutlets'];
    return SmartRouteSession(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      routeDate:
          DateTime.tryParse(json['routeDate']?.toString() ?? '') ??
          DateTime.now(),
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? ''),
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? ''),
      totalStops: (json['totalStops'] as num?)?.toInt() ?? 0,
      pendingStops: (json['pendingStops'] as num?)?.toInt() ?? 0,
      inProgressStops: (json['inProgressStops'] as num?)?.toInt() ?? 0,
      completedStops: (json['completedStops'] as num?)?.toInt() ?? 0,
      skippedStops: (json['skippedStops'] as num?)?.toInt() ?? 0,
      assignedOutlets: rawAssignedOutlets is List
          ? rawAssignedOutlets
                .whereType<Map>()
                .map(
                  (item) => SmartRouteOutletSummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const <SmartRouteOutletSummary>[],
    );
  }

  final String id;
  final String userId;
  final String status;
  final DateTime routeDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final int totalStops;
  final int pendingStops;
  final int inProgressStops;
  final int completedStops;
  final int skippedStops;
  final List<SmartRouteOutletSummary> assignedOutlets;
}

class SmartRouteOutletSummary {
  const SmartRouteOutletSummary({
    required this.id,
    required this.outletName,
    required this.ownerName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.suggestedSeq,
    required this.stopStatus,
  });

  factory SmartRouteOutletSummary.fromJson(Map<String, dynamic> json) {
    return SmartRouteOutletSummary(
      id: json['id']?.toString() ?? '',
      outletName: json['outletName']?.toString() ?? 'Unknown outlet',
      ownerName: json['ownerName']?.toString() ?? 'Owner not set',
      address: json['address']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      suggestedSeq: (json['suggestedSeq'] as num?)?.toInt() ?? 0,
      stopStatus: json['stopStatus']?.toString() ?? 'pending',
    );
  }

  final String id;
  final String outletName;
  final String ownerName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int suggestedSeq;
  final String stopStatus;
}

class SmartRouteStop {
  SmartRouteStop({
    required this.id,
    required this.routeSessionId,
    required this.outletId,
    required this.outletName,
    required this.ownerName,
    this.address,
    this.latitude,
    this.longitude,
    required this.suggestedSeq,
    this.actualSeq,
    required this.purpose,
    required this.status,
    this.priorityScore,
    required this.priorityBand,
    this.distanceKm,
    this.etaMinutes,
    required this.recommendation,
  });

  factory SmartRouteStop.fromJson(Map<String, dynamic> json) {
    return SmartRouteStop(
      id: json['id']?.toString() ?? '',
      routeSessionId: json['routeSessionId']?.toString() ?? '',
      outletId: json['outletId']?.toString() ?? '',
      outletName: json['outletName']?.toString() ?? 'Unknown outlet',
      ownerName: json['ownerName']?.toString() ?? 'Owner not set',
      address: json['address']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      suggestedSeq: (json['suggestedSeq'] as num?)?.toInt() ?? 0,
      actualSeq: (json['actualSeq'] as num?)?.toInt(),
      purpose: json['purpose']?.toString() ?? 'Visit',
      status: json['status']?.toString() ?? 'pending',
      priorityScore: (json['priorityScore'] as num?)?.toDouble(),
      priorityBand: json['priorityBand']?.toString() ?? 'Standard',
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      etaMinutes: (json['etaMinutes'] as num?)?.toInt(),
      recommendation:
          json['recommendation']?.toString() ?? 'follow-sequence',
    );
  }

  final String id;
  final String routeSessionId;
  final String outletId;
  final String outletName;
  final String ownerName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int suggestedSeq;
  final int? actualSeq;
  final String purpose;
  final String status;
  final double? priorityScore;
  final String priorityBand;
  final double? distanceKm;
  final int? etaMinutes;
  final String recommendation;
}

class SmartRouteProgress {
  const SmartRouteProgress({
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
      sessionId: json['sessionId']?.toString() ?? '',
      totalStops: (json['totalStops'] as num?)?.toInt() ?? 0,
      pendingStops: (json['pendingStops'] as num?)?.toInt() ?? 0,
      inProgressStops: (json['inProgressStops'] as num?)?.toInt() ?? 0,
      completedStops: (json['completedStops'] as num?)?.toInt() ?? 0,
      skippedStops: (json['skippedStops'] as num?)?.toInt() ?? 0,
      currentStopNumber: (json['currentStopNumber'] as num?)?.toInt() ?? 0,
    );
  }

  final String sessionId;
  final int totalStops;
  final int pendingStops;
  final int inProgressStops;
  final int completedStops;
  final int skippedStops;
  final int currentStopNumber;
}

class SmartRouteServiceException implements Exception {
  SmartRouteServiceException(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() => 'SmartRouteServiceException: $message';
}

class SmartRouteService {
  final Dio _dio = DioClient.instance.client;

  Future<SmartRouteSession> getOrCreateSession() async {
    try {
      final response = await _dio.get('/smart-route/session');
      return SmartRouteSession.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw SmartRouteServiceException(
        e.response?.data?['message'] ??
            e.message ??
            'Unknown error fetching session',
      );
    }
  }

  Future<SmartRouteProgress> getProgress({required String sessionId}) async {
    try {
      final response = await _dio.get(
        '/smart-route/progress',
        queryParameters: {'sessionId': sessionId},
      );
      return SmartRouteProgress.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw SmartRouteServiceException(
        e.response?.data?['message'] ??
            e.message ??
            'Unknown error fetching progress',
      );
    }
  }

  Future<SmartRouteStop?> getNextStop({
    required String sessionId,
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await _dio.get(
        '/smart-route/next-stop',
        queryParameters: {
          'sessionId': sessionId,
          'lat': ?lat,
          'lng': ?lng,
        },
      );
      if (response.statusCode == 204 ||
          response.data == null ||
          response.data == '') {
        return null;
      }
      return SmartRouteStop.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw SmartRouteServiceException(
        e.response?.data?['message'] ??
            e.message ??
            'Unknown error fetching next stop',
      );
    }
  }

  Future<SmartRouteStop> startStop({required String stopId}) async {
    try {
      final response = await _dio.post(
        '/smart-route/start',
        data: {'stopId': stopId},
      );
      return SmartRouteStop.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw SmartRouteServiceException(
        e.response?.data?['message'] ??
            e.message ??
            'Unknown error starting stop',
      );
    }
  }

  Future<SmartRouteStop> completeStop({required String stopId}) async {
    try {
      final response = await _dio.post(
        '/smart-route/complete',
        data: {'stopId': stopId},
      );
      return SmartRouteStop.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw SmartRouteServiceException(
        e.response?.data?['message'] ??
            e.message ??
            'Unknown error completing stop',
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
      final response = await _dio.post(
        '/smart-route/skip',
        data: {
          'stopId': stopId,
          'reasonCode': reasonCode,
          'freeText': freeText,
          'lat': ?lat,
          'lng': ?lng,
        },
      );
      if (response.statusCode == 204 ||
          response.data == null ||
          response.data == '') {
        return null;
      }
      return SmartRouteStop.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw SmartRouteServiceException(
        e.response?.data?['message'] ??
            e.message ??
            'Unknown error skipping stop',
      );
    }
  }
}
