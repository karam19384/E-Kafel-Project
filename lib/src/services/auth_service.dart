// lib/src/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ دالة مساعدة لتوليد customId فريد
  String _generateCustomId() {
    final random = DateTime.now().millisecondsSinceEpoch % 900000 + 100000;
    return random.toString();
  }

  // ✅ دالة لملء البيانات الناقصة للمستخدمين القدامى
  Future<void> _migrateUserData(
    String uid,
    Map<String, dynamic> additionalData,
  ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        // إنشاء مستخدم جديد في النظام الموحد
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'userRole': additionalData['userRole'] ?? 'supervisor',
          'institutionId': additionalData['institutionId'] ?? '',
          'customId': additionalData['customId'] ?? _generateCustomId(),
          'permissions': additionalData['permissions'] ?? [],
          'areaResponsibleFor': additionalData['areaResponsibleFor'] ?? '',
          'functionalLodgment': additionalData['functionalLodgment'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'email': additionalData['email'] ?? '',
          'mobileNumber':
              additionalData['mobileNumber'] ??
              additionalData['headMobileNumber'] ??
              '',
          'name': additionalData['name'] ?? additionalData['headName'] ?? '',
          'institutionName': additionalData['institutionName'] ?? '',
          'address': additionalData['address'] ?? '',
          'kafalaHeadId': additionalData['userRole'] == 'kafala_head'
              ? uid
              : additionalData['kafalaHeadId'] ?? '',
        });
      }
    } catch (e) {
      print('Migration error: $e');
    }
  }

  /// إنشاء حساب مشرف دون تبديل جلسة رئيس القسم (باستعمال App ثانوي)
  Future<String> createSupervisorAccount({
    required Map<String, dynamic> supervisorData,
    required String password,
  }) async {
    final secondary = await Firebase.initializeApp(
      name: 'secondary',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondary);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: supervisorData['email'] as String,
        password: password,
      );
      final uid = cred.user!.uid;

      // خزن بيانات المستخدم
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'userRole': 'supervisor',
        'isActive': supervisorData['isActive'] ?? true,
        'kafalaHeadId': supervisorData['kafalaHeadId'],
        'institutionId': supervisorData['institutionId'],
        'institutionName': supervisorData['institutionName'],
        'fullName': supervisorData['fullName'] ?? '',
        'email': supervisorData['email'],
        'mobileNumber': supervisorData['mobileNumber'] ?? '',
        'customId': supervisorData['customId'] ?? '',
        'areaResponsibleFor': supervisorData['areaResponsibleFor'] ?? '',
        'functionalLodgment': supervisorData['functionalLodgment'] ?? '',
        'address': supervisorData['address'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'profileImageUrl': supervisorData['profileImageUrl'] ?? '',
        'permissions': supervisorData['permissions'] ?? <String>[],
      }, SetOptions(merge: true));

      return uid;
    } finally {
      await secondary.delete();
    }
  }

  // ✅ تسجيل الدخول المحسن (يدعم النظام القديم والجديد)
  Future<String?> signIn({
    required String loginIdentifier,
    required String password,
  }) async {
    String email = loginIdentifier;
    Map<String, dynamic>? userData;

    try {
      // البحث في النظام الجديد (users collection)
      if (!loginIdentifier.contains('@')) {
        final userQuery = await _firestore
            .collection('users')
            .where('customId', isEqualTo: loginIdentifier)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          userData = userQuery.docs.first.data();
          email = userData['email'] ?? '';
        } else {
          // البحث في النظام القديم للتوافق
          final kafalaQuery = await _firestore
              .collection('kafala_heads')
              .where('customId', isEqualTo: loginIdentifier)
              .limit(1)
              .get();

          if (kafalaQuery.docs.isNotEmpty) {
            userData = kafalaQuery.docs.first.data();
            email = userData['email'] ?? userData['headEmail'] ?? '';
          } else {
            final supervisorQuery = await _firestore
                .collection('supervisors')
                .where('supervisorNo', isEqualTo: loginIdentifier)
                .limit(1)
                .get();

            if (supervisorQuery.docs.isNotEmpty) {
              userData = supervisorQuery.docs.first.data();
              email = userData['email'] ?? '';
            } else {
              return 'المعرف غير موجود';
            }
          }
        }
      }

      if (email.isEmpty) return 'لا يوجد بريد مرتبط بالمستخدم';

      // تسجيل الدخول
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null && userData != null) {
        // ترحيل البيانات إذا لزم الأمر
        await _migrateUserData(user.uid, userData);
      }

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'المستخدم غير موجود. تأكد من صحة البيانات';
      } else if (e.code == 'wrong-password') {
        return 'كلمة المرور غير صحيحة';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ✅ تسجيل حساب جديد مع النظام الموحد
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
    required String institutionId,
    required String areaResponsibleFor,
    required String functionalLodgment,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: headEmail,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return 'فشل إنشاء الحساب';

      // ✅ إنشاء معرف فريد
      final customId = _generateCustomId();

      // ✅ إنشاء وثيقة المؤسسة
      final institutionRef = _firestore.collection('institutions').doc();
      final newInstitutionId = institutionRef.id;

      await institutionRef.set({
        'institutionId': newInstitutionId,
        'institutionName': name,
        'email': email,
        'address': address,
        'website': website,
        'createdAt': FieldValue.serverTimestamp(),
        'kafala_head': {
          'name': headName,
          'kafalaHeadEmail': headEmail,
          'kafalaHeadMobileNumber': headMobileNumber,
          'customId': customId,
          'createdAt': FieldValue.serverTimestamp(),
        },
      });

      // ✅ إنشاء المستخدم في النظام الموحد
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'userRole': 'kafala_head',
        'institutionId': newInstitutionId,
        'customId': customId,
        'permissions': ['all'], // جميع الصلاحيات لرئيس القسم
        'areaResponsibleFor': areaResponsibleFor,
        'functionalLodgment': functionalLodgment,
        'createdAt': FieldValue.serverTimestamp(),
        'email': headEmail,
        'mobileNumber': headMobileNumber,
        'name': headName,
        'institutionName': name,
        'address': address,
        'kafalaHeadId': user.uid, // نفس الـ uid لرئيس القسم
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }


  // ✅ إعادة تعيين كلمة المرور
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ✅ الحصول على بيانات المستخدم من النظام الموحد
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data();
      }

      // البحث في النظام القديم للتوافق
      final kafalaDoc = await _firestore
          .collection('kafala_heads')
          .doc(uid)
          .get();
      if (kafalaDoc.exists) {
        final data = kafalaDoc.data()!;
        await _migrateUserData(uid, data); // ترحيل البيانات
        return data;
      }

      final supervisorDoc = await _firestore
          .collection('supervisors')
          .doc(uid)
          .get();
      if (supervisorDoc.exists) {
        final data = supervisorDoc.data()!;
        await _migrateUserData(uid, data); // ترحيل البيانات
        return data;
      }

      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

Future<String?> createUserWithEmailAndPassword({
  required String email,
  required String password,
  required Map<String, dynamic> userData,
}) async {
  try {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user == null) return null;

    // تأكد من وجود UID في البيانات
    final dataWithUid = {
      ...userData,
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    };

    await _firestore.collection('users').doc(user.uid).set(dataWithUid);
    return user.uid;
  } catch (e) {
    debugPrint('Error creating user with email/password: $e');
    rethrow;
  }
}
}
