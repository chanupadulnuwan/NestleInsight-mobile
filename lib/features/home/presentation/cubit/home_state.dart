abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final String firstName;
  final String territoryName;
  final bool hasActiveRoute;
  final int shopsLeft;

  HomeLoaded({
    required this.firstName,
    required this.territoryName,
    required this.hasActiveRoute,
    required this.shopsLeft,
  });
}

class HomeError extends HomeState {
  final String message;

  HomeError(this.message);
}
