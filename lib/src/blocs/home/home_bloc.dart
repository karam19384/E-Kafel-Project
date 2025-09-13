// lib/src/blocs/home/home_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:e_kafel/src/services/auth_service.dart';
import 'package:e_kafel/src/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  HomeBloc(this._authService, this._firestoreService) : super(HomeInitial()) {
    on<LoadHomeData>((event, emit) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(HomeError('User not authenticated.')); // ✅ تعديل هنا
        return;
      }

      emit(HomeLoading());
      try {
        final userData = await _firestoreService.getUserData(user.uid);
        if (userData != null) {
          final userRole = userData['role'] as String? ?? 'unknown';
          final institutionId = userData['institutionId'] as String?;

          if (institutionId == null) {
            emit(HomeError('Institution ID not found.')); // ✅ تعديل هنا
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
          // قم بإضافة هذا السطر بعد التأكد من وجود الدالة في firestore_service.dart
          final int? totalTasksCount = await _firestoreService.getTasksCount(
            institutionId,
          );

          emit(
            HomeLoaded(
              userName: userData['name'] ?? 'User',
              userRole: userRole,
              profileImageUrl: userData['profileImageUrl'] ?? '',
              institutionId: institutionId,
              orphanSponsored: stats['orphanSponsored'] ?? 0,
              completedTasksPercentage:
                  (stats['completedTasksPercentage'] ?? 0.0).toDouble(),
              orphanRequiringUpdates: stats['orphanRequiringUpdates'] ?? 0,
              supervisorsCount: stats['supervisorsCount'] ?? 0,
              completedFieldVisits: stats['completedFieldVisits'] ?? 0,
              scheduledVisits: visits,
              notifications: notifications,
              totalOrphans: stats['totalOrphans'] ?? 0,
              completedTasks: stats['completedTasks'] ?? 0,
              totalVisits: stats['totalVisits'] ?? 0,
              totalTasks: totalTasksCount ?? 0,
            ),
          );
        } else {
          emit(HomeError('User data not found.')); // ✅ تعديل هنا
        }
      } catch (e, stackTrace) {
        print('Error caught in HomeBloc: $e');
        print('StackTrace: $stackTrace');
        emit(HomeError('Failed to load home data: $e')); // ✅ تعديل هنا
      }
    });
  }
}
