part of 'home_bloc.dart';

@immutable
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final String userName;
  final String userRole;
  final String profileImageUrl;
  final String institutionId;
  final int orphanSponsored;
  final int completedTasksPercentage;
  final int orphanRequiringUpdates;
  final int supervisorsCount;
  final int completedFieldVisits;
  final List<Map<String, dynamic>> scheduledVisits;
  final List<Map<String, dynamic>> notifications;
  
  // الخصائص الجديدة
  final int totalOrphans;
  final int completedTasks;
  final int totalVisits;

  const HomeLoaded({
    required this.userName,
    required this.userRole,
    required this.profileImageUrl,
    required this.institutionId,
    required this.orphanSponsored,
    required this.completedTasksPercentage,
    required this.orphanRequiringUpdates,
    required this.supervisorsCount,
    required this.completedFieldVisits,
    required this.scheduledVisits,
    required this.notifications,
    required this.totalOrphans,
    required this.completedTasks,
    required this.totalVisits,
  });

  @override
  List<Object> get props => [
        userName,
        userRole,
        profileImageUrl,
        institutionId,
        orphanSponsored,
        completedTasksPercentage,
        orphanRequiringUpdates,
        supervisorsCount,
        completedFieldVisits,
        scheduledVisits,
        notifications,
        totalOrphans,
        completedTasks,
        totalVisits,
      ];
}

class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object> get props => [message];
}