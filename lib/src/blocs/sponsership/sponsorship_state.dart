part of 'sponsership_bloc.dart';



abstract class SponsorshipState extends Equatable {
  const SponsorshipState();
  
  @override
  List<Object?> get props => [];
}

class SponsorshipInitial extends SponsorshipState {}

class SponsorshipLoading extends SponsorshipState {}

class SponsorshipLoaded extends SponsorshipState {
  final List<SponsorshipProject> projects;
  final int totalProjects;
  final int activeCount;
  final int completedCount;
  final int pendingCount;
  final double totalBudget;
  final double totalSpent;
  final double totalAvailable;

  const SponsorshipLoaded({
    required this.projects,
    required this.totalProjects,
    required this.activeCount,
    required this.completedCount,
    required this.pendingCount,
    required this.totalBudget,
    required this.totalSpent,
    required this.totalAvailable,
  });

  @override
  List<Object?> get props => [
        projects,
        totalProjects,
        activeCount,
        completedCount,
        pendingCount,
        totalBudget,
        totalSpent,
        totalAvailable,
      ];
}

class SponsorshipError extends SponsorshipState {
  final String message;

  const SponsorshipError(this.message);

  @override
  List<Object?> get props => [message];
}

// الحالات الجديدة المطلوبة للـ Listener
class SponsorshipProjectCreated extends SponsorshipState {
  final SponsorshipProject project;

  const SponsorshipProjectCreated({required this.project});

  @override
  List<Object?> get props => [project];
}

class SponsorshipProjectUpdated extends SponsorshipState {
  final SponsorshipProject project;

  const SponsorshipProjectUpdated({required this.project});

  @override
  List<Object?> get props => [project];
}

class SponsorshipProjectStatusChanged extends SponsorshipState {
  final String projectId;
  final String status;

  const SponsorshipProjectStatusChanged({
    required this.projectId,
    required this.status,
  });

  @override
  List<Object?> get props => [projectId, status];
}

class SponsorshipEventAdded extends SponsorshipState {
  final String projectId;
  final SponsorshipEventItem event;

  const SponsorshipEventAdded({
    required this.projectId,
    required this.event,
  });

  @override
  List<Object?> get props => [projectId, event];
}