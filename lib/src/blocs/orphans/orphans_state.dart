part of 'orphans_bloc.dart';

abstract class OrphansState extends Equatable {
  const OrphansState();

  @override
  List<Object?> get props => [];
}

class OrphansInitial extends OrphansState {}

class OrphansLoading extends OrphansState {}

class OrphansLoaded extends OrphansState {
  final List<Map<String, dynamic>> orphans;

  const OrphansLoaded(this.orphans);

  @override
  List<Object?> get props => [orphans];
}

class OrphansError extends OrphansState {
  final String message;

  const OrphansError(this.message);

  @override
  List<Object?> get props => [message];
}

class OrphanAdded extends OrphansState {
  const OrphanAdded();
}

