// orphans_state.dart
part of 'orphans_bloc.dart';

abstract class OrphansState extends Equatable {
  const OrphansState();

  @override
  List<Object?> get props => [];
}
class ArchivedOrphansCountLoaded extends OrphansState {
  final int? count;
  const ArchivedOrphansCountLoaded({required this.count});
}

class OrphansInitial extends OrphansState {}

class OrphansLoading extends OrphansState {}

class OrphansLoaded extends OrphansState {
  final List<Orphan> orphans;
  final Map<String, dynamic>? filters;

  const OrphansLoaded(this.orphans, {this.filters});

  @override
  List<Object?> get props => [orphans, filters];
}

class OrphansError extends OrphansState {
  final String message;

  const OrphansError(this.message);

  @override
  List<Object?> get props => [message];
}

class OrphanAdded extends OrphansState {
  final Orphan orphan;

  const OrphanAdded(this.orphan);

  @override
  List<Object?> get props => [orphan];
}

class OrphanUpdated extends OrphansState {
  final Orphan orphan;

  const OrphanUpdated(this.orphan);

  @override
  List<Object?> get props => [orphan];
}

class OrphanArchived extends OrphansState {
  final String orphanId;

  const OrphanArchived(this.orphanId);

  @override
  List<Object?> get props => [orphanId];
}

class OrphansSearchLoaded extends OrphansState {
  final List<Orphan> orphans;
  final String searchTerm;

  const OrphansSearchLoaded(this.orphans, this.searchTerm);

  @override
  List<Object?> get props => [orphans, searchTerm];
}