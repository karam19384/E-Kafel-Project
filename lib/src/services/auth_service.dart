// lib/src/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:e_kafel/src/services/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;  // ✅ أضف هذا


  // تسجيل الدخول بالبريد/كلمة مرور أو المعرف الفريد
  Future<String?> signIn({
    required String loginIdentifier, // تم تغيير اسم المتغير
    required String password,
  }) async {
    String email = loginIdentifier;
    // التحقق مما إذا كان المعرف هو معرف فريد (6 أرقام)
    if (loginIdentifier.length == 6 && int.tryParse(loginIdentifier) != null) {
      final userDoc = await _firestoreService.getUserByCustomId(loginIdentifier);
      if (userDoc == null) {
        return 'المعرف غير موجود';
      }
      final userData = userDoc.data() as Map<String, dynamic>;
      email = userData['email'];
    }

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'المستخدم غير موجود. تأكد من إدخال المعرف بشكل صحيح.';
      }
      return e.message;
    }
  }
    // ✅ استرجاع userRole من Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      // البحث أولاً في kafala_head
      final kafalaDoc = await _firestore.collection('kafala_head').doc(uid).get();
      if (kafalaDoc.exists) {
        return kafalaDoc.data()?['userRole'] ?? 'kafala_head';
      }

      // البحث ثانياً في supervisor
      final supervisorDoc = await _firestore.collection('supervisor').doc(uid).get();
      if (supervisorDoc.exists) {
        return supervisorDoc.data()?['userRole'] ?? 'supervisor';
      }

      return null;
    } catch (e) {
      print("Error fetching userRole: $e");
      return null;
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
        email: headEmail,
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
          'name': headName,
          'email': headEmail,
          'headMobileNumber': headMobileNumber,
          'userRole': userRole,
          'customId': _firestoreService.generateCustomId(), // توليد وحفظ المعرف الفريد
        },
      );
      
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
            'role': 'kafala_head', 
          });
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
}