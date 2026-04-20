import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'package:mobile/features/promotions/data/services/promotion_service.dart';
import 'package:mobile/features/promotions/domain/promotion.dart';
import 'package:mobile/features/sales_rep/data/services/outlet_visit_service.dart';
import 'package:mobile/features/sales_rep/data/services/visit_service.dart';
import 'package:mobile/features/home/data/services/product_catalog_service.dart';
import 'package:mobile/features/home/domain/shop_catalog_product.dart';
import 'package:mobile/features/sales_rep/presentation/widgets/visit/osa_product_card.dart';

// ─────────────────────────────────────────────────────────────
// Domain types
// ─────────────────────────────────────────────────────────────

class StockEntry {
  final int shelfCount;
  final int backroomCount;

  const StockEntry({this.shelfCount = 0, this.backroomCount = 0});

  int estimatedSales(int historicalQty) {
    final consumed = historicalQty - shelfCount - backroomCount;
    return consumed.clamp(0, historicalQty > 0 ? historicalQty : 999999);
  }

  StockEntry copyWith({int? shelfCount, int? backroomCount}) => StockEntry(
        shelfCount: shelfCount ?? this.shelfCount,
        backroomCount: backroomCount ?? this.backroomCount,
      );
}

class PromoCheckEntry {
  final bool informed;
  final String feedback;

  const PromoCheckEntry({this.informed = false, this.feedback = ''});

  PromoCheckEntry copyWith({bool? informed, String? feedback}) =>
      PromoCheckEntry(
        informed: informed ?? this.informed,
        feedback: feedback ?? this.feedback,
      );
}

