import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:e_kafel/src/models/massege_model.dart';

class SMSService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إن كانت الدالة منشورة في منطقة أخرى غيّرها
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// إرسال رسالة (إشعار) باستخدام Cloud Functions
  Future<Map<String, dynamic>> sendMessage(Message message) async {
    try {
      // 1) حفظ الرسالة
      await _firestore.collection('messages').doc(message.id).set({
        ...message.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'isSent': false,
      }, SetOptions(merge: true));

      // 2) استدعاء الدالة (تأكّد من اسمها ومن الحقول المتوقعة)
      final callable = _functions.httpsCallable('sendBulkNotifications');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'messageText': message.messageText,
        'recipientType': message.recipientType,
        // اتفق مع الدالة: هل ترسل userIds أم tokens؟
        'recipientIds': message.recipientIds,
      });

      final data = Map<String, dynamic>.from(result.data ?? {});
      final sentCount = (data['sentCount'] ?? 0) as int;
      final failedCount = (data['failedCount'] ?? 0) as int;
      final requested =
          (data['requestedCount'] ?? message.recipientIds.length) as int;

      // 3) تحديث الرسالة
      await _firestore.collection('messages').doc(message.id).update({
        'isSent': true,
        'sentAt': FieldValue.serverTimestamp(),
        'successCount': sentCount,
        'failureCount': failedCount,
        'requestedCount': requested,
      });

      // 4) تحديث الإحصاءات
      await _updateSMSStats(
        totalRequested: requested,
        successCount: sentCount,
        failureCount: failedCount,
      );

      return {'success': true, 'sentCount': sentCount, 'failedCount': failedCount};
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ فشل إرسال الرسالة: $e\n$st');
      }
      // حاول إضافة رسالة الخطأ وثبيت الحالة
      await _firestore.collection('messages').doc(message.id).set({
        'isSent': false,
        'error': e.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return {'success': false, 'error': e.toString()};
    }
  }

  /// تهيئة FCM + حفظ الـ token
  Future<void> setupFCM() async {
    // أذونات الإشعار (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
      // optional:
      provisional: false, announcement: false,
    );
    if (kDebugMode) {
      print('🔔 notif permission: ${settings.authorizationStatus}');
    }

    // حاول الحصول على التوكِن مع retry بسيط على أعطال مؤقتة
    await _getAndSaveTokenWithRetry();

    // الاستماع لتحديث التوكِن
    _messaging.onTokenRefresh.listen((t) async {
      await _saveFCMToken(t);
    });
  }

  Future<void> _getAndSaveTokenWithRetry() async {
    const maxRetries = 3;
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final token = await _messaging.getToken();
        if (token != null) {
          if (kDebugMode) print('🔑 FCM token: $token');
          await _saveFCMToken(token);
        }
        return; // نجحت
      } catch (e) {
        final msg = e.toString();
        final transient = msg.contains('SERVICE_NOT_AVAILABLE') ||
            msg.contains('INSTALLATIONS') ||
            msg.contains('timeout');
        if (!transient || attempt == maxRetries) {
          if (kDebugMode) {
            print('❌ getToken failed (attempt $attempt): $e');
          }
          return; // لا تكسر التطبيق
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
  }

 Future<void> _saveFCMToken(String token) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    if (kDebugMode) print('⚠️ لا يمكن حفظ التوكن: المستخدم غير مسجل.');
    return;
  }

  final userDoc = _firestore.collection('users').doc(uid);
  await _firestore.runTransaction((tx) async {
    final snap = await tx.get(userDoc);
    final prev = snap.data() ?? {};
    final List<dynamic> tokens = List<dynamic>.from(prev['fcmTokens'] ?? []);
    if (!tokens.contains(token)) tokens.add(token);

    tx.set(userDoc, {
      'fcmTokens': tokens,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      // (اختياري) معلومات الجهاز:
      'lastDevice': {
        'platform': defaultTargetPlatform.toString(),
        'kIsWeb': kIsWeb,
      },
    }, SetOptions(merge: true));
  });
}

  /// الاشتراك في Topics حسب الدور
  Future<void> subscribeToTopics(String userRole) async {
    await _messaging.subscribeToTopic('all_users');
    switch (userRole) {
      case 'supervisor':
        await _messaging.subscribeToTopic('supervisors');
        break;
      case 'kafala_head':
        await _messaging.subscribeToTopic('kafala_heads');
        break;
      case 'admin':
        await _messaging.subscribeToTopic('admins');
        break;
    }
  }

  /// تحديث الإحصاءات
  Future<void> _updateSMSStats({
    required int totalRequested,
    required int successCount,
    required int failureCount,
  }) async {
    final doc = _firestore.collection('sms_stats').doc('current');
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final prev = snap.data() ?? const {};
      tx.set(doc, {
        'totalMessages': (prev['totalMessages'] ?? 0) + 1,
        'sentMessages': (prev['sentMessages'] ?? 0) + successCount,
        'failedMessages': (prev['failedMessages'] ?? 0) + failureCount,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  /// سجل الرسائل (افترض أن Message.fromMap يقبل id)
  Stream<List<Message>> getMessagesHistory() {
    return _firestore
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromMap({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList());
  }

  // --------- Data sources (منقحة المفاتيح) ---------

  Stream<List<Map<String, dynamic>>> getOrphans() {
    return _firestore
        .collection('orphans')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'fullName': data['fullName'] ?? 'غير معروف',
                'mobileNumber': data['mobileNumber'] ?? data['guardianPhone'] ?? '',
                'governorate': data['governorate'] ?? '',
                'city': data['city'] ?? '',
                'sponsorshipStatus': data['sponsorshipStatus'] ?? '',
                'needsUpdate': data['needsUpdate'] ?? false,
                'waitingForSponsorship': data['waitingForSponsorship'] ?? false,
              };
            })
            .where((o) => (o['mobileNumber'] as String).isNotEmpty)
            .toList());
  }

  Stream<List<Map<String, dynamic>>> getSupervisors() {
    return _firestore
        .collection('users')
        .where('userRole', whereIn: ['supervisor', 'admin'])
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'fullName': data['fullName'] ?? 'غير معروف',
                'mobileNumber': data['mobileNumber'] ?? '',
                'userRole': data['userRole'] ?? '',
                'areaResponsibleFor': data['areaResponsibleFor'] ?? '',
              };
            })
            .where((u) => (u['mobileNumber'] as String).isNotEmpty)
            .toList());
  }

  Stream<List<Map<String, dynamic>>> getKafalaHeads() {
    return _firestore
        .collection('users')
        .where('userRole', isEqualTo: 'kafala_head')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'fullName': data['fullName'] ?? 'غير معروف',
                'mobileNumber': data['mobileNumber'] ?? '',
                'institutionId': data['institutionId'] ?? '',
              };
            })
            .where((u) => (u['mobileNumber'] as String).isNotEmpty)
            .toList());
  }

  Future<Map<String, dynamic>> getSMSStats() async {
    try {
      final snapshot = await _firestore.collection('sms_stats').doc('current').get();
      return snapshot.data() ??
          {'totalMessages': 0, 'sentMessages': 0, 'failedMessages': 0};
    } catch (_) {
      return {'totalMessages': 0, 'sentMessages': 0, 'failedMessages': 0};
    }
  }

  Future<List<Map<String, dynamic>>> searchRecipients(String query, String recipientType) async {
    final recipients = await getRecipientsByType(recipientType).first;
    final q = query.toLowerCase();
    return recipients.where((r) {
      final name = (r['fullName'] as String?)?.toLowerCase() ?? '';
      final phone = (r['mobileNumber'] as String?)?.toLowerCase() ?? '';
      return name.contains(q) || phone.contains(q);
    }).toList();
  }

  Stream<List<Map<String, dynamic>>> getRecipientsByType(String recipientType) {
    switch (recipientType) {
      case 'جميع الأيتام':
      case 'أيتام محددون':
        return getOrphans();

      case 'المشرفين':
        return getSupervisors();

      case 'رؤساء الكفالة':
        return getKafalaHeads();

      case 'أيتام يحتاجون تحديث بيانات':
        return _firestore
            .collection('orphans')
            .where('needsUpdate', isEqualTo: true)
            .where('isActive', isEqualTo: true)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) {
                  final data = doc.data();
                  return {
                    'id': doc.id,
                    'fullName': data['fullName'] ?? 'غير معروف',
                    'mobileNumber': data['mobileNumber'] ?? data['guardianPhone'] ?? '',
                    'needsUpdate': true,
                  };
                })
                .where((o) => (o['mobileNumber'] as String).isNotEmpty)
                .toList());

      case 'أيتام في انتظار الكفالة':
        return _firestore
            .collection('orphans')
            .where('waitingForSponsorship', isEqualTo: true)
            .where('isActive', isEqualTo: true)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) {
                  final data = doc.data();
                  return {
                    'id': doc.id,
                    'fullName': data['fullName'] ?? 'غير معروف',
                    'mobileNumber': data['mobileNumber'] ?? data['guardianPhone'] ?? '',
                    'waitingForSponsorship': true,
                  };
                })
                .where((o) => (o['mobileNumber'] as String).isNotEmpty)
                .toList());

      default:
        return getOrphans();
    }
  }
  /// راقب حالة تسجيل الدخول وزامن التوكن متى توفّر user
void listenAuthAndSyncToken() {
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user != null) {
      try {
        final t = await _messaging.getToken();
        if (t != null) {
          await _saveFCMToken(t);
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ فشل في جلب/حفظ التوكن بعد تسجيل الدخول: $e');
      }
    }
  });
}

}
