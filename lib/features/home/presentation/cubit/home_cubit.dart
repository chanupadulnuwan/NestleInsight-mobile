import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';
import '../../../../core/network/dio_client.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  Map<String, dynamic> _readAuthUser(dynamic payload) {
    if (payload is! Map) {
      return const <String, dynamic>{};
    }

    final root = Map<String, dynamic>.from(payload);
    final nestedUser = root['user'];
    if (nestedUser is Map) {
      return Map<String, dynamic>.from(nestedUser);
    }

    final nestedData = root['data'];
    if (nestedData is Map) {
      return Map<String, dynamic>.from(nestedData);
    }

    return root;
  }

  String _readTerritoryName(Map<dynamic, dynamic> userData) {
    final territoryName = userData['territoryName']?.toString().trim();
    if (territoryName != null && territoryName.isNotEmpty) {
      return territoryName;
    }

    final territory = userData['territory'];
    if (territory is Map) {
      final nestedName = territory['name']?.toString().trim();
      if (nestedName != null && nestedName.isNotEmpty) {
        return nestedName;
      }
    }

    if (territory is String && territory.trim().isNotEmpty) {
      return territory.trim();
    }

    return 'Unknown Territory';
  }

  String? _readTerritoryId(Map<dynamic, dynamic> userData) {
    final directTerritoryId = userData['territoryId']?.toString().trim();
    if (directTerritoryId != null && directTerritoryId.isNotEmpty) {
      return directTerritoryId;
    }

    final territory = userData['territory'];
    if (territory is Map) {
      final nestedTerritoryId = territory['id']?.toString().trim();
      if (nestedTerritoryId != null && nestedTerritoryId.isNotEmpty) {
        return nestedTerritoryId;
      }
    }

    return null;
  }

  Future<void> loadHomeData() async {
    emit(HomeLoading());
    try {
      final dio = DioClient.instance.client;
      int shopsLeft = 0;
      bool hasActiveRoute = false;
      bool hasReportableRoute = false;
      String firstName = "User";
      String territoryName = "Unknown Territory";
      String? territoryId;
      String? activeTerritoryId;
      String? activeRouteId;

      // 1. Fetch User Data for Name & Territory
      try {
        final resAuth = await dio.get('/auth/me');
        final userData = _readAuthUser(resAuth.data);
        firstName = userData['firstName'] ?? 'User';
        territoryName = _readTerritoryName(userData);
        territoryId = _readTerritoryId(userData);
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

        final status = actualRoute['status']?.toString().toUpperCase();
        hasActiveRoute = status == 'ACTIVE' || status == 'IN_PROGRESS';
        activeRouteId = actualRoute['id']?.toString();
        activeTerritoryId = actualRoute['territoryId']?.toString();
        hasReportableRoute = activeRouteId != null && activeRouteId.isNotEmpty;

        if (!hasReportableRoute) {
          final latestRouteRes = await dio.get('/sales-routes/my/latest');
          final latestRouteData = latestRouteRes.data ?? {};
          final latestRoute = latestRouteData['route'] ?? {};

          final latestRouteId = latestRoute['id']?.toString();
          if (latestRouteId != null && latestRouteId.isNotEmpty) {
            activeRouteId = latestRouteId;
            activeTerritoryId =
                latestRoute['territoryId']?.toString() ?? activeTerritoryId;
            hasReportableRoute = true;
          }
        }
      } catch (e) {
        hasActiveRoute = false;
      }

      emit(HomeLoaded(
        firstName: firstName,
        territoryName: territoryName,
        territoryId: territoryId,
        shopsLeft: shopsLeft,
        hasActiveRoute: hasActiveRoute,
        hasReportableRoute: hasReportableRoute,
        activeRouteId: activeRouteId,
        activeTerritoryId: activeTerritoryId,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
