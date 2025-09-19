// lib/src/blocs/visit/visit_state.dart
part of 'visit_bloc.dart';

abstract class VisitState extends Equatable {
  const VisitState();

  @override
  List<Object?> get props => [];
}

class VisitInitial extends VisitState {}

class VisitLoading extends VisitState {}


class VisitLoaded extends VisitState {
  final List<Map<String, dynamic>> scheduledVisits;
  final List<Map<String, dynamic>> completedVisits;



  const VisitLoaded({
    this.scheduledVisits = const [],
    this.completedVisits = const [],
  });

  @override
  List<Object?> get props => [scheduledVisits, completedVisits];
}

class VisitError extends VisitState {
  final String message;

  const VisitError(this.message);

  @override
  List<Object?> get props => [message];
}