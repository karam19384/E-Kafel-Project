part of 'sponsership_bloc.dart';

abstract class SponsorshipEvent extends Equatable {
  const SponsorshipEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadSponsorshipProjects extends SponsorshipEvent {
  final String institutionId;
  final String? status;
  final String? type;
  final String? search;
  
  const LoadSponsorshipProjects({
    required this.institutionId,
    this.status,
    this.type,
    this.search,
  });
  
  @override
  List<Object?> get props => [institutionId, status, type, search];
}

class CreateSponsorshipProjectEvent extends SponsorshipEvent {
  final SponsorshipProject project;
  
  const CreateSponsorshipProjectEvent(this.project);
  
  @override
  List<Object?> get props => [project];
}

class UpdateSponsorshipProjectEvent extends SponsorshipEvent {
  final SponsorshipProject project;
  
  const UpdateSponsorshipProjectEvent(this.project);
  
  @override
  List<Object?> get props => [project];
}

class ChangeProjectStatusEvent extends SponsorshipEvent {
  final String projectId;
  final String status;
  
  const ChangeProjectStatusEvent({
    required this.projectId,
    required this.status,
  });
  
  @override
  List<Object?> get props => [projectId, status];
}

class AddProjectEventItemEvent extends SponsorshipEvent {
  final String projectId;
  final SponsorshipEventItem event;
  
  const AddProjectEventItemEvent({
    required this.projectId,
    required this.event,
  });
  
  @override
  List<Object?> get props => [projectId, event];
}