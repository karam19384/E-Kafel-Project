// lib/src/blocs/profile/profile_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart'; // ⬅️ لإرسال FCM عبر callable
import '../../models/profile_model.dart';
import '../../services/firestore_service.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final FirestoreService firestoreService;
  final FirebaseAuth _auth;

  Profile? _profile; // حالة داخلية

  ProfileBloc(this.firestoreService, {FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance,
        super(ProfileInitial()) {
    on<LoadProfile>(_onLoad);
    on<UpdateProfileRequested>(_onUpdateProfile);
    on<UpdatePasswordRequested>(_onUpdatePassword);
    on<UpdateEmailRequested>(_onUpdateEmail);
  }

  Future<void> _onLoad(LoadProfile event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final p = await firestoreService.getProfileByUid(event.uid);
      if (p == null) {
        emit(const ProfileError('لم يتم العثور على بيانات المستخدم'));
        return;
      }
      _profile = p;
      emit(ProfileLoaded(p));
    } catch (e) {
      emit(ProfileError('فشل جلب البيانات: $e'));
    }
  }

// lib/src/blocs/profile/profile_bloc.dart

Future<void> _onUpdateProfile(
  UpdateProfileRequested event,
  Emitter<ProfileState> emit,
) async {
  final current = _profile;
  if (current == null) {
    emit(const ProfileError('الملف غير محمّل'));
    return;
  }
  emit(ProfileUpdating(current));

  try {
    final Map<String, dynamic> allowed = Map.of(event.fields);

    // قفل الحقول الثابتة دوماً
    const lockedAlways = {
      'customId','institutionName','institutionId','uid','userRole','kafalaHeadId',
      'functionalLodgment','areaResponsibleFor','fullName'
    };
    for (final k in lockedAlways) { allowed.remove(k); }

    // لو هو مشرف (ليس له صلاحيات كاملة)، لا نسمح إلا بهذه الحقول:
    if (!current.canEditAll) {
      final whitelist = {'email','address','profileImageUrl'}; // كلمة المرور لها حدث منفصل
      allowed.removeWhere((k, v) => !whitelist.contains(k));
    }

    await firestoreService.updateProfileFields(current.uid, allowed);

    final updated = current.copyWith(
      fullName: current.fullName, // لا تتغيّر
      email: allowed['email'],
      mobileNumber: current.mobileNumber, // لا تتغيّر هنا
      address: allowed['address'],
      profileImageUrl: allowed['profileImageUrl'],
      updatedAt: DateTime.now(),
    );
    _profile = updated;
    emit(ProfileUpdated(updated));
  } catch (e) {
    emit(ProfileError('فشل التحديث: $e'));
  }
}


  Future<void> _onUpdatePassword(
    UpdatePasswordRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'غير مسجّل دخول';

      await user.updatePassword(event.newPassword);

      // لا حاجة لتعديل حالة واجهة كبيرة
      final p = _profile;
      if (p != null) {
        emit(ProfileUpdated(p));
        // 🔔 إشعار للمستخدم نفسه
        await _notifyUser(
          userId: p.uid,
          title: 'تم تغيير كلمة المرور',
          message: 'تم تغيير كلمة مرور حسابك بنجاح.',
          type: 'password_change',
        );
      }
    } catch (e) {
      emit(ProfileError('فشل تغيير كلمة المرور: $e'));
    }
  }

  Future<void> _onUpdateEmail(
    UpdateEmailRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'غير مسجّل دخول';

      await user.updateEmail(event.newEmail);

      if (_profile != null) {
        await firestoreService.updateEmailInDoc(_profile!.uid, event.newEmail);
        _profile = _profile!.copyWith(
          email: event.newEmail,
          updatedAt: DateTime.now(),
        );
        emit(ProfileUpdated(_profile!));

        // 🔔 إشعار للمستخدم نفسه
        await _notifyUser(
          userId: _profile!.uid,
          title: 'تم تغيير البريد الإلكتروني',
          message: 'تم تحديث بريدك الإلكتروني إلى ${event.newEmail}.',
          type: 'email_change',
        );
      }
    } catch (e) {
      emit(ProfileError('فشل تغيير البريد: $e'));
    }
  }

  // =================== إشعارات للمستخدم ===================
  Future<void> _notifyUser({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      // 1) خزّن إشعارًا في Firestore (للواجهة)
      await firestoreService.createNotification({
        'userId': userId,
        'title': title,
        'message': message, // لِـ FirestoreService
        'body': message,    // لِـ الـ UI القديم الذي يقرأ body
        'type': type,
        'isRead': false,
      });

      // 2) حاول إرسال FCM لو عنده fcmTokens
      final userData = await firestoreService.getUserData(userId);
      if (userData == null) return;

      // يدعم fcmTokens (Array) أو fcmToken (واحد)
      final dynamic tokensRaw = userData['fcmTokens'] ?? userData['fcmToken'];
      final List<String> tokens = switch (tokensRaw) {
        List<dynamic> l => l.whereType<String>().toList(),
        String s when s.isNotEmpty => [s],
        _ => <String>[],
      };
      if (tokens.isEmpty) return;

      final callable = FirebaseFunctions.instance.httpsCallable('sendToToken');
      for (final t in tokens) {
        try {
          await callable.call(<String, dynamic>{
            'token': t,
            'notification': {'title': title, 'body': message},
            'data': {
              'type': type,
              'userId': userId,
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
          });
        } catch (e) {
          // لا نكسر التدفق بسبب فشل واحد
        }
      }
    } catch (e) {
      // تجاهل الخطأ حتى لا يؤثر على تجربة التحديث
    }
  }
}
