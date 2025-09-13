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
        final userDoc = await _firestoreService.getUser(user.uid);
        if (userDoc == null) {
          // إذا كان المستخدم جديدًا، نقوم بإنشاء مستخدم جديد في Firestore
          await _firestoreService.createUser(user.uid, {
            'email': user.email,
            'name': user.displayName,
            'role': 'supervisor', // افتراضياً، دور المشرف
          });
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // تسجيل حساب جديد
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String address,
    required String website,
    required String headName,
    required String headEmail,
    required String headMobileNumber,
    required String userRole,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return 'فشل إنشاء الحساب';

      await _firestoreService.initializeNewInstitution(
        user.uid,
        {
          'name': name,
          'email': email,
          'address': address,
          'website': website,
          'headName': headName,
          'headEmail': headEmail,
          'headMobileNumber': headMobileNumber,
        },
        {
          'uid': user.uid,
          'name': name,
          'email': email,
          'userRole': userRole,
          'institutionId': user.uid,
        },
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
}