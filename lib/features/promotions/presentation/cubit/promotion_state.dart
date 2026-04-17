import 'package:mobile/features/promotions/domain/promotion.dart';

/// Base class for all promotion cubit states.
abstract class PromotionState {
  const PromotionState();
}

/// Initial state before any fetch has been requested.
class PromotionInitial extends PromotionState {
  const PromotionInitial();
}

/// Emitted while the network request is in-flight.
class PromotionLoading extends PromotionState {
  const PromotionLoading();
}

/// Emitted when promotions have been successfully fetched.
/// [promotions] may be empty when none are active for the territory.
class PromotionLoaded extends PromotionState {
  const PromotionLoaded(this.promotions, {required this.territoryId});

  final List<Promotion> promotions;
  final String territoryId;

  /// Convenience accessor for the first promotion, or null if the list is empty.
  Promotion? get firstPromotion =>
      promotions.isNotEmpty ? promotions.first : null;
}

/// Emitted when the fetch fails.
class PromotionError extends PromotionState {
  const PromotionError(this.message);

  final String message;
}
