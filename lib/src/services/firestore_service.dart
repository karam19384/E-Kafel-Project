// lib/src/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== Utils ==========
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
    if (data['institutionId'] == null ||
        (data['institutionId'] as String).isEmpty) {
      throw ArgumentError("institutionId is required on this operation.");
    }
  }

// ========== Users ==========
  Future<DocumentSnapshot?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc : null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<void> createUser(String uid, Map<String, dynamic> userData) async {
    await _firestore.collection('users').doc(uid).set(userData);
  }

  // ========== Institutions ==========
  Future<void> initializeNewInstitution(
    String institutionId,
    Map<String, dynamic> institutionData,
    Map<String, dynamic> kafalaHeadData,
  ) async {
    final institutionRef = _firestore
        .collection('institutions')
        .doc(institutionId);
    final kafalaHeadUid = kafalaHeadData['uid'] as String?;
    
    // إنشاء ملف المؤسسة
    await institutionRef.set({
      ...institutionData,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // إنشاء ملف المستخدم (رئيس الكفالة) وربطه بالمؤسسة
    if (kafalaHeadUid != null) {
      await _firestore.collection('users').doc(kafalaHeadUid).set({
        ...kafalaHeadData,
        'institutionId': institutionId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ========== Supervisors ==========
  Future<void> createSupervisor(
    String institutionId,
    Map<String, dynamic> supervisorData,
  ) async {
    final uid = supervisorData['uid'] as String?;
    if (uid == null || uid.isEmpty) {
      throw ArgumentError('supervisorData.uid is required');
    }
    final ref = _firestore.collection('supervisors').doc(uid);

    await ref.set({
      ...supervisorData,
      'institutionId': institutionId,
      'createdAt': FieldValue.serverTimestamp(),
      'role': 'supervisor',
      'isActive': true,
    });
  }

  Future<List<Map<String, dynamic>>> listSupervisors(
    String institutionId,
  ) async {
    final q = await _firestore
        .collection('supervisors')
        .where('institutionId', isEqualTo: institutionId)
        .orderBy('createdAt', descending: true)
        .get();
    return q.docs.map((d) => d.data()).toList();
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final head = await _firestore.collection('kafala_heads').doc(uid).get();
    if (head.exists) return head.data();
    final sup = await _firestore.collection('supervisors').doc(uid).get();
    if (sup.exists) return sup.data();
    return null;
  }
 
  Future<int?> getTasksCount(String institutionId) async {
    try {
      final querySnapshot = await _firestore
          .collection('tasks')
          .where('institutionId', isEqualTo: institutionId)
          .count()
          .get();
      return querySnapshot.count;
    } catch (e) {
      print('Error getting tasks count: $e');
      return 0;
    }
  }
  // ==========  ==========\
  Future<Map<String, dynamic>> getDashboardStats(String institutionId) async {
    return _firestore.runTransaction<Map<String, dynamic>>((tx) async {
      // Queries for counts
      final totalOrphansQuery = _firestore
          .collection('orphans')
          .where('institutionId', isEqualTo: institutionId)
          .where('isArchived', isEqualTo: false);
      final orphanSponsoredQuery = totalOrphansQuery.where(
        'isSponsored',
        isEqualTo: true,
      );
      final orphanRequiringUpdatesQuery = totalOrphansQuery.where(
        'isRequiringUpdates',
        isEqualTo: true,
      );
      final supervisorsCountQuery = _firestore
          .collection('users')
          .where('institutionId', isEqualTo: institutionId)
          .where('role', isEqualTo: 'supervisor');
      final completedTasksQuery = _firestore
          .collection('tasks')
          .where('institutionId', isEqualTo: institutionId)
          .where('status', isEqualTo: 'completed');
      final totalTasksQuery = _firestore
          .collection('tasks')
          .where('institutionId', isEqualTo: institutionId);
      final totalVisitsQuery = _firestore
          .collection('field_visits')
          .where('institutionId', isEqualTo: institutionId);
      final completedFieldVisitsQuery = totalVisitsQuery.where(
        'status',
        isEqualTo: 'completed',
      );

      // Fetch counts
      final totalOrphansSnapshot = await totalOrphansQuery.count().get();
      final orphanSponsoredSnapshot = await orphanSponsoredQuery.count().get();
      final orphanRequiringUpdatesSnapshot = await orphanRequiringUpdatesQuery
          .count()
          .get();
      final supervisorsCountSnapshot = await supervisorsCountQuery
          .count()
          .get();
      final completedTasksSnapshot = await completedTasksQuery.count().get();
      final totalTasksSnapshot = await totalTasksQuery.count().get();
      final totalVisitsSnapshot = await totalVisitsQuery.count().get();
      final completedFieldVisitsSnapshot = await completedFieldVisitsQuery
          .count()
          .get();

      // Get the count values
      final totalOrphans = totalOrphansSnapshot.count;
      final orphanSponsored = orphanSponsoredSnapshot.count;
      final orphanRequiringUpdates = orphanRequiringUpdatesSnapshot.count;
      final supervisorsCount = supervisorsCountSnapshot.count;
      final completedTasks = completedTasksSnapshot.count;
      final totalTasks = totalTasksSnapshot.count;
      final totalVisits = totalVisitsSnapshot.count;
      final completedFieldVisits = completedFieldVisitsSnapshot.count;

      // Calculate percentages
      final completedTasksPercentage = totalTasks! > 0
          ? (completedTasks! / totalTasks) * 100
          : 0.0;

      final Map<String, dynamic> stats = {
        'totalOrphans': totalOrphans,
        'orphanSponsored': orphanSponsored,
        'orphanRequiringUpdates': orphanRequiringUpdates,
        'supervisorsCount': supervisorsCount,
        'completedTasks': completedTasks,
        'completedTasksPercentage': completedTasksPercentage,
        'totalVisits': totalVisits,
        'completedFieldVisits': completedFieldVisits,
        'totalTasks': totalTasks, // Added for completeness
      };

      print('FirestoreService: Fetched Stats: $stats');
      return stats;
    });
  }

  // ========== Field Visits ==========
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

  Future<void> markNotificationRead(
    String notificationId, {
    bool isRead = true,
  }) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': isRead,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  // ========== Orphans ==========
  Query getOrphansQuery({
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
    Query query = _firestore
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
      // البحث المتقدم: الاسم، رقم اليتيم، رقم الهوية، اسم المتوفى، اسم المعيل
      query = query.where(
        'searchKeywords',
        arrayContains: searchTerm.toLowerCase(),
      );
    }

    return query.orderBy('createdAt', descending: true);
  }

  Future<String?> addOrphan(Map<String, dynamic> orphanData) async {
    try {
      _ensureHasInstitutionId(orphanData);
      final ref = _firestore.collection('orphans').doc();
      final id = ref.id;

      // توليد مصفوفة Keywords للبحث المتقدم
      List<String> keywords = [];
      if (orphanData['name'] != null) {
        keywords.addAll(_generateSearchKeywords(orphanData['name']));
      }
      if (orphanData['orphanIdNumber'] != null) {
        keywords.add(orphanData['orphanIdNumber'].toString());
      }
      if (orphanData['deceasedName'] != null) {
        keywords.addAll(_generateSearchKeywords(orphanData['deceasedName']));
      }
      if (orphanData['breadwinnerName'] != null) {
        keywords.addAll(_generateSearchKeywords(orphanData['breadwinnerName']));
      }
      orphanData['searchKeywords'] = keywords;

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

  Future<bool> updateOrphan(
    String orphanId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      if (updateData.containsKey('name') ||
          updateData.containsKey('orphanIdNumber') ||
          updateData.containsKey('deceasedName') ||
          updateData.containsKey('breadwinnerName')) {
        List<String> keywords = [];
        if (updateData['name'] != null) {
          keywords.addAll(_generateSearchKeywords(updateData['name']));
        }
        if (updateData['orphanIdNumber'] != null) {
          keywords.add(updateData['orphanIdNumber'].toString());
        }
        if (updateData['deceasedName'] != null) {
          keywords.addAll(_generateSearchKeywords(updateData['deceasedName']));
        }
        if (updateData['breadwinnerName'] != null) {
          keywords.addAll(
            _generateSearchKeywords(updateData['breadwinnerName']),
          );
        }
        updateData['searchKeywords'] = keywords;
      }

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

  // ========== Helpers ==========
  List<String> _generateSearchKeywords(String text) {
    final List<String> keywords = [];
    final parts = text.toLowerCase().split(' ');
    String current = '';
    for (var part in parts) {
      current = current.isEmpty ? part : '$current $part';
      keywords.add(current);
    }
    return keywords;
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
    Query q = _firestore
        .collection('tasks')
        .where('institutionId', isEqualTo: institutionId);
    if (status != null) q = q.where('status', isEqualTo: status);
    if (assignedToUid != null) {
      q = q.where('assignedTo', isEqualTo: assignedToUid);
    }
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
