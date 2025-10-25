import 'package:bloc/bloc.dart';
import 'package:e_kafel/src/services/email_link_service.dart';
import 'package:e_kafel/src/services/fcm_service.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:e_kafel/src/services/auth_service.dart';
import 'package:e_kafel/src/services/firestore_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final EmailLinkService _emailLinkService = EmailLinkService();
  final FCMService _fcmService = FCMService();

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<SendEmailVerificationRequested>(_onSendEmailVerificationRequested);
    on<VerifyEmailCodeRequested>(_onVerifyEmailCodeRequested);
    on<UnlinkEmailRequested>(_onUnlinkEmailRequested);
    on<CheckEmailLinkStatus>(_onCheckEmailLinkStatus);
    on<LoginButtonPressed>(_onLoginButtonPressed);
    on<LogoutButtonPressed>(_onLogoutButtonPressed);
    on<SignOutButtonPressed>(_onSignOutButtonPressed);
    on<SignUpButtonPressed>(_onSignUpButtonPressed);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    try {
      // تهيئة FCM Service
      await _fcmService.initialize();
    } catch (e) {
      print('⚠️ فشل تهيئة FCM: $e');
    }

    final user = _firebaseAuth.currentUser;
    if (user == null) {
      emit(AuthUnauthenticated());
      return;
    }

    final data = await _getUserDataByUid(user.uid);
    if (data == null) {
      await _firebaseAuth.signOut();
      emit(AuthUnauthenticated());
      return;
    }

    // حارس التفعيل
    final isActive = (data['isActive'] as bool?) ?? true;
    if (!isActive) {
      await _firebaseAuth.signOut();
      emit(AuthUnauthenticated(
        message: 'تم إلغاء تفعيل حسابك. تواصل مع الإدارة.',
      ));
      return;
    }

    emit(
      AuthAuthenticated(
        userRole: (data['userRole'] ?? 'unknown').toString(),
        userName: (data['fullName'] ?? data['headName'] ?? data['email'] ?? 'User')
            .toString(),
        institutionId: (data['institutionId'] ?? '').toString(),
        userData: data,
      ),
    );
  }

  Future<void> _onSendEmailVerificationRequested(
    SendEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      final currentState = state;
      if (currentState is AuthAuthenticated) {
        await _emailLinkService.sendVerificationEmail(
          email: event.email,
          userId: currentState.userData['uid'],
        );
        
        // إرسال إشعار محلي برمز التحقق
        final verificationCode = await _getVerificationCode(currentState.userData['uid']);
        if (verificationCode != null) {
          await _fcmService.sendVerificationNotification(verificationCode);
        }
        
        emit(EmailVerificationSent(event.email));
      } else {
        emit(const AuthErrorState(message: 'يجب تسجيل الدخول أولاً'));
      }
    } catch (e) {
      emit(AuthErrorState(message: e.toString()));
    }
  }

  Future<String?> _getVerificationCode(String userId) async {
    try {
      final doc = await _firestoreService
          .collection('emailLinkRequests')
          .doc(userId)
          .get();
      if (doc.exists) {
        return doc.data()?['verificationCode'] as String?;
      }
    } catch (e) {
      print('فشل الحصول على رمز التحقق: $e');
    }
    return null;
  }

  Future<void> _onVerifyEmailCodeRequested(
    VerifyEmailCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      final currentState = state;
      if (currentState is AuthAuthenticated) {
        await _emailLinkService.verifyEmailCode(
          email: event.email,
          code: event.code,
          userId: currentState.userData['uid'],
        );
        emit(EmailVerified(event.email));
        // إعادة تحميل حالة المستخدم
        add(CheckEmailLinkStatus());
      } else {
        emit(const AuthErrorState(message: 'يجب تسجيل الدخول أولاً'));
      }
    } catch (e) {
      emit(AuthErrorState(message: e.toString()));
    }
  }

  Future<void> _onUnlinkEmailRequested(
    UnlinkEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      final currentState = state;
      if (currentState is AuthAuthenticated) {
        await _emailLinkService.unlinkEmail(currentState.userData['uid']);
        emit(const EmailUnlinked());
        // إعادة تحميل حالة المستخدم
        add(CheckEmailLinkStatus());
      } else {
        emit(const AuthErrorState(message: 'يجب تسجيل الدخول أولاً'));
      }
    } catch (e) {
      emit(AuthErrorState(message: e.toString()));
    }
  }

  Future<void> _onCheckEmailLinkStatus(
    CheckEmailLinkStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is AuthAuthenticated) {
        final status = await _emailLinkService.getEmailLinkStatus(currentState.userData['uid']);
        emit(EmailLinkStatusChecked(
          isLinked: status?['isLinked'] ?? false,
          email: status?['email'],
          isVerified: status?['verified'] ?? false,
        ));
      }
    } catch (e) {
      // لا نعرض خطأ هنا لأنه ليس حرجاً
      print('Error checking email link status: $e');
    }
  }

  // باقي الدوال كما هي بدون تغيير (_onLoginButtonPressed, _onLogoutButtonPressed, etc.)
  // ... [جميع الدوال الأخرى تبقى كما هي بدون تعديل]

  // ====== Login (email or customId) ======
  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      String emailToUse = event.loginIdentifier.trim();
      String userRole = '';
      String? institutionId;
      Map<String, dynamic> userData = {};

      final isEmail = emailToUse.contains('@');

      // لو المُعرّف ليس بريد، ابحث بالـ customId في users أولاً، ثم في النظام القديم
      if (!isEmail) {
        final userQuery = await _firestoreService
            .collection('users')
            .where('customId', isEqualTo: event.loginIdentifier)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final raw = userQuery.docs.first;
          userData = {...raw.data(), 'uid': raw.id};
          emailToUse = (userData['email'] ?? '').toString();
          userRole = (userData['userRole'] ?? '').toString();
          institutionId = userData['institutionId'] as String?;
        } else {
          final legacy = await _findUserInLegacySystem(event.loginIdentifier);
          if (legacy == null) {
            emit(const AuthErrorState(message: 'المستخدم غير موجود'));
            return;
          }
          userData = legacy;
          emailToUse = (userData['email'] ?? userData['headEmail'] ?? '').toString();
          userRole = (userData['userRole'] ?? '').toString();
          institutionId = userData['institutionId'] as String?;
        }
      }

      // تسجيل الدخول بالبريد/كلمة المرور
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: emailToUse,
        password: event.password,
      );
      final user = cred.user;
      if (user == null) {
        emit(const AuthErrorState(message: 'فشل تسجيل الدخول.'));
        return;
      }

      // لو ما معانا userData (دخل بالبريد مباشرة)، جيبه بالـ uid
      if (userData.isEmpty) {
        final fetched = await _getUserDataByUid(user.uid);
        if (fetched != null) {
          userData = fetched;
          userRole = (userData['userRole'] ?? 'unknown').toString();
          institutionId = userData['institutionId'] as String?;
        }
      }

      // حارس التفعيل (المهم!)
      final isActive = (userData['isActive'] as bool?) ?? true;
      if (!isActive) {
        await _firebaseAuth.signOut();
        emit(AuthUnauthenticated(
          message: 'تم إلغاء تفعيل حسابك. لن تتمكن من تسجيل الدخول.',
        ));
        return;
      }

      final userName =
          (userData['fullName'] ??
                  userData['headName'] ??
                  userData['email']?.toString().split('@').first ??
                  'User')
              .toString();

      emit(
        AuthAuthenticated(
          userRole: userRole.isEmpty ? 'unknown' : userRole,
          userName: userName,
          institutionId: institutionId ?? '',
          userData: userData,
        ),
      );
    } on FirebaseAuthException catch (e) {
      emit(
        AuthErrorState(
          message: e.message ?? 'فشل تسجيل الدخول، تحقق من البيانات.',
        ),
      );
    } catch (e) {
      emit(AuthErrorState(message: e.toString()));
    }
  }

  // ====== Reset Password ======
  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final error = await _authService.resetPassword(event.email);
      if (error != null) {
        emit(AuthErrorState(message: error));
        return;
      }
      emit(PasswordResetSent(email: event.email));
    } catch (e) {
      emit(AuthErrorState(message: 'فشل إرسال رابط التعيين: $e'));
    }
  }

  // ====== Sign Up ======
  Future<void> _onSignUpButtonPressed(
    SignUpButtonPressed event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await _authService.signUp(
        name: event.name,
        email: event.email,
        password: event.password,
        address: event.address,
        website: event.website,
        headName: event.headName,
        headEmail: event.headEmail,
        headMobileNumber: event.headMobileNumber,
        userRole: event.userRole,
        institutionId: event.institutionId,
        areaResponsibleFor: event.areaResponsibleFor,
        functionalLodgment: event.functionalLodgment,
      );

      if (result != null) {
        emit(AuthErrorState(message: result));
        return;
      }

      final user = _firebaseAuth.currentUser;
      if (user == null) {
        emit(const AuthErrorState(message: 'فشل الحصول على بيانات المستخدم بعد التسجيل'));
        return;
      }

      final data = await _getUserDataByUid(user.uid) ?? {};
      // حارس التفعيل بعد التسجيل (نادرًا)
      final isActive = (data['isActive'] as bool?) ?? true;
      if (!isActive) {
        await _firebaseAuth.signOut();
        emit(AuthUnauthenticated(
          message: 'تم إنشاء الحساب لكن غير مفعّل بعد.',
        ));
        return;
      }

      emit(
        AuthAuthenticated(
          userRole: event.userRole,
          userName: event.headName,
          institutionId: (data['institutionId'] ?? '').toString(),
          userData: data,
        ),
      );
    } catch (e) {
      emit(AuthErrorState(message: e.toString()));
    }
  }

  // ====== Logout ======
  Future<void> _onLogoutButtonPressed(
    LogoutButtonPressed event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.signOut();
    emit(AuthUnauthenticated());
  }

  Future<void> _onSignOutButtonPressed(
    SignOutButtonPressed event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.signOut();
    emit(AuthUnauthenticated());
  }

  // ====== Helpers ======

  // البحث في النظام القديم (kafala_heads / supervisors) بالـ customId أو supervisorNo
  Future<Map<String, dynamic>?> _findUserInLegacySystem(String identifier) async {
    try {
      final kafalaHeadSnapshot = await _firestoreService
          .collection('kafala_heads')
          .where('customId', isEqualTo: identifier)
          .limit(1)
          .get();

      if (kafalaHeadSnapshot.docs.isNotEmpty) {
        final d = kafalaHeadSnapshot.docs.first;
        return {...d.data(), 'uid': d.id};
      }

      final supervisorSnapshot = await _firestoreService
          .collection('supervisors')
          .where('supervisorNo', isEqualTo: identifier)
          .limit(1)
          .get();

      if (supervisorSnapshot.docs.isNotEmpty) {
        final d = supervisorSnapshot.docs.first;
        return {...d.data(), 'uid': d.id};
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // جلب بيانات المستخدم بالـ uid من users أولاً، ثم ترحيل النظام القديم إن لزم
  Future<Map<String, dynamic>?> _getUserDataByUid(String uid) async {
    try {
      final userDoc =
          await _firestoreService.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        return {...userDoc.data()!, 'uid': userDoc.id};
      }

      final kafalaHeadDoc =
          await _firestoreService.collection('kafala_heads').doc(uid).get();
      if (kafalaHeadDoc.exists && kafalaHeadDoc.data() != null) {
        final data = {...kafalaHeadDoc.data()!, 'uid': kafalaHeadDoc.id};
        await _migrateUserData(uid, data);
        return data;
      }

      final supervisorDoc =
          await _firestoreService.collection('supervisors').doc(uid).get();
      if (supervisorDoc.exists && supervisorDoc.data() != null) {
        final data = {...supervisorDoc.data()!, 'uid': supervisorDoc.id};
        await _migrateUserData(uid, data);
        return data;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ترحيل مستخدم للنظام الموحد
  Future<void> _migrateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestoreService.collection('users').doc(uid).set({
        'uid': uid,
        'userRole':
            data['userRole'] ??
            (data.containsKey('supervisorNo') ? 'supervisor' : 'kafala_head'),
        'institutionId': data['institutionId'] ?? '',
        'customId': data['customId'] ?? data['supervisorNo'] ?? _generateCustomId(),
        'permissions': data['permissions'] ?? [],
        'areaResponsibleFor': data['areaResponsibleFor'] ?? '',
        'functionalLodgment': data['functionalLodgment'] ?? '',
        'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
        'email': data['email'] ?? data['headEmail'] ?? '',
        'mobileNumber': data['mobileNumber'] ?? data['headMobileNumber'] ?? '',
        'fullName': data['fullName'] ?? data['headName'] ?? '',
        'institutionName': data['institutionName'] ?? '',
        'address': data['address'] ?? '',
        'kafalaHeadId':
            data['userRole'] == 'kafala_head' ? uid : (data['kafalaHeadId'] ?? ''),
        'isActive': data['isActive'] ?? true,
      }, SetOptions(merge: true));
    } catch (_) {/* تجاهل */}
  }

  String _generateCustomId() {
    final rnd = DateTime.now().millisecondsSinceEpoch % 900000 + 100000;
    return rnd.toString();
  }
}