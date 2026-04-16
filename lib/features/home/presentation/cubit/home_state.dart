abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final String firstName;
  final String territoryName;
  final bool hasActiveRoute;
  final int shopsLeft;
  final String? activeRouteId;
  final String? activeTerritoryId;

  HomeLoaded({
    required this.firstName,
    required this.territoryName,
    required this.hasActiveRoute,
    required this.shopsLeft,
    this.activeRouteId,
    this.activeTerritoryId,
  });
}

class HomeError extends HomeState {
  final String message;

  HomeError(this.message);
}
