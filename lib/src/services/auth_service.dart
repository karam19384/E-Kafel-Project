// lib/src/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:e_kafel/src/services/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // تسجيل الدخول بالبريد/كلمة مرور
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // تسجيل الدخول بجوجل
  Future<String?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return 'تم إلغاء تسجيل الدخول';

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // جلب بياناته من Firestore (kafala_heads / supervisors)
        final existingUser = await _firestoreService.getUserData(user.uid);

        if (existingUser == null) {
          // في حالتنا: ما بننشئ مستخدم جديد أوتوماتيكياً
          // لازم يكمّل التسجيل من شاشة تسجيل المؤسسة أو رئيس الكفالة
          return 'الحساب غير مسجّل في النظام. الرجاء استكمال التسجيل.';
        }
      }

      return null;
    } catch (e) {
      return 'فشل في تسجيل الدخول بجوجل: $e';
    }
  }

  /// تسجيل حساب جديد
  /// userRole: 'kafala_head' أو 'supervisor'
  /// لو أول تسجيل مؤسسة: institutionData مطلوب
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String role, // 'kafala_head' or 'supervisor'
    Map<String, dynamic>? institutionData,
    String? institutionId,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return 'فشل إنشاء الحساب';

      if (role == 'kafala_head') {
        if (institutionData == null) {
          return 'بيانات المؤسسة مطلوبة عند تسجيل رئيس قسم الكفالة';
        }

        final newInstitutionId = institutionId ?? user.uid;

        await _firestoreService.initializeNewInstitution(
          newInstitutionId,
          {...institutionData, 'ownerEmail': email, 'ownerName': name},
          {'uid': user.uid, 'name': name, 'email': email},
        );
      } else if (role == 'supervisor') {
        if (institutionId == null) {
          return 'institutionId مطلوب عند تسجيل مشرف جديد';
        }

        await _firestoreService.createSupervisor(institutionId, {
          'uid': user.uid,
          'name': name,
          'email': email,
        });
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
