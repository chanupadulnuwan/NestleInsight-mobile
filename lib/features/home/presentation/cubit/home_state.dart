abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final String firstName;
  final String fullName;
  final String username;
  final String email;
  final String mobileNumber;
  final String territoryName;
  final String? territoryId;
  final bool hasActiveRoute;
  final bool hasReportableRoute;
  final int shopsLeft;
  final String? activeRouteId;
  final String? activeTerritoryId;
  final String? reportableRouteId;
  final String? reportableTerritoryId;

  HomeLoaded({
    required this.firstName,
    required this.fullName,
    required this.username,
    required this.email,
    required this.mobileNumber,
    required this.territoryName,
    this.territoryId,
    required this.hasActiveRoute,
    required this.hasReportableRoute,
    required this.shopsLeft,
    this.activeRouteId,
    this.activeTerritoryId,
    this.reportableRouteId,
    this.reportableTerritoryId,
  });
}

class HomeError extends HomeState {
  final String message;

  HomeError(this.message);
}
