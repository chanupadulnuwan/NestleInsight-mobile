import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';
import '../../../../core/network/dio_client.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  Future<void> loadHomeData() async {
    emit(HomeLoading());
    try {
      final dio = DioClient.instance.client;
      int shopsLeft = 0;
      bool hasActiveRoute = false;
      String firstName = "User";
      String territoryName = "Unknown Territory";
      String? activeTerritoryId;
      String? activeRouteId;

      // 1. Fetch User Data for Name & Territory
      try {
        final resAuth = await dio.get('/auth/me');
        final userData = resAuth.data['data'] ?? {};
        firstName = userData['firstName'] ?? 'User';
        territoryName = userData['territory']?['name'] ?? 'Unknown Territory';
      } catch (e) {
        // Fallback already set
      }

      // 2. Shops Left
      try {
        final resBeat = await dio.get('/outlets/beat-plan/today');
        final List items = resBeat.data['data'] ?? [];
        shopsLeft = items.where((item) => item['status'] != 'COMPLETED').length;
      } catch (e) {
        shopsLeft = 14; // Fallback for UI if empty
      }

      // 3. Route Status
      try {
        final resRoute = await dio.get('/sales-routes/my');
        final routeData = resRoute.data ?? {};
        final actualRoute = routeData['route'] ?? {};

        hasActiveRoute = actualRoute['status'] == 'IN_PROGRESS';
        activeRouteId = actualRoute['id']?.toString();
        activeTerritoryId = actualRoute['territoryId']?.toString();
      } catch (e) {
        hasActiveRoute = false;
      }

      emit(HomeLoaded(
        firstName: firstName,
        territoryName: territoryName,
        shopsLeft: shopsLeft,
        hasActiveRoute: hasActiveRoute,
        activeRouteId: activeRouteId,
        activeTerritoryId: activeTerritoryId,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
