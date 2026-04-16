import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/features/sales_rep/data/services/register_outlet_service.dart';
import 'package:mobile/features/sales_rep/data/services/route_setup_service.dart';

abstract class RegisterOutletState {}

class RegisterOutletInitial extends RegisterOutletState {}

class RegisterOutletLoading extends RegisterOutletState {}

class RegisterOutletLocationFetched extends RegisterOutletState {
  RegisterOutletLocationFetched({
    required this.latitude,
    required this.longitude,
    required this.territories,
  });

  final double latitude;
  final double longitude;
  final List<Territory> territories;
}

class RegisterOutletSuccess extends RegisterOutletState {
  RegisterOutletSuccess(this.message, this.outletId);

  final String message;
  final String outletId;
}

class RegisterOutletError extends RegisterOutletState {
  RegisterOutletError(this.message);

  final String message;
}

class RegisterOutletCubit extends Cubit<RegisterOutletState> {
  RegisterOutletCubit({
    RegisterOutletService? registerOutletService,
    RouteSetupService? routeSetupService,
  }) : _registerOutletService =
           registerOutletService ?? RegisterOutletService(),
       _routeSetupService = routeSetupService ?? RouteSetupService(),
       super(RegisterOutletInitial());

  final RegisterOutletService _registerOutletService;
  final RouteSetupService _routeSetupService;

  Future<void> fetchLocationAndTerritories() async {
    emit(RegisterOutletLoading());

    try {
      // Request location service
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(RegisterOutletError('Location services are disabled.'));
        return;
      }

      // Request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        emit(
          RegisterOutletError('Location permissions are permanently denied.'),
        );
        return;
      }

      if (permission == LocationPermission.denied) {
        emit(RegisterOutletError('Location permission denied.'));
        return;
      }

      // Fetch current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Fetch territories
      final territories = await _routeSetupService.fetchTerritories();

      emit(
        RegisterOutletLocationFetched(
          latitude: position.latitude,
          longitude: position.longitude,
          territories: territories,
        ),
      );
    } on RegisterOutletException catch (error) {
      emit(RegisterOutletError(error.message));
    } catch (e) {
      emit(RegisterOutletError('Failed to fetch location: $e'));
    }
  }

  Future<void> registerOutlet({
    required String outletName,
    required String ownerName,
    required String contactNumber,
    required String territoryId,
    required double latitude,
    required double longitude,
    String? ownerEmail,
    String? address,
  }) async {
    emit(RegisterOutletLoading());

    try {
      final request = RegisterOutletRequest(
        outletName: outletName,
        ownerName: ownerName,
        contactNumber: contactNumber,
        territoryId: territoryId,
        latitude: latitude,
        longitude: longitude,
        ownerEmail: ownerEmail,
        address: address,
      );

      final response = await _registerOutletService.registerOutlet(request);
      emit(RegisterOutletSuccess(response.message, response.outletId));
    } on RegisterOutletException catch (error) {
      emit(RegisterOutletError(error.message));
    }
  }
}
