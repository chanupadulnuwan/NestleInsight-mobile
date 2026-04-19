import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/services/territory_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/features/sales_rep/data/services/register_outlet_service.dart';

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
  final List<RegisterOutletTerritoryOption> territories;
}

class RegisterOutletTerritoryOption {
  const RegisterOutletTerritoryOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
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
    TerritoryService? territoryService,
  }) : _registerOutletService =
           registerOutletService ?? RegisterOutletService(),
       _territoryService = territoryService ?? TerritoryService(),
       super(RegisterOutletInitial());

  final RegisterOutletService _registerOutletService;
  final TerritoryService _territoryService;

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
      final position = await Geolocator.getCurrentPosition();
      final assignment = await _territoryService.resolveAssignment(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (assignment == null) {
        emit(
          RegisterOutletError(
            'No matching territory was found for your current location.',
          ),
        );
        return;
      }

      final territories = [
        RegisterOutletTerritoryOption(
          id: assignment.territoryId,
          name: assignment.territoryName,
        ),
      ];

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
