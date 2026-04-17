import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/promotions/data/services/promotion_service.dart';
import 'package:mobile/features/promotions/presentation/cubit/promotion_state.dart';

/// Manages the lifecycle of active-promotion fetching for a given territory.
///
/// Usage:
/// ```dart
/// BlocProvider(
///   create: (_) => PromotionCubit(
///     territoryId: state.territoryId,
///     service: PromotionService(),
///   )..loadPromotions(),
/// )
/// ```
class PromotionCubit extends Cubit<PromotionState> {
  PromotionCubit({
    required this.territoryId,
    required PromotionService service,
  })  : _service = service,
        super(const PromotionInitial());

  /// The territory whose active promotions will be fetched.
  final String territoryId;

  final PromotionService _service;

  /// Fetches active promotions for [territoryId].
  ///
  /// If [territoryId] is empty the cubit immediately emits
  /// [PromotionLoaded] with an empty list — no network call is made.
  Future<void> loadPromotions() async {
    // Guard: skip the request when no territory is available yet.
    if (territoryId.trim().isEmpty) {
      emit(PromotionLoaded(const [], territoryId: territoryId));
      return;
    }

    emit(const PromotionLoading());
    try {
      final promotions = await _service.fetchActivePromotions(territoryId);
      emit(PromotionLoaded(promotions, territoryId: territoryId));
    } on PromotionServiceException catch (error) {
      emit(PromotionError(error.message));
    } catch (error) {
      emit(PromotionError('An unexpected error occurred: $error'));
    }
  }
}
