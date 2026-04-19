import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'package:mobile/features/sales_rep/data/services/outlet_visit_service.dart';
import 'package:mobile/features/sales_rep/data/services/visit_service.dart';
import 'package:mobile/features/home/data/services/product_catalog_service.dart';
import 'package:mobile/features/home/domain/shop_catalog_product.dart';
import 'package:mobile/features/sales_rep/presentation/widgets/visit/osa_product_card.dart';

abstract class OutletVisitState {}

class OutletVisitInitial extends OutletVisitState {}

class OutletVisitLoadingOutlets extends OutletVisitState {}

class OutletVisitOutletsLoaded extends OutletVisitState {
  final List<TerritoryOutlet> outlets;
  OutletVisitOutletsLoaded(this.outlets);
}

class OutletVisitInProgress extends OutletVisitState {
  final StoreVisit visit;
  final String routeId;
  final TerritoryOutlet? selectedOutlet;
  final List<ShopCatalogProduct> products;
  final Map<String, (OSAStatus, String?)> osaStatuses;

  OutletVisitInProgress({
    required this.visit,
    required this.routeId,
    this.selectedOutlet,
    this.products = const [],
    this.osaStatuses = const {},
  });

  OutletVisitInProgress copyWith({
    StoreVisit? visit,
    List<ShopCatalogProduct>? products,
    Map<String, (OSAStatus, String?)>? osaStatuses,
  }) {
    return OutletVisitInProgress(
      visit: visit ?? this.visit,
      routeId: routeId,
      selectedOutlet: selectedOutlet,
      products: products ?? this.products,
      osaStatuses: osaStatuses ?? this.osaStatuses,
    );
  }
}

class OutletVisitCompleted extends OutletVisitState {
  final String message;
  final int durationSeconds;
  OutletVisitCompleted({required this.message, required this.durationSeconds});
}

class OutletVisitError extends OutletVisitState {
  final String message;
  OutletVisitError(this.message);
}

class OutletVisitCubit extends Cubit<OutletVisitState> {
  final OutletVisitService _outletVisitService = OutletVisitService();
  final VisitService _visitService = VisitService();
  final ProductCatalogService _productService = ProductCatalogService();

  OutletVisitCubit() : super(OutletVisitInitial());

  Future<(double, double)?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return null;
    } 

    try {
      final position = await Geolocator.getCurrentPosition();
      return (position.latitude, position.longitude);
    } catch (e) {
      return null;
    }
  }

  Future<void> loadOutlets() async {
    emit(OutletVisitLoadingOutlets());
    try {
      final outlets = await _outletVisitService.fetchMyOutlets();
      emit(OutletVisitOutletsLoaded(outlets));
    } on OutletVisitServiceException catch (e) {
      emit(OutletVisitError(e.message));
    } catch (e) {
      emit(OutletVisitError('Failed to load outlets: $e'));
    }
  }

  Future<void> startVisit({
    required String routeId,
    required String territoryId,
    required TerritoryOutlet outlet,
  }) async {
    emit(OutletVisitLoadingOutlets());
    try {
      final location = await _getCurrentLocation();
      final lat = location?.$1 ?? outlet.latitude ?? 0.0;
      final lng = location?.$2 ?? outlet.longitude ?? 0.0;

      final res = await _visitService.startVisit(
        routeId: routeId,
        shopId: outlet.id,
        shopName: outlet.outletName,
        latitude: lat,
        longitude: lng,
        territoryId: territoryId,
      );

      // Fetch products for OSA check
      final catalog = await _productService.fetchCatalog();

      emit(
        OutletVisitInProgress(
          visit: res.visit,
          routeId: routeId,
          selectedOutlet: outlet,
          products: catalog.products,
          osaStatuses: {
            for (var p in catalog.products) p.id: (OSAStatus.none, null)
          },
        ),
      );
    } on VisitServiceException catch (e) {
      emit(OutletVisitError(e.message));
    } on ProductCatalogServiceException catch (e) {
      emit(OutletVisitError('Failed to load products: ${e.message}'));
    } catch (e) {
      emit(OutletVisitError('Failed to start visit: $e'));
    }
  }

  void updateOSAStatus(String productId, OSAStatus status, String? reason) {
    final currentState = state;
    if (currentState is! OutletVisitInProgress) return;

    final newStatuses = Map<String, (OSAStatus, String?)>.from(currentState.osaStatuses);
    newStatuses[productId] = (status, reason);

    emit(currentState.copyWith(osaStatuses: newStatuses));
  }

  void markAllInStock() {
    final currentState = state;
    if (currentState is! OutletVisitInProgress) return;

    final newStatuses = {
      for (var p in currentState.products) p.id: (OSAStatus.inStock, null as String?)
    };

    emit(currentState.copyWith(osaStatuses: newStatuses));
  }

  Future<void> completeVisit({
    required String visitId,
    bool? planogramOk,
    bool? posmOk,
    String? osaNote,
    String? feedback,
  }) async {
    final currentState = state;
    if (currentState is! OutletVisitInProgress) return;

    emit(OutletVisitLoadingOutlets()); // Show loading while completing
    try {
      final osaStatuses = currentState.osaStatuses;
      final osaIssuesList = osaStatuses.entries
          .where((e) => e.value.$1 == OSAStatus.outOfStock)
          .map((e) => {
                'productId': e.key,
                'status': 'OOS',
                'reason': e.value.$2,
              })
          .toList();

      final res = await _visitService.completeVisit(
        visitId: visitId,
        planogramOk: planogramOk,
        posmOk: posmOk,
        osaIssues: osaIssuesList.isNotEmpty ? {'items': osaIssuesList, 'note': osaNote} : null,
        feedback: feedback,
      );

      emit(OutletVisitCompleted(
        message: res.message,
        durationSeconds: res.durationSeconds,
      ));
    } on VisitServiceException catch (e) {
      emit(OutletVisitError(e.message));
    } catch (e) {
      emit(OutletVisitError('Failed to complete visit: $e'));
    }
  }
}
