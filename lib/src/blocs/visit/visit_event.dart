// lib/src/blocs/visit/visit_event.dart
part of 'visit_bloc.dart';

abstract class VisitEvent extends Equatable {
  const VisitEvent();

  @override
  List<Object?> get props => [];
}


class LoadVisitsByStatus extends VisitEvent {
  final String institutionId;
  final String status;

  const LoadVisitsByStatus({
    required this.institutionId,
    required this.status,
  });

  @override
  List<Object?> get props => [institutionId, status];
}

class LoadVisits extends VisitEvent {}

class AddVisit extends VisitEvent {
  final DateTime date;
  final String name;
  final String location;
  final String institutionId;

  const AddVisit({
    required this.date,
    required this.name,
    required this.location,
    required this.institutionId,
  });

  @override
  List<Object?> get props => [date, name, location, institutionId];
}

class UpdateVisit extends VisitEvent {
  final String id;
  final Map<String, dynamic> updates;
  final String institutionId;

  const UpdateVisit({
    required this.id,
    required this.updates,
    required this.institutionId,
  });

  @override
  List<Object?> get props => [id, updates, institutionId];
}

class DeleteVisit extends VisitEvent {
  final String id;
  final String institutionId;
  final String status;

  const DeleteVisit({
    required this.id,
    required this.status,
    required this.institutionId,
  });

  @override
  List<Object?> get props => [id, status, institutionId];
}

class LoadAllVisits extends VisitEvent {
  final String institutionId;

  const LoadAllVisits({required this.institutionId});

  @override
  List<Object?> get props => [institutionId];
}