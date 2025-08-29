import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:e_kafel/src/services/auth_service.dart';
import 'package:e_kafel/src/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  // ignore: unused_field
  final AuthService _authService;
  final FirestoreService _firestoreService;

  HomeBloc(this._authService, this._firestoreService) : super(HomeInitial()) {
    on<LoadHomeData>((event, emit) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(HomeError(message: 'User not authenticated.'));
        return;
      }

      emit(HomeLoading());
      try {
        final userData = await _firestoreService.getUserData(user.uid);
        if (userData != null) {
          final userRole = userData['role'] as String? ?? 'unknown';
          final institutionId = userData['institutionId'] as String?;

          if (institutionId == null) {
            emit(HomeError(message: 'Institution ID not found.'));
            return;
          }

          final stats = await _firestoreService.getDashboardStats(
            institutionId,
          );
          final visits = await _firestoreService.getScheduledVisits(
            institutionId,
          );
          final notifications = await _firestoreService.getNotifications(
            user.uid,
          );

          emit(
            HomeLoaded(
              userName: userData['name'] ?? 'User',
              userRole: userRole,
              profileImageUrl: userData['profileImageUrl'] ?? '',
              institutionId: institutionId,
              orphanSponsored: stats['orphanSponsored'] ?? 0,
              completedTasksPercentage:
                  (stats['completedTasksPercentage'] ?? 0),
              orphanRequiringUpdates: stats['orphanRequiringUpdates'] ?? 0,
              supervisorsCount: stats['supervisorsCount'] ?? 0,
              completedFieldVisits: stats['completedFieldVisits'] ?? 0,
              scheduledVisits: visits,
              notifications: notifications,
              totalOrphans:
                  (stats['orphanSponsored'] ?? 0) +
                  (stats['orphanRequiringUpdates'] ?? 0),
              completedTasks: (stats['completedTasksPercentage'] ?? 0.0)
                  .toInt(),
              totalVisits: stats['completedFieldVisits'] ?? 0,
            ),
          );
        } else {
          emit(HomeError(message: 'User data not found.'));
        }
      } catch (e) {
        emit(HomeError(message: 'Failed to load home data: $e'));
      }
    });
  }
}
