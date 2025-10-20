// lib/src/blocs/home/home_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_kafel/src/services/firestore_service.dart';
import 'package:e_kafel/src/services/auth_service.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final AuthService _authService;
  final FirestoreService _firestore;

  HomeBloc(this._authService, this._firestore) : super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
  }

  // ========== Helpers ==========
  String _s(Object? v, {String def = ''}) => (v is String) ? v : def;
  int _i(Object? v, {int def = 0}) => (v is int) ? v : def;
  double _d(Object? v, {double def = 0.0}) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return def;
  }

  List<Map<String, dynamic>> _castListOfMap(Object? v) {
    if (v is List) {
      return v
          .whereType<Map>()
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>?> _getCurrentUserMap() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // users collection
    final uSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (uSnap.exists) {
      final data = uSnap.data();
      if (data != null) return {...data, 'uid': uSnap.id};
    }

    // fallback kafala_heads
    final khSnap = await FirebaseFirestore.instance
        .collection('kafala_heads')
        .doc(user.uid)
        .get();
    if (khSnap.exists && khSnap.data() != null) {
      return {...khSnap.data()!, 'uid': khSnap.id, 'userRole': 'kafala_head'};
    }

    // fallback supervisors
    final supSnap = await FirebaseFirestore.instance
        .collection('supervisors')
        .doc(user.uid)
        .get();
    if (supSnap.exists && supSnap.data() != null) {
      return {...supSnap.data()!, 'uid': supSnap.id, 'userRole': 'supervisor'};
    }

    return null;
  }

  // ========== Handler ==========
  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(HomeLoading());

      final userMap = await _getCurrentUserMap();
      if (userMap == null) {
        emit(const HomeError('فشل في تحميل بيانات المستخدم'));
        return;
      }

      final institutionId = _s(userMap['institutionId']);
      final userRole = _s(userMap['userRole'], def: 'unknown');
      final userName = _s(
        userMap['fullName'].toString().isNotEmpty
            ? userMap['fullName']
            : userMap['email']?.split('@').first ?? 'مستخدم',
      );
      final profileImageUrl = _s(userMap['profileImageUrl']);
      final kafalaHeadId = _s(userMap['kafalaHeadId']);

      // ✅ استخدم _firestore بدل _firestoreService
      final stats = await _firestore.getDashboardStats(institutionId);

      // زيارات مجدولة
      List<Map<String, dynamic>> scheduledVisits = _castListOfMap(
        stats['scheduledVisits'],
      );
      if (scheduledVisits.isEmpty) {
        scheduledVisits = await _firestore.getScheduledVisits(institutionId);
      }

      // إشعارات
      List<Map<String, dynamic>> notifications = _castListOfMap(
        stats['notifications'],
      );
      if (notifications.isEmpty) {
        final uid = _s(userMap['uid']);
        if (uid.isNotEmpty) {
          notifications = await _firestore.getNotifications(uid);
        }
      }

      final archivedOrphansCount =
          await _firestore.getArchivedOrphansCount(institutionId) ?? 0;

      emit(
        HomeLoaded(
          userName: userName,
          userRole: userRole,
          profileImageUrl: profileImageUrl,
          institutionId: institutionId,
          kafalaHeadId: kafalaHeadId,

          totalOrphans: _i(stats['totalOrphans']),
          orphanSponsored: _i(stats['orphanSponsored']),
          orphanRequiringUpdates: _i(stats['orphanRequiringUpdates']),
          supervisorsCount: _i(stats['supervisorsCount']),
          completedTasks: _i(stats['completedTasks']),
          totalTasks: _i(stats['totalTasks']),
          totalVisits: _i(stats['totalVisits']),
          completedFieldVisits: _i(stats['completedFieldVisits']),
          completedTasksPercentage: _d(stats['completedTasksPercentage']),
          archivedOrphansCount: archivedOrphansCount,
          scheduledVisits: scheduledVisits,
          notifications: notifications,
        ),
      );
    } catch (e) {
      emit(HomeError('فشل في تحميل البيانات: $e'));
    }
  }
}