// ─────────────────────────────────────────────────────────────
// States
// ─────────────────────────────────────────────────────────────

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
  final String territoryId;
  final TerritoryOutlet? selectedOutlet;
  final List<ShopCatalogProduct> products;

  // OSA statuses (in/out of stock + reason)
  final Map<String, (OSAStatus, String?)> osaStatuses;

  // Stock counts per product
  final Map<String, StockEntry> stockEntries;

  // Expiry flags per product
  final Map<String, bool> expiryFlags;

  // OSA issue tags
  final Set<String> selectedOsaIssueTags;
  final String competitorNotes;

  // Promotion checks
  final Map<String, PromoCheckEntry> promotionChecks;
  final List<Promotion> activePromotions;

  // Planogram & POSM answers
  final Map<String, String> planogramAnswers;
  final Map<String, String> posmAnswers;

  // Outlet feedback
  final Map<String, String> outletFeedbackAnswers;
  final String outletFeedbackNote;

  // Order history context from backend
  final Map<String, int> productQuantitiesSinceLastVisit;
  final DateTime? lastVisitDate;
  final List<Map<String, dynamic>> recentOrders;

  // Locally captured photos (paths before upload)
  final List<String> localPhotoPaths;

  OutletVisitInProgress({
    required this.visit,
    required this.routeId,
    required this.territoryId,
    this.selectedOutlet,
    this.products = const [],
    this.osaStatuses = const {},
    this.stockEntries = const {},
    this.expiryFlags = const {},
    this.selectedOsaIssueTags = const {},
    this.competitorNotes = '',
    this.promotionChecks = const {},
    this.activePromotions = const [],
    this.planogramAnswers = const {},
    this.posmAnswers = const {},
    this.outletFeedbackAnswers = const {},
    this.outletFeedbackNote = '',
    this.productQuantitiesSinceLastVisit = const {},
    this.lastVisitDate,
    this.recentOrders = const [],
    this.localPhotoPaths = const [],
  });

  OutletVisitInProgress copyWith({
    StoreVisit? visit,
    List<ShopCatalogProduct>? products,
    Map<String, (OSAStatus, String?)>? osaStatuses,
    Map<String, StockEntry>? stockEntries,
    Map<String, bool>? expiryFlags,
    Set<String>? selectedOsaIssueTags,
    String? competitorNotes,
    Map<String, PromoCheckEntry>? promotionChecks,
    List<Promotion>? activePromotions,
    Map<String, String>? planogramAnswers,
    Map<String, String>? posmAnswers,
    Map<String, String>? outletFeedbackAnswers,
    String? outletFeedbackNote,
    Map<String, int>? productQuantitiesSinceLastVisit,
    DateTime? lastVisitDate,
    List<Map<String, dynamic>>? recentOrders,
    List<String>? localPhotoPaths,
  }) {
    return OutletVisitInProgress(
      visit: visit ?? this.visit,
      routeId: routeId,
      territoryId: territoryId,
      selectedOutlet: selectedOutlet,
      products: products ?? this.products,
      osaStatuses: osaStatuses ?? this.osaStatuses,
      stockEntries: stockEntries ?? this.stockEntries,
      expiryFlags: expiryFlags ?? this.expiryFlags,
      selectedOsaIssueTags: selectedOsaIssueTags ?? this.selectedOsaIssueTags,
      competitorNotes: competitorNotes ?? this.competitorNotes,
      promotionChecks: promotionChecks ?? this.promotionChecks,
      activePromotions: activePromotions ?? this.activePromotions,
      planogramAnswers: planogramAnswers ?? this.planogramAnswers,
      posmAnswers: posmAnswers ?? this.posmAnswers,
      outletFeedbackAnswers:
          outletFeedbackAnswers ?? this.outletFeedbackAnswers,
      outletFeedbackNote: outletFeedbackNote ?? this.outletFeedbackNote,
      productQuantitiesSinceLastVisit: productQuantitiesSinceLastVisit ??
          this.productQuantitiesSinceLastVisit,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      recentOrders: recentOrders ?? this.recentOrders,
      localPhotoPaths: localPhotoPaths ?? this.localPhotoPaths,
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

// ─────────────────────────────────────────────────────────────
// Cubit
// ─────────────────────────────────────────────────────────────

class OutletVisitCubit extends Cubit<OutletVisitState> {
  final OutletVisitService _outletVisitService = OutletVisitService();
  final VisitService _visitService = VisitService();
  final ProductCatalogService _productService = ProductCatalogService();
  final PromotionService _promotionService = PromotionService();

  OutletVisitCubit() : super(OutletVisitInitial());

  Future<(double, double)?> _getCurrentLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition();
      return (position.latitude, position.longitude);
    } catch (_) {
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

      // Start visit, fetch products & context in parallel
      final results = await Future.wait([
        _visitService.startVisit(
          routeId: routeId,
          shopId: outlet.id,
          shopName: outlet.outletName,
          latitude: lat,
          longitude: lng,
          territoryId: territoryId,
        ),
        _productService.fetchCatalog(),
        _outletVisitService.getOutletContext(outlet.id),
        _promotionService
            .fetchTerritoryPromotions(territoryId)
            .catchError((_) => <Promotion>[]),
      ]);

      final visitRes = results[0] as StartVisitResult;
      final catalog = results[1] as dynamic;
      final context = results[2] as OutletContext;
      final promotions = results[3] as List<Promotion>;

      final products = catalog.products as List<ShopCatalogProduct>;

      emit(
        OutletVisitInProgress(
          visit: visitRes.visit,
          routeId: routeId,
          territoryId: territoryId,
          selectedOutlet: outlet,
          products: products,
          osaStatuses: {
            for (var p in products) p.id: (OSAStatus.none, null as String?)
          },
          stockEntries: {for (var p in products) p.id: const StockEntry()},
          expiryFlags: {for (var p in products) p.id: false},
          activePromotions: promotions,
          promotionChecks: {
            for (var p in promotions)
              p.id: const PromoCheckEntry()
          },
          productQuantitiesSinceLastVisit: context.productQuantities,
          lastVisitDate: context.lastVisitDate,
          recentOrders: context.recentOrders,
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

  // ── OSA / Stock ──────────────────────────────────────────

  void updateOSAStatus(String productId, OSAStatus status, String? reason) {
    final s = state;
    if (s is! OutletVisitInProgress) return;
    final newStatuses = Map<String, (OSAStatus, String?)>.from(s.osaStatuses);
    newStatuses[productId] = (status, reason);
    emit(s.copyWith(osaStatuses: newStatuses));
  }

  void markAllInStock() {
    final s = state;
    if (s is! OutletVisitInProgress) return;
    emit(s.copyWith(osaStatuses: {
      for (var p in s.products) p.id: (OSAStatus.inStock, null as String?)
    }));
  }

  void updateStockEntry(String productId, int shelfCount, int backroomCount) {
    final s = state;
    if (s is! OutletVisitInProgress) return;
    final newEntries = Map<String, StockEntry>.from(s.stockEntries);
    newEntries[productId] = StockEntry(
      shelfCount: shelfCount,
      backroomCount: backroomCount,
    );
    emit(s.copyWith(stockEntries: newEntries));
  }

  // ── Expiry ───────────────────────────────────────────────

  void toggleExpiryFlag(String productId, bool hasExpiry) {
    final s = state;
    if (s is! OutletVisitInProgress) return;
    final newFlags = Map<String, bool>.from(s.expiryFlags);
    newFlags[productId] = hasExpiry;
    emit(s.copyWith(expiryFlags: newFlags));
  }

  // ── OSA Issues ───────────────────────────────────────────

  void toggleOsaIssueTag(String tag) {
    final s = state;
    if (s is! OutletVisitInProgress) return;
    final newTags = Set<String>.from(s.selectedOsaIssueTags);
    if (newTags.contains(tag)) {
      newTags.remove(tag);
    } else {
      newTags.add(tag);
    }
    emit(s.copyWith(selectedOsaIssueTags: newTags));
  }

  void updateCompetitorNotes(String notes) {
    final s = state;
    if (s is! OutletVisitInProgress) return;
    emit(s.copyWith(competitorNotes: notes));
  }

  // ── Promotions ───────────────────────────────────────────

  void updatePromoCheck(String promotionId, {bool? informed, String? feedback}) {
    final s = state;
    if (s is! OutletVisitInProgress) return;
    final newChecks = Map<String, PromoCheckEntry>.from(s.promotionChecks);
    final existing = newChecks[promotionId] ?? const PromoCheckEntry();
    newChecks[promotionId] = existing.copyWith(
      informed: informed,
      feedback: feedback,
    );
    emit(s.copyWith(promotionChecks: newChecks));
  }

  // ── Planogram / POSM ─────────────────────────────────────

  void updatePlanogramAnswer(String question, String answer) {
    final s = state;
    if (s is! OutletVisitInProgress) return;
    final newAnswers = Map<String, String>.from(s.planogramAnswers);
    newAnswers[question] = answer;
    emit(s.copyWith(planogramAnswers: newAnswers));
  }

  void updatePosmAnswer(String question, String answer) {
    final s = state;
    if (s is! OutletVisitInProgress) return;
    final newAnswers = Map<String, String>.from(s.posmAnswers);
    newAnswers[question] = answer;
    emit(s.copyWith(posmAnswers: newAnswers));
  }

  void addLocalPhoto(String path) {
    final s = state;
    if (s is! OutletVisitInProgress) return;
    emit(s.copyWith(localPhotoPaths: [...s.localPhotoPaths, path]));
  }

  void removeLocalPhoto(String path) {
    final s = state;
    if (s is! OutletVisitInProgress) return;
    emit(s.copyWith(
        localPhotoPaths: s.localPhotoPaths.where((p) => p != path).toList()));
  }

  // ── Outlet Feedback ──────────────────────────────────────

  void updateOutletFeedbackAnswer(String question, String answer) {
    final s = state;
    if (s is! OutletVisitInProgress) return;
    final newAnswers = Map<String, String>.from(s.outletFeedbackAnswers);
    newAnswers[question] = answer;
    emit(s.copyWith(outletFeedbackAnswers: newAnswers));
  }

  void updateOutletFeedbackNote(String note) {
    final s = state;
    if (s is! OutletVisitInProgress) return;
    emit(s.copyWith(outletFeedbackNote: note));
  }

  // ── Complete Visit ───────────────────────────────────────

  Future<void> completeVisit(String visitId) async {
    final s = state;
    if (s is! OutletVisitInProgress) return;

    emit(OutletVisitLoadingOutlets());
    try {
      // Build structured stock items
      final stockItems = s.products.map((p) {
        final osa = s.osaStatuses[p.id] ?? (OSAStatus.none, null as String?);
        final entry = s.stockEntries[p.id] ?? const StockEntry();
        final historical = s.productQuantitiesSinceLastVisit[p.id] ?? 0;
        return {
          'productId': p.id,
          'productName': p.name,
          'shelfCount': entry.shelfCount,
          'backroomCount': entry.backroomCount,
          'estimatedSales': entry.estimatedSales(historical),
          'inStock': osa.$1 != OSAStatus.outOfStock,
          if (osa.$2 != null) 'oosReason': osa.$2,
        };
      }).toList();

      // Expiry items
      final expiryItems = s.products
          .where((p) => s.expiryFlags[p.id] == true)
          .map((p) => {
                'productId': p.id,
                'productName': p.name,
                'hasExpiredItems': true,
              })
          .toList();

      // OSA issue tags
      final osaIssues = s.selectedOsaIssueTags
          .map((tag) => {'tag': tag})
          .toList();

      // Promotion checks
      final promotionChecks = s.activePromotions.map((promo) {
        final check = s.promotionChecks[promo.id] ?? const PromoCheckEntry();
        return {
          'promotionId': promo.id,
          'informed': check.informed,
          if (check.feedback.isNotEmpty) 'customerFeedback': check.feedback,
        };
      }).toList();

      // Planogram answers
      final planogramAnswers = s.planogramAnswers.entries
          .map((e) => {'question': e.key, 'answer': e.value})
          .toList();

      // POSM answers
      final posmAnswers = s.posmAnswers.entries
          .map((e) => {'question': e.key, 'answer': e.value})
          .toList();

      // Outlet feedback answers
      final feedbackAnswers = s.outletFeedbackAnswers.entries
          .map((e) => {'question': e.key, 'answer': e.value})
          .toList();

      final planogramOk = s.planogramAnswers.values.isNotEmpty &&
          s.planogramAnswers.values.every((v) => v == 'Yes');
      final posmOk = s.posmAnswers.values.isNotEmpty &&
          s.posmAnswers.values.every((v) => v == 'Yes');

      final res = await _visitService.completeVisit(
        visitId: visitId,
        stockItems: stockItems,
        expiryItems: expiryItems.isNotEmpty ? expiryItems : null,
        osaIssues: osaIssues.isNotEmpty ? osaIssues : null,
        competitorNotes:
            s.competitorNotes.isNotEmpty ? s.competitorNotes : null,
        promotionChecks: promotionChecks.isNotEmpty ? promotionChecks : null,
        planogramAnswers: planogramAnswers.isNotEmpty ? planogramAnswers : null,
        posmAnswers: posmAnswers.isNotEmpty ? posmAnswers : null,
        outletFeedbackAnswers:
            feedbackAnswers.isNotEmpty ? feedbackAnswers : null,
        planogramOk: planogramOk,
        posmOk: posmOk,
        feedback: s.outletFeedbackNote.isNotEmpty ? s.outletFeedbackNote : null,
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
