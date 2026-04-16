part of 'outlet_cubit.dart';

abstract class OutletState {}

class OutletInitial extends OutletState {}

class OutletLoading extends OutletState {}

class OutletSuccess extends OutletState {
  final String message;
  final dynamic outlet;

  OutletSuccess(this.message, this.outlet);
}

class OutletError extends OutletState {
  final String message;

  OutletError(this.message);
}
