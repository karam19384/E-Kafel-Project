// lib/src/services/firestore_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/orphan_model.dart';
import '../models/profile_model.dart';
import '../models/setting_model.dart';
import '../models/sponsorship_model.dart';
import '../models/tasks_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // تعريف collections المفقودة
  CollectionReference<Map<String, dynamic>> get _projectsCol =>
      _firestore.collection('sponsorship_projects');

  /// helper
  CollectionReference<Map<String, dynamic>> collection(String name) =>
      _firestore.collection(name);

  // إنشاء مشروع جديد
  Future<String> createSponsorshipProject(SponsorshipProject project) async {
    final doc = _projectsCol.doc();
    final data = project
        .copyWith(
          id: doc.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )
        .toMap();
    data['id'] = doc.id; // إن أردت حفظ ال id داخل الوثيقة
    await doc.set(data);
    return doc.id;
  }

  // تحديث مشروع
  Future<void> updateSponsorshipProject(SponsorshipProject project) async {
    await _projectsCol.doc(project.id).update({
      ...project.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // أرشفة/تغيير حالة
  Future<void> setSponsorshipProjectStatus(
    String projectId,
    String status,
  ) async {
    await _projectsCol.doc(projectId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // حذف (في الغالب تكتفي بالأرشفة)
  Future<void> deleteSponsorshipProject(String projectId) async {
    await _projectsCol
        .doc(projectId)
        .delete(); // إصلاح: استخدام _projectsCol بدلاً من collection
  }

  // جلب قائمة المشاريع (مع فلاتر اختيارية)
  Future<List<SponsorshipProject>> listSponsorshipProjects({
    required String institutionId,
    String? status, // active | pending | completed | archived
    String? type,
    String? search, // بالاسم
  }) async {
    Query<Map<String, dynamic>> q = _projectsCol.where(
      'institutionId',
      isEqualTo: institutionId,
    );

    if (status != null && status.isNotEmpty) {
      q = q.where('status', isEqualTo: status);
    }
    if (type != null && type.isNotEmpty) {
      q = q.where('type', isEqualTo: type);
    }

    final snap = await q.orderBy('createdAt', descending: true).get();

    var list = snap.docs
        .map((d) => SponsorshipProject.fromMap(d.data(), d.id))
        .toList();

    if (search != null && search.trim().isNotEmpty) {
      final s = search.trim().toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(s)).toList();
    }

    return list;
  }

  // إضافة حدث داخل مشروع
  Future<void> addSponsorshipEvent({
    required String projectId,
    required SponsorshipEventItem event,
  }) async {
    final col = _projectsCol.doc(projectId).collection('events');
    final doc = col.doc();
    await doc.set(event.copyWith(id: doc.id).toMap());
  }

  // قراءة أحداث مشروع (اختياري)
  Future<List<SponsorshipEventItem>> listSponsorshipEvents(
    String projectId,
  ) async {
    final col = _projectsCol.doc(projectId).collection('events');
    final snap = await col.orderBy('timestamp', descending: true).get();
    return snap.docs
        .map((d) => SponsorshipEventItem.fromMap(d.data(), d.id))
        .toList();
  }



// استبدل هذه الدالة (لا تحذف نهائياً من Firestore):
Future<void> removeSupervisor(String uid) async {
  // ممنوع الحذف — سنكتفي بتعطيل الحساب
  await _firestore.collection('users').doc(uid).update({
    'isActive': false,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

// أضِف:
Future<void> toggleSupervisorActive(String uid, bool isActive) async {
  await _firestore.collection('users').doc(uid).update({
    'isActive': isActive,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

// عدّل listSupervisors ليقبل kafalaHeadId ويُفلتر:
Future<List<UserModel>> listSupervisors(String institutionId, {String? kafalaHeadId}) async {
  Query<Map<String, dynamic>> q = _firestore
      .collection('users')
      .where('institutionId', isEqualTo: institutionId)
      .where('userRole', isEqualTo: 'supervisor');

  if (kafalaHeadId != null && kafalaHeadId.isNotEmpty) {
    q = q.where('kafalaHeadId', isEqualTo: kafalaHeadId);
  }

  final snap = await q.get();
  return snap.docs.map((d) => UserModel.fromMap({...d.data(), 'uid': d.id})).toList();
}


  // ====================== المستخدمون (موحّد) ======================

  Future<String> createUser(Map<String, dynamic> userData) async {
    try {
      final docRef = _firestore.collection('users').doc();
      final userId = docRef.id;

      final dataToSave = <String, dynamic>{
        'uid': userId,
        ...userData,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': userData['isActive'] ?? true,
      };

      await docRef.set(dataToSave);
      return userId;
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

// في firestore_service.dart
Future<Map<String, dynamic>?> getInstitutionData(String institutionId) async {
  try {
    final doc = await _firestore.collection('institutions').doc(institutionId).get();
    if (!doc.exists) return null;
    return doc.data();
  } catch (e) {
    debugPrint('Error getting institution data: $e');
    return null;
  }
}

Future<String> getInstitutionName(String institutionId) async {
  try {
    final data = await getInstitutionData(institutionId);
    return data?['institutionName'] as String? ?? 'غير محدد';
  } catch (e) {
    debugPrint('Error getting institution name: $e');
    return 'غير محدد';
  }
}
  Future<Map<String, dynamic>?> findUserByUniqueNumber(String unique) async {
    try {
      // users
      final uq = await _firestore
          .collection('users')
          .where('customId', isEqualTo: unique)
          .limit(1)
          .get();

      if (uq.docs.isNotEmpty) {
        final d = uq.docs.first;
        final data = d.data();
        return {...data, '__collection': 'users', '__docId': d.id};
      }

      // legacy: supervisors
      final supQ = await _firestore
          .collection('supervisors')
          .where('supervisorNo', isEqualTo: unique)
          .limit(1)
          .get();

      if (supQ.docs.isNotEmpty) {
        final d = supQ.docs.first;
        final data = d.data();
        return {...data, '__collection': 'supervisors', '__docId': d.id};
      }

      // legacy: kafala_heads
      final headQ = await _firestore
          .collection('kafala_heads')
          .where('customId', isEqualTo: unique)
          .limit(1)
          .get();

      if (headQ.docs.isNotEmpty) {
        final d = headQ.docs.first;
        final data = d.data();
        return {...data, '__collection': 'kafala_heads', '__docId': d.id};
      }

      return null;
    } catch (e) {
      debugPrint("findUserByUniqueNumber error: $e");
      return null;
    }
  }

  Future<void> migrateUserToUnifiedSystem(
    String uid,
    Map<String, dynamic> legacyData,
  ) async {
    try {
      final userRole =
          legacyData['userRole'] ??
          (legacyData.containsKey('supervisorNo')
              ? 'supervisor'
              : 'kafala_head');

      final userData = <String, dynamic>{
        'uid': uid,
        'userRole': userRole,
        'institutionId': legacyData['institutionId'] ?? '',
        'customId':
            legacyData['customId'] ??
            legacyData['supervisorNo'] ??
            generateCustomId(),
        'permissions': legacyData['permissions'] ?? <String>[],
        'areaResponsibleFor': legacyData['areaResponsibleFor'] ?? '',
        'functionalLodgment': legacyData['functionalLodgment'] ?? '',
        'createdAt': legacyData['createdAt'] ?? FieldValue.serverTimestamp(),
        'email': legacyData['email'] ?? legacyData['headEmail'] ?? '',
        'mobileNumber':
            legacyData['mobileNumber'] ?? legacyData['headMobileNumber'] ?? '',
        'name': legacyData['name'] ?? legacyData['headName'] ?? '',
        'institutionName': legacyData['institutionName'] ?? '',
        'address': legacyData['address'] ?? '',
        'kafalaHeadId': userRole == 'kafala_head'
            ? uid
            : (legacyData['kafalaHeadId'] ?? ''),
        'isActive': legacyData['isActive'] ?? legacyData['is_active'] ?? true,
      };

      await _firestore
          .collection('users')
          .doc(uid)
          .set(userData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error migrating user: $e');
    }
  }

  Future<bool> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUsersByInstitution(
    String institutionId, {
    String? userRole,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .where('institutionId', isEqualTo: institutionId)
          .where('isActive', isEqualTo: true);

      if (userRole != null && userRole.isNotEmpty) {
        query = query.where('userRole', isEqualTo: userRole);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs
          .map((doc) => {'uid': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('Error getting users by institution: $e');
      return [];
    }
  }

  // ====================== الملف الشخصي ======================

  CollectionReference<Map<String, dynamic>> get usersCol =>
      _firestore.collection('users');

  Future<Profile?> getProfileByUid(String uid) async {
    final doc = await usersCol.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    final map = {...doc.data()!, 'uid': doc.id};
    return Profile.fromMap(map);
  }

  Future<void> updateProfileFields(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await usersCol.doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
      // لا نسمح بتعديل customId/institutionName هنا
      // أبقها ممنوعة من الـ UI أيضاً
    });
  }

  Future<void> updateEmailInDoc(String uid, String email) =>
      updateProfileFields(uid, {'email': email});

  Future<void> updatePhoneInDoc(String uid, String phone) =>
      updateProfileFields(uid, {'mobileNumber': phone});

  // ====================== الإعدادات ======================

  Future<SettingsModel?> getSettings(String userId) async {
    final doc = await _firestore.collection('settings').doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return SettingsModel.fromMap(doc.data()!);
  }

  Future<void> saveSettings(String userId, SettingsModel settings) async {
    await _firestore
        .collection('settings')
        .doc(userId)
        .set(settings.toMap(), SetOptions(merge: true));
  }

  // ====================== المؤسسات ======================

  Future<void> initializeNewInstitution(
    String institutionId,
    Map<String, dynamic> institutionData,
    Map<String, dynamic> kafalaHeadData,
    String institutionName,
  ) async {
    final institutionRef = _firestore
        .collection('institutions')
        .doc(institutionId);

    final customId = kafalaHeadData['customId'] ?? _generateCustomId();

    final dataWithHead = {
      ...institutionData,
      'institutionId': institutionId,
      'institutionName': institutionName,
      'createdAt': FieldValue.serverTimestamp(),
      'headName': kafalaHeadData['name'],
      'headEmail': kafalaHeadData['email'],
      'headMobileNumber': kafalaHeadData['headMobileNumber'],
      'kafalaHeadId': kafalaHeadData['kafalaHeadId'],
      'kafalaHeadCustomId': customId,
      'kafalaHeadCreatedAt': FieldValue.serverTimestamp(),
    };

    await institutionRef.set(dataWithHead, SetOptions(merge: true));
  }

  Future<void> deleteInstitutionCompletely(String institutionId) async {
    // ملاحظة: عمليات الحذف المتعددة قد تحتاج Cloud Functions أو batch/recursive delete
    final fs = _firestore;

    Future<void> _deleteColl(String coll, String field) async {
      final qs = await fs
          .collection(coll)
          .where(field, isEqualTo: institutionId)
          .get();
      for (final d in qs.docs) {
        await d.reference.delete();
      }
    }

    await _deleteColl('kafala_heads', 'institutionId');
    await _deleteColl('supervisors', 'institutionId');
    await _deleteColl('orphans', 'institutionId');
    await _deleteColl('sponsorships', 'institutionId');
    await _deleteColl('visits', 'institutionId');
    await fs.collection('institutions').doc(institutionId).delete();
  }

  // ====================== المشرفون ======================

 Future<String?> createSupervisorWithAuth({
  required Map<String, dynamic> supervisorData,
  required String password,
}) async {
  try {
    final authService = AuthService();
    
    // استخدام الدالة الصحيحة من AuthService
    final uid = await authService.createSupervisorAccount(
      supervisorData: supervisorData,
      password: password,
    );
    
    return uid;
  } catch (e) {
    debugPrint('Error creating supervisor with auth: $e');
    rethrow;
  }
}
  // دالة مساعدة لإنشاء مستخدم مع مصادقة
  Future<String> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // إنشاء مستخدم في Authentication
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final String uid = userCredential.user!.uid;

      // حفظ بيانات المستخدم في Firestore
      final userDoc = _firestore.collection('users').doc(uid);
      final dataToSave = <String, dynamic>{
        'uid': uid,
        ...userData,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      await userDoc.set(dataToSave);
      return uid;
    } catch (e) {
      debugPrint('Error creating user with email/password: $e');
      rethrow;
    }
  }

  Future<void> updateSupervisor(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<UserModel?> getSupervisorById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    final map = {...doc.data()!, 'uid': doc.id};
    return UserModel.fromMap(map);
  }
    
     Future<List<UserModel>> searchSupervisors({
    required String institutionId,
    String? search,
    String? userRole, // استخدم userRole لو متاح
    String? areaResponsibleFor,
    bool? isActive,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .where('institutionId', isEqualTo: institutionId);

    if (userRole != null && userRole.isNotEmpty) {
      // إن كنت تستخدم userRole بدلاً من userRole غيّر هنا
      query = query.where('userRole', isEqualTo: userRole);
    }
    if (areaResponsibleFor != null && areaResponsibleFor.isNotEmpty) {
      query = query.where('areaResponsibleFor', isEqualTo: areaResponsibleFor);
    }
    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }

    final snap = await query.get();

    List<UserModel> list = snap.docs
        .map((d) => UserModel.fromMap({...d.data(), 'uid': d.id}))
        .toList();

    if (search != null && search.trim().isNotEmpty) {
      final s = search.trim().toLowerCase();

      list = list.where((u) {
        final name = (u.fullName).toLowerCase();
        final email = (u.email).toLowerCase();
        final mobile = (u.mobileNumber).toString().toLowerCase();
        final customId = (u.customId).toLowerCase();

        return name.contains(s) ||
            email.contains(s) ||
            mobile.contains(s) ||
            customId.contains(s);
      }).toList();
    }

    return list;
  }
// ====================== الإشعارات ======================
 // ===== إشعارات موجهة للمستخدم =====
  Future<void> notifyUser({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
    Map<String, dynamic>? extra,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      ...?extra,
    });
  }



  // ===== جلب مشرفين لرئيس قسم معيّن =====
  Future<List<Map<String, dynamic>>> listSupervisorsByHead({
    required String institutionId,
    required String kafalaHeadId,
    bool? isActive,
  }) async {
    Query<Map<String, dynamic>> q = _firestore
        .collection('users')
        .where('institutionId', isEqualTo: institutionId)
        .where('userRole', isEqualTo: 'supervisor')
        .where('kafalaHeadId', isEqualTo: kafalaHeadId);

    if (isActive != null) q = q.where('isActive', isEqualTo: isActive);

    final snap = await q.orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
  }

  Future<Map<String, dynamic>?> getUserById(String uid) async {
    final d = await _firestore.collection('users').doc(uid).get();
    return d.data();
  }

  // جلب اسم رئيس القسم من ID
  Future<String> getHeadNameById(String headUid) async {
    final d = await _firestore.collection('users').doc(headUid).get();
    final data = d.data();
    if (data == null) return '—';
    return (data['fullName'] as String?)?.trim().isNotEmpty == true
        ? data['fullName'] as String
        : '—';
  }
/// تحميل إشعارات مستخدم مع ترقيم صفحات (Page Size افتراضي = 20)
Future<List<Map<String, dynamic>>> getNotificationsPage(
  String uid, {
  int limit = 20,
  DocumentSnapshot<Map<String, dynamic>>? startAfter,
}) async {
  try {
    Query<Map<String, dynamic>> q = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.get();
    return snap.docs.map((d) => {
      ...d.data(),
      'notificationId': d.id,
      '__doc': d, // مفيد لإحضاره كنقطة startAfter لاحقًا
    }).toList();
  } catch (e) {
    debugPrint('Error getNotificationsPage: $e');
    return [];
  }
}

/// نسخة بسيطة بدون ترقيم صفحات (تبقى موجودة إن احتجتها)
Future<List<Map<String, dynamic>>> getNotifications(String uid) async {
  try {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(100) // لا تجيب كل شيء مرّة واحدة
        .get();

    return snapshot.docs.map((d) => {
      ...d.data(),
      'notificationId': d.id,
    }).toList();
  } catch (e) {
    debugPrint('Error getting notifications: $e');
    return [];
  }
}

/// إنشاء إشعار واحد وإرجاع ID — مع ضمان وجود timestamp و isRead
Future<String> createNotification(Map<String, dynamic> data) async {
  final ref = _firestore.collection('notifications').doc();
  final payload = {
    ...data,
    'notificationId': ref.id,
    'timestamp': data['timestamp'] ?? FieldValue.serverTimestamp(),
    'isRead': data['isRead'] ?? false,
  };

  await ref.set(payload);
  return ref.id;
}

/// إرسال إشعار لكل مستخدمي مؤسسة معيّنة (Batch + تقطيع لتفادي حد 500)
Future<List<String>> sendNotificationToInstitution(
  String institutionId,
  String title,
  String message, {
  String? type,
  Map<String, dynamic>? extra, // بيانات إضافية لعرض مخصص
}) async {
  final createdIds = <String>[];
  try {
    final users = await getUsersByInstitution(institutionId);
    if (users.isEmpty) return createdIds;

    const int batchLimit = 450; // أقل من 500 لسلامة الهامش
    final chunks = <List<Map<String, dynamic>>>[];

    // قسّم المستخدمين على دفعات
    for (var i = 0; i < users.length; i += batchLimit) {
      chunks.add(users.sublist(
        i,
        i + batchLimit > users.length ? users.length : i + batchLimit,
      ));
    }

    for (final chunk in chunks) {
      final batch = _firestore.batch();

      for (final user in chunk) {
        final uid = (user['uid'] ?? user['id'])?.toString() ?? '';
        if (uid.isEmpty) continue;

        final ref = _firestore.collection('notifications').doc();
        createdIds.add(ref.id);

        final data = {
          'notificationId': ref.id,
          'userId': uid,
          'title': title,
          'message': message,
          'type': type ?? 'general',
          'institutionId': institutionId,
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
          if (extra != null) ...{'extra': extra},
        };

        batch.set(ref, data);
      }

      await batch.commit();
    }

    // (اختياري) نطلق دفع FCM عبر Cloud Function callable بعد الحفظ
    // جرّب استدعاء دالة HTTPS ترسل Push حسب اليوزر/التوبيك:
    // await FirebaseFunctions.instanceFor(region: 'us-central1')
    //   .httpsCallable('notifyInstitutionUsers')
    //   .call({'institutionId': institutionId, 'title': title, 'body': message, 'type': type ?? 'general'});

    return createdIds;
  } catch (e) {
    debugPrint('Error sending notification to institution: $e');
    return createdIds;
  }
}

/// وضع إقرأ/غير مقروء لإشعار واحد
Future<void> markNotificationRead(
  String notificationId, {
  bool isRead = true,
}) async {
  await _firestore.collection('notifications').doc(notificationId).update({
    'isRead': isRead,
    'readAt': isRead ? FieldValue.serverTimestamp() : null,
  });
}

/// تمييز كل إشعارات المستخدم كمقروءة (Batch)
Future<void> markAllNotificationsReadForUser(String uid) async {
  try {
    final q = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .limit(450)
        .get();

    if (q.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final d in q.docs) {
      batch.update(d.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  } catch (e) {
    debugPrint('markAllNotificationsReadForUser error: $e');
  }
}

/// ستريم عدّاد غير المقروء (لأيقونة الجرس في الـ AppBar)
Stream<int> unreadCountStream(String uid) {
  return _firestore
      .collection('notifications')
      .where('userId', isEqualTo: uid)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((s) => s.size);
}

  // ====================== الأيتام (Orphans) ======================

  Future<List<Orphan>> getOrphansByInstitution(
    String institutionId, {
    Map<String, dynamic>? filters,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('orphans')
          .where('institutionId', isEqualTo: institutionId)
          .where('isArchived', isEqualTo: false);

      if (filters != null) {
        if (filters['gender'] != null && filters['gender'] != '') {
          query = query.where('gender', isEqualTo: filters['gender']);
        }
        if (filters['orphanType'] != null && filters['orphanType'] != '') {
          query = query.where('orphanType', isEqualTo: filters['orphanType']);
        }
        if (filters['sponsorshipStatus'] != null &&
            filters['sponsorshipStatus'] != '') {
          query = query.where(
            'sponsorshipStatus',
            isEqualTo: filters['sponsorshipStatus'],
          );
        }
        if (filters['governorate'] != null && filters['governorate'] != '') {
          query = query.where('governorate', isEqualTo: filters['governorate']);
        }
        if (filters['city'] != null && filters['city'] != '') {
          query = query.where('city', isEqualTo: filters['city']);
        }
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs
          .map((doc) => Orphan.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting orphans: $e');
      return [];
    }
  }

  Future<Orphan?> getOrphanById(String orphanId) async {
    try {
      final doc = await _firestore.collection('orphans').doc(orphanId).get();
      if (!doc.exists || doc.data() == null) return null;
      return Orphan.fromMap(doc.data()!, id: doc.id);
    } catch (e) {
      debugPrint('Error getting orphan by ID: $e');
      return null;
    }
  }

  Future<String?> createOrphan(Orphan orphan) async {
    try {
      final orphanNo = await _generateNewOrphanNumber(
        orphan.institutionId,
      ); // unique
      final data = orphan.copyWith(orphanNo: orphanNo).toMap();

      final docRef = await _firestore.collection('orphans').add(data);
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating orphan: $e');
      return null;
    }
  }

  Future<bool> updateOrphanData(
    String orphanId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('orphans').doc(orphanId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating orphan: $e');
      return false;
    }
  }

  Future<bool> archiveOrphanData(String orphanId) async {
    try {
      await _firestore.collection('orphans').doc(orphanId).update({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error archiving orphan: $e');
      return false;
    }
  }

  Future<List<Orphan>> searchOrphans({
    required String institutionId,
    required String searchTerm,
    Map<String, dynamic>? filters,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('orphans')
          .where('institutionId', isEqualTo: institutionId)
          .where('isArchived', isEqualTo: false);

      if (searchTerm.isNotEmpty) {
        // يتطلب وجود fullName مفهرس أو searchKeywords
        query = query
            .where('fullName', isGreaterThanOrEqualTo: searchTerm)
            .where('fullName', isLessThan: '$searchTerm\uf8ff');
      }

      if (filters != null) {
        if (filters['gender'] != null && filters['gender'] != '') {
          query = query.where('gender', isEqualTo: filters['gender']);
        }
        if (filters['orphanType'] != null && filters['orphanType'] != '') {
          query = query.where('orphanType', isEqualTo: filters['orphanType']);
        }
      }

      final snapshot = await query.orderBy('fullName').limit(50).get();

      return snapshot.docs
          .map((doc) => Orphan.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error searching orphans: $e');
      return [];
    }
  }

  Future<int?> getOrphansCount(
    String institutionId, {
    bool includeArchived = false,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('orphans')
          .where('institutionId', isEqualTo: institutionId);

      if (!includeArchived) {
        query = query.where('isArchived', isEqualTo: false);
      }

      try {
        final snapshot = await query.count().get();
        return snapshot.count;
      } catch (_) {
        final snap = await query.get();
        return snap.size;
      }
    } catch (e) {
      debugPrint('Error getting orphans count: $e');
      return 0;
    }
  }

  Future<int?> getArchivedOrphansCount(String institutionId) async {
    try {
      final baseQuery = _firestore
          .collection('orphans')
          .where('institutionId', isEqualTo: institutionId)
          .where('isArchived', isEqualTo: true);

      try {
        final agg = await baseQuery.count().get();
        return agg.count;
      } catch (_) {
        final snap = await baseQuery.get();
        return snap.size;
      }
    } catch (e) {
      debugPrint('getArchivedOrphansCount error: $e');
      return 0;
    }
  }

  Future<int> _generateNewOrphanNumber(String institutionId) async {
    final counterRef = _firestore
        .collection('counters')
        .doc('orphanCounter_$institutionId');

    return _firestore.runTransaction<int>((tx) async {
      final counterDoc = await tx.get(counterRef);
      int newNumber;
      if (counterDoc.exists && counterDoc.data() != null) {
        final currentNumber =
            (counterDoc.data()!['lastOrphanNo'] as int?) ?? 10000;
        newNumber = currentNumber + 1;
      } else {
        newNumber = 10001;
      }
      tx.set(counterRef, {'lastOrphanNo': newNumber});
      return newNumber;
    });
  }

  /// استعلام مرن للأيتام
  Query<Map<String, dynamic>> getOrphansQuery({
    required String institutionId,
    String? searchTerm,
    String? gender,
    bool includeArchived = false,
    DateTime? minBirthDate,
    DateTime? maxBirthDate,
    DateTime? minDeathDate,
    DateTime? maxDeathDate,
    double? minKafala,
    double? maxKafala,
    bool onlyIncomplete = false,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('orphans')
        .where('institutionId', isEqualTo: institutionId);

    if (!includeArchived) {
      query = query.where('isArchived', isEqualTo: false);
    }
    if (onlyIncomplete) {
      query = query.where('isDataComplete', isEqualTo: false);
    }
    if (gender != null && gender.isNotEmpty) {
      query = query.where('gender', isEqualTo: gender);
    }
    if (minBirthDate != null) {
      query = query.where(
        'dateOfBirth',
        isGreaterThanOrEqualTo: Timestamp.fromDate(minBirthDate),
      );
    }
    if (maxBirthDate != null) {
      query = query.where(
        'dateOfBirth',
        isLessThanOrEqualTo: Timestamp.fromDate(maxBirthDate),
      );
    }
    if (minDeathDate != null) {
      query = query.where(
        'dateOfDeath',
        isGreaterThanOrEqualTo: Timestamp.fromDate(minDeathDate),
      );
    }
    if (maxDeathDate != null) {
      query = query.where(
        'dateOfDeath',
        isLessThanOrEqualTo: Timestamp.fromDate(maxDeathDate),
      );
    }
    if (minKafala != null) {
      query = query.where('kafalaAmount', isGreaterThanOrEqualTo: minKafala);
    }
    if (maxKafala != null) {
      query = query.where('kafalaAmount', isLessThanOrEqualTo: maxKafala);
    }
    if (searchTerm != null && searchTerm.isNotEmpty) {
      // يتطلب searchKeywords Array مفهرس مسبقاً
      query = query.where(
        'searchKeywords',
        arrayContains: searchTerm.toLowerCase(),
      );
    }

    return query.orderBy('createdAt', descending: true);
  }

  Future<String?> addOrphan({
    required Map<String, dynamic> orphanData,
    required String institutionId,
  }) async {
    try {
      final ref = _firestore.collection('orphans').doc();
      final id = ref.id;

      final orphanNo = await _generateNewOrphanNumber(institutionId);

      final List<String> keywords = [];
      if ((orphanData['name'] ?? '').toString().isNotEmpty) {
        keywords.addAll(_generateSearchKeywords(orphanData['name']));
      }
      if (orphanData['orphanIdNumber'] != null) {
        keywords.add(orphanData['orphanIdNumber'].toString());
      }
      if ((orphanData['deceasedName'] ?? '').toString().isNotEmpty) {
        keywords.addAll(_generateSearchKeywords(orphanData['deceasedName']));
      }
      if ((orphanData['breadwinnerName'] ?? '').toString().isNotEmpty) {
        keywords.addAll(_generateSearchKeywords(orphanData['breadwinnerName']));
      }

      await ref.set({
        ...orphanData,
        'institutionId': institutionId,
        'orphanId': id,
        'orphanNo': orphanNo,
        'searchKeywords': keywords,
        'createdAt': FieldValue.serverTimestamp(),
        'isDataComplete': orphanData['isDataComplete'] ?? false,
        'isArchived': orphanData['isArchived'] ?? false,
      });

      await sendNotificationToInstitution(
        institutionId,
        'تم إضافة يتيم جديد',
        'تم إضافة اليتيم ${orphanData['name']} إلى النظام',
      );

      return id;
    } catch (e) {
      debugPrint('Error adding orphan: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getOrphanData(String orphanId) async {
    try {
      final d = await _firestore.collection('orphans').doc(orphanId).get();
      return d.data();
    } catch (e) {
      debugPrint('Error getting orphan data: $e');
      return null;
    }
  }

  // ====================== المهام ======================

  Future<String?> addTasks(Map<String, dynamic> taskData) async {
    try {
      _ensureHasInstitutionId(taskData);
      final ref = _firestore.collection('tasks').doc();
      final id = ref.id;

      await ref.set({
        ...taskData,
        'taskId': id,
        'createdAt': FieldValue.serverTimestamp(),
        'status': taskData['status'] ?? 'pending',
      });
      return id;
    } catch (e) {
      debugPrint('Error adding task: $e');
      return null;
    }
  }

  Future<bool> updateTask(TaskModel task) async {
    try {
      await _firestore.collection('tasks').doc(task.id).update(task.toMap());
      return true;
    } catch (e) {
      debugPrint('Error updating task: $e');
      return false;
    }
  }

  Query<Map<String, dynamic>> getTasksQuery({
    required String institutionId,
    String? status,
    String? assignedToUid,
  }) {
    Query<Map<String, dynamic>> q = _firestore
        .collection('tasks')
        .where('institutionId', isEqualTo: institutionId);
    if (status != null) q = q.where('status', isEqualTo: status);
    if (assignedToUid != null && assignedToUid.isNotEmpty) {
      q = q.where('assignedTo', isEqualTo: assignedToUid);
    }
    return q.orderBy('createdAt', descending: true);
  }

  Future<List<TaskModel>> fetchTasks(String institutionId) async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('institutionId', isEqualTo: institutionId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();

        DateTime parseDate(dynamic v) {
          if (v is Timestamp) return v.toDate();
          if (v is DateTime) return v;
          return DateTime.now();
        }

        return TaskModel(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          priority: data['priority'] ?? 'متوسط',
          status: data['status'] ?? 'pending',
          dueDate: parseDate(data['dueDate']),
          createdAt: parseDate(data['createdAt']),
          assignedTo: data['assignedTo'] ?? '',
          taskType: data['taskType'] ?? 'إدارية',
          taskLocation: data['taskLocation'] ?? '',
          institutionId: data['institutionId'] ?? '',
          kafalaHeadId: data['kafalaHeadId'] ?? '',
        );
      }).toList();
    } catch (e, stack) {
      debugPrint('Error fetching tasks: $e');
      debugPrint(stack.toString());
      return [];
    }
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }

  Future<int?> getTasksCount(String institutionId) async {
    try {
      final qs = await _firestore
          .collection('tasks')
          .where('institutionId', isEqualTo: institutionId)
          .count()
          .get();
      return qs.count;
    } catch (e) {
      debugPrint('Error getting tasks count: $e');
      return 0;
    }
  }

  // ====================== زيارات ميدانية (Field Visits) ======================

  Future<List<Map<String, dynamic>>> getScheduledVisits(
    String institutionId,
  ) async {
    try {
      final qs = await _firestore
          .collection('field_visits')
          .where('institutionId', isEqualTo: institutionId)
          .where('status', isEqualTo: 'scheduled')
          .orderBy('scheduledDate', descending: false)
          .limit(5)
          .get();

      String fmt(dynamic date) {
        if (date == null) return 'Unknown';
        if (date is Timestamp) {
          final dt = date.toDate();
          return '${dt.day}/${dt.month}/${dt.year}';
        }
        if (date is DateTime) {
          return '${date.day}/${date.month}/${date.year}';
        }
        return date.toString();
      }

      return qs.docs.map((doc) {
        final data = doc.data();
        return {
          'date': fmt(data['scheduledDate']),
          'name': data['orphanName'] ?? 'Unknown',
          'location': data['area'] ?? 'Unknown',
          'visitId': data['visitId'] ?? doc.id,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting scheduled visits: $e');
      return [];
    }
  }

  Future<String?> addFieldVisit(Map<String, dynamic> visitData) async {
    try {
      _ensureHasInstitutionId(visitData);
      final ref = _firestore.collection('field_visits').doc();
      final id = ref.id;

      await ref.set({
        ...visitData,
        'visitId': id,
        'createdAt': FieldValue.serverTimestamp(),
        'status': visitData['status'] ?? 'scheduled',
      });
      return id;
    } catch (e) {
      debugPrint('Error adding field visit: $e');
      return null;
    }
  }

  // ====================== زيارات (قديمة) ======================

  Future<void> addVisit(Map<String, dynamic> visitData) async {
    await _firestore.collection('visits').add(visitData);
  }

  Future<List<Map<String, dynamic>>> getAllVisits(
    String institutionId,
    String status,
  ) async {
    final snapshot = await _firestore
        .collection('visits')
        .where('institutionId', isEqualTo: institutionId)
        .where('status', isEqualTo: status)
        .get();

    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<void> updateVisit(String id, Map<String, dynamic> updates) async {
    await _firestore.collection('visits').doc(id).update(updates);
  }

  Future<void> deleteVisit(String id) async {
    await _firestore.collection('visits').doc(id).delete();
  }

  // ====================== الإحصائيات للوحة التحكم ======================

  Future<Map<String, dynamic>> getDashboardStats(String institutionId) async {
    final orphansBase = _firestore
        .collection('orphans')
        .where('institutionId', isEqualTo: institutionId);

    final tasksBase = _firestore
        .collection('tasks')
        .where('institutionId', isEqualTo: institutionId);

    final visitsBase = _firestore
        .collection('visits')
        .where('institutionId', isEqualTo: institutionId);

    final supervisorsBase = _firestore
        .collection('users')
        .where('institutionId', isEqualTo: institutionId)
        .where('userRole', isEqualTo: 'supervisor')
        .where('isActive', isEqualTo: true);

    // counts
    final totalOrphans = await orphansBase
        .where('isArchived', isEqualTo: false)
        .count()
        .get();
    final orphanSponsored = await orphansBase
        .where('isArchived', isEqualTo: false)
        .where('isSponsored', isEqualTo: true)
        .count()
        .get();
    final orphanRequiringUpdates = await orphansBase
        .where('isArchived', isEqualTo: false)
        .where('isRequiringUpdates', isEqualTo: true)
        .count()
        .get();

    final supervisorsCount = await supervisorsBase.count().get();

    final totalTasksRes = await tasksBase.count().get();
    final completedTasksRes = await tasksBase
        .where('status', isEqualTo: 'completed')
        .count()
        .get();

    final totalVisitsRes = await visitsBase.count().get();
    final completedFieldVisitsRes = await visitsBase
        .where('status', isEqualTo: 'completed')
        .count()
        .get();

    final totalTasks = totalTasksRes.count ?? 0; // إصلاح: معالجة القيم null
    final completedTasks = completedTasksRes.count ?? 0;

    final completedTasksPercentage = totalTasks > 0
        ? (completedTasks / totalTasks) * 100.0
        : 0.0;

    final stats = <String, dynamic>{
      'totalOrphans': totalOrphans.count ?? 0,
      'orphanSponsored': orphanSponsored.count ?? 0,
      'orphanRequiringUpdates': orphanRequiringUpdates.count ?? 0,
      'supervisorsCount': supervisorsCount.count ?? 0,
      'completedTasks': completedTasks,
      'completedTasksPercentage': completedTasksPercentage,
      'totalVisits': totalVisitsRes.count ?? 0,
      'completedFieldVisits': completedFieldVisitsRes.count ?? 0,
      'totalTasks': totalTasks,
    };

    debugPrint('FirestoreService: Fetched Stats: $stats');
    return stats;
  }

  // ====================== أدوات مساعدة ======================

  String generateCustomId() {
    final random = Random();
    const min = 100000;
    const max = 999999;
    return (min + random.nextInt(max - min)).toString();
  }

  String _generateCustomId() {
    final random = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
    return random.toString().padLeft(6, '0');
  }

  void _ensureHasInstitutionId(Map<String, dynamic> data) {
    final id = (data['institutionId'] ?? '').toString();
    if (id.isEmpty) {
      throw ArgumentError('institutionId is required on this operation.');
    }
  }

  List<String> _generateSearchKeywords(String text) {
    final List<String> keywords = [];
    final parts = text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty);
    String current = '';
    for (final part in parts) {
      current = current.isEmpty ? part : '$current $part';
      keywords.add(current);
    }
    return keywords;
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final snap =
        await _firestore // إصلاح: استخدام _firestore بدلاً من FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

    if (!snap.exists) return null;

    final data = snap.data(); // <-- هذا هو الـ Map<String, dynamic>?
    if (data == null) return null;

    return {
      ...data,
      'uid': snap.id, // أضف المعرّف إن احتجته
    };
  }
}

// نقل الـ extension خارج الكلاس
extension SponsorshipEventItemExtension on SponsorshipEventItem {
  SponsorshipEventItem copyWith({
    String? id,
    String? projectId,
    String? title,
    String? details,
    String? performedByUid,
    DateTime? timestamp,
    double? amount,
    String? type,
  }) {
    return SponsorshipEventItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      details: details ?? this.details,
      performedByUid: performedByUid ?? this.performedByUid,
      timestamp: timestamp ?? this.timestamp,
      amount: amount ?? this.amount,
      type: type ?? this.type,
    );
  }
}
