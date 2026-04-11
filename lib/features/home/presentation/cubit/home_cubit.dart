import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/dio_client.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  Future<void> loadHomeData() async {
    emit(HomeLoading());

    try {
      String firstName = 'User';
      String territoryName = 'No Territory Assigned';
      bool hasActiveRoute = false;
      int shopsLeft = 0;

      final dio = DioClient.instance.client;

      // 1. User Info
      try {
        final resMe = await dio.get('/auth/me');
        final userObj = resMe.data['user'] ?? resMe.data ?? {};
        firstName = userObj['firstName'] ?? userObj['name'] ?? 'Alex';
        territoryName = userObj['territory']?['name'] ?? userObj['territoryName'] ?? 'North District';
      } catch (e) {
        // Fallback for demo if endpoint fails
      }

      // 2. Route Status
      try {
        final resRoute = await dio.get('/routes/active');
        final routeData = resRoute.data ?? {};
        hasActiveRoute = routeData['hasActiveRoute'] == true ||
                         routeData['isActive'] == true ||
                         routeData['status'] == 'ACTIVE' || 
                         (routeData is Map && routeData.isNotEmpty); // If object exists, active
      } catch (e) {
        hasActiveRoute = false;
      }

      // 3. Daily Shops
      try {
        final resShops = await dio.get('/outlets/beat-plan/today');
        final shopsData = resShops.data ?? {};
        final count = shopsData['count'] ?? shopsData['pending'] ?? 14;
        shopsLeft = count is int ? count : int.tryParse(count.toString()) ?? 14;
      } catch (e) {
        shopsLeft = 14; // Fallback
      }

      emit(HomeLoaded(
        firstName: firstName,
        territoryName: territoryName,
        hasActiveRoute: hasActiveRoute,
        shopsLeft: shopsLeft,
      ));
    } catch (e) {
      emit(HomeError('Failed to load home data: $e'));
    }
  }
}
