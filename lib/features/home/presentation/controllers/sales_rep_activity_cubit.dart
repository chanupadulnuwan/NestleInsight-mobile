import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/dio_client.dart';
import '../../../activity/domain/activity_entry.dart';

abstract class SalesRepActivityState {}

class SalesRepActivityInitial extends SalesRepActivityState {}

class SalesRepActivityLoading extends SalesRepActivityState {}

class SalesRepActivityLoaded extends SalesRepActivityState {
  final List<ActivityEntry> activities;
  final bool isRefreshing;

  SalesRepActivityLoaded({
    required this.activities,
    this.isRefreshing = false,
  });
}

class SalesRepActivityError extends SalesRepActivityState {
  final String message;
  SalesRepActivityError(this.message);
}

class SalesRepActivityCubit extends Cubit<SalesRepActivityState> {
  SalesRepActivityCubit() : super(SalesRepActivityInitial());

  Timer? _pollingTimer;

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      fetchActivities(isPolling: true);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> fetchActivities({bool isPolling = false, bool isManualRefresh = false}) async {
    if (state is SalesRepActivityLoading && !isPolling && !isManualRefresh) return;

    if (isManualRefresh && state is SalesRepActivityLoaded) {
      emit(SalesRepActivityLoaded(
        activities: (state as SalesRepActivityLoaded).activities,
        isRefreshing: true,
      ));
    } else if (!isPolling) {
      emit(SalesRepActivityLoading());
    }

    try {
      final dio = DioClient.instance.client;
      final response = await dio.get('/activities/my');
      
      // The Backend returns { message: '...', activities: [...] }
      final List rawList = response.data['activities'] ?? [];
      final activities = rawList
          .map((json) => ActivityEntry.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      emit(SalesRepActivityLoaded(activities: activities));
    } catch (e) {
      if (!isPolling) {
        emit(SalesRepActivityError(e.toString()));
      }
    }
  }

  @override
  Future<void> close() {
    stopPolling();
    return super.close();
  }
}
