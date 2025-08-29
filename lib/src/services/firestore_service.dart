// lib/src/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== Utils ==========
  // ignore: unused_element
  String _generateCustomId() {
    final random = Random();
    const min = 10000000;
    const max = 99999999;
    return (min + random.nextInt(max - min)).toString();
  }

  String _formatDate(dynamic date) {
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

  void _ensureHasInstitutionId(Map<String, dynamic> data) {
    if (data['institutionId'] == null || (data['institutionId'] as String).isEmpty) {
      throw ArgumentError("institutionId is required on this operation.");
    }
  }

  // ========== Institutions & Kafala Head ==========
  /// إنشاء مؤسسة جديدة + إنشاء رئيس قسم الكفالة (بدون أي مشرف)
  /// institutionId: يتم توليده خارجًا (مثلاً من Auth UID للمؤسسة) أو مسبقًا.
  /// institutionData: name, email, phone, address, ... (من الفورم)
  /// kafalaHeadData: uid, name, email, phone, ... (من Auth بعد التسجيل)
  Future<void> initializeNewInstitution(
    String institutionId,
    Map<String, dynamic> institutionData,
    Map<String, dynamic> kafalaHeadData,
  ) async {
    final institutionRef = _firestore.collection('institutions').doc(institutionId);
    final kafalaHeadUid = kafalaHeadData['uid'] as String?;
    if (kafalaHeadUid == null || kafalaHeadUid.isEmpty) {
      throw ArgumentError("kafalaHeadData.uid is required");
    }
    final kafalaHeadRef = _firestore.collection('kafala_heads').doc(kafalaHeadUid);

    await _firestore.runTransaction((tx) async {
      tx.set(institutionRef, {
        ...institutionData,
        'institutionId': institutionId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      tx.set(kafalaHeadRef, {
        ...kafalaHeadData,
        'institutionId': institutionId,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'kafala_head',
        'isActive': true,
      });
    });
  }

  Future<Map<String, dynamic>?> getInstitution(String institutionId) async {
    final snap = await _firestore.collection('institutions').doc(institutionId).get();
    return snap.data();
  }

  Future<void> updateInstitution(String institutionId, Map<String, dynamic> update) async {
    update['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('institutions').doc(institutionId).update(update);
  }

  // ========== Supervisors ==========
  /// إنشاء مشرف جديد (يستدعيه فقط رئيس قسم الكفالة من الواجهة)
  /// supervisorData: يجب أن يحتوي uid وبيانات المشرف الأساسية
  Future<void> createSupervisor(String institutionId, Map<String, dynamic> supervisorData) async {
    final uid = supervisorData['uid'] as String?;
    if (uid == null || uid.isEmpty) throw ArgumentError('supervisorData.uid is required');
    final ref = _firestore.collection('supervisors').doc(uid);

    await ref.set({
      ...supervisorData,
      'institutionId': institutionId,
      'createdAt': FieldValue.serverTimestamp(),
      'role': 'supervisor',
      'isActive': true,
    });
  }

  Future<List<Map<String, dynamic>>> listSupervisors(String institutionId) async {
    final q = await _firestore
        .collection('supervisors')
        .where('institutionId', isEqualTo: institutionId)
        .orderBy('createdAt', descending: true)
        .get();
    return q.docs.map((d) => d.data()).toList();
  }

  // ========== Auth-linked user fetch ==========
  /// جلب بيانات المستخدم (رئيس كفالة أو مشرف) حسب uid
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final head = await _firestore.collection('kafala_heads').doc(uid).get();
    if (head.exists) return head.data();
    final sup = await _firestore.collection('supervisors').doc(uid).get();
    if (sup.exists) return sup.data();
    return null;
  }

  // ========== Dashboard ==========
  /// تُرجع أرقام لوحة التحكم (num تدعم int و double)
  Future<Map<String, int>> getDashboardStats(String institutionId) async {
    try {
      final orphansCount = await _firestore
          .collection('orphans')
          .where('institutionId', isEqualTo: institutionId)
          .count()
          .get();

      final supervisorsCount = await _firestore
          .collection('supervisors')
          .where('institutionId', isEqualTo: institutionId)
          .count()
          .get();

      final completedTasks = await _firestore
          .collection('tasks')
          .where('institutionId', isEqualTo: institutionId)
          .where('status', isEqualTo: 'completed')
          .count()
          .get();

      final totalTasks = await _firestore
          .collection('tasks')
          .where('institutionId', isEqualTo: institutionId)
          .count()
          .get();

      int completedTasksPercentage = 0;
      final total = (totalTasks.count ?? 0);
      if (total > 0) {
        completedTasksPercentage = (((completedTasks.count ?? 0) / total) * 100).round();
      }

      final orphansNeedingUpdates = await _firestore
          .collection('orphans')
          .where('institutionId', isEqualTo: institutionId)
          .where('isDataComplete', isEqualTo: false)
          .count()
          .get();

      final completedVisits = await _firestore
          .collection('field_visits')
          .where('institutionId', isEqualTo: institutionId)
          .where('status', isEqualTo: 'completed')
          .count()
          .get();

      return {
        'orphanSponsored': orphansCount.count ?? 0,
        'completedTasksPercentage': completedTasksPercentage,
        'orphanRequiringUpdates': orphansNeedingUpdates.count ?? 0,
        'supervisorsCount': supervisorsCount.count ?? 0,
        'completedFieldVisits': completedVisits.count ?? 0,
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {
        'orphanSponsored': 0,
        'completedTasksPercentage': 0,
        'orphanRequiringUpdates': 0,
        'supervisorsCount': 0,
        'completedFieldVisits': 0,
      };
    }
  }

  // ========== Field Visits ==========
  Future<List<Map<String, dynamic>>> getScheduledVisits(String institutionId) async {
    try {
      final qs = await _firestore
          .collection('field_visits')
          .where('institutionId', isEqualTo: institutionId)
          .where('status', isEqualTo: 'scheduled')
          .orderBy('scheduledDate', descending: false)
          .limit(5)
          .get();

      return qs.docs.map((doc) {
        final data = doc.data();
        return {
          'date': _formatDate(data['scheduledDate']),
          'name': data['orphanName'] ?? 'Unknown',
          'location': data['area'] ?? 'Unknown',
          'visitId': data['visitId'] ?? doc.id,
        };
      }).toList();
    } catch (e) {
      print('Error getting scheduled visits: $e');
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
      print('Error adding field visit: $e');
      return null;
    }
  }

  // ========== Notifications (ديناميكية بالكامل) ==========
  Future<List<Map<String, dynamic>>> getNotifications(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  Future<void> createNotification(Map<String, dynamic> data) async {
    // متوقَّع: userId, title, message, type, institutionId(optional), timestamp(optional)
    final ref = _firestore.collection('notifications').doc();
    await ref.set({
      ...data,
      'notificationId': ref.id,
      'timestamp': data['timestamp'] ?? FieldValue.serverTimestamp(),
      'isRead': data['isRead'] ?? false,
    });
  }

  Future<void> markNotificationRead(String notificationId, {bool isRead = true}) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': isRead,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  // ========== Orphans ==========
  Query getOrphansQuery({
    required String institutionId,
    bool showIncomplete = false,
  }) {
    Query query = _firestore
        .collection('orphans')
        .where('institutionId', isEqualTo: institutionId);

    if (showIncomplete) {
      query = query.where('isDataComplete', isEqualTo: false);
    }
    return query.orderBy('createdAt', descending: true);
  }

  Future<String?> addOrphan(Map<String, dynamic> orphanData) async {
    try {
      _ensureHasInstitutionId(orphanData);
      final ref = _firestore.collection('orphans').doc();
      final id = ref.id;

      await ref.set({
        ...orphanData,
        'orphanId': id,
        'createdAt': FieldValue.serverTimestamp(),
        'isDataComplete': orphanData['isDataComplete'] ?? false,
        'isArchived': orphanData['isArchived'] ?? false,
      });
      return id;
    } catch (e) {
      print('Error adding orphan: $e');
      return null;
    }
  }

  Future<bool> updateOrphan(String orphanId, Map<String, dynamic> updateData) async {
    try {
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('orphans').doc(orphanId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating orphan: $e');
      return false;
    }
  }

  Future<bool> archiveOrphan(String orphanId) async {
    try {
      await _firestore.collection('orphans').doc(orphanId).update({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error archiving orphan: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getOrphanData(String orphanId) async {
    try {
      final d = await _firestore.collection('orphans').doc(orphanId).get();
      return d.data();
    } catch (e) {
      print('Error getting orphan data: $e');
      return null;
    }
  }

  // ========== Tasks ==========
  Future<String?> addTask(Map<String, dynamic> taskData) async {
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
      print('Error adding task: $e');
      return null;
    }
  }

  Future<bool> updateTaskStatus(String taskId, String status) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating task status: $e');
      return false;
    }
  }

  Query getTasksQuery({
    required String institutionId,
    String? status, // 'pending' | 'in_progress' | 'completed'
    String? assignedToUid,
  }) {
    Query q = _firestore.collection('tasks').where('institutionId', isEqualTo: institutionId);
    if (status != null) q = q.where('status', isEqualTo: status);
    if (assignedToUid != null) q = q.where('assignedTo', isEqualTo: assignedToUid);
    return q.orderBy('createdAt', descending: true);
    }

  // ========== SMS Logs ==========
  Future<bool> sendSMS(Map<String, dynamic> smsData) async {
    try {
      _ensureHasInstitutionId(smsData);
      final smsRef = _firestore.collection('sms_logs').doc();

      await smsRef.set({
        ...smsData,
        'smsId': smsRef.id,
        'sentAt': FieldValue.serverTimestamp(),
        'status': smsData['status'] ?? 'sent',
      });
      return true;
    } catch (e) {
      print('Error sending SMS: $e');
      return false;
    }
  }
}
