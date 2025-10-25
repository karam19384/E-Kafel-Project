// lib/src/services/fcm_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FCMService {
  final String _projectId = '508451456084';
  final HttpsCallable _sendToToken =
      FirebaseFunctions.instance.httpsCallable('sendToToken');
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _setupLocalNotifications();
    await _setupFCM();
  }

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    // إنشاء قناة إشعارات للأندرويد
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'verification_channel',
      'قناة رمز التحقق',
      description: 'قناة لإشعارات رمز التحقق والتأكيد',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _setupFCM() async {
    // طلب الإذن للإشعارات
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // الحصول على token وحفظه
    String? token = await _fcm.getToken();
    if (token != null) {
      await _saveFCMToken(token);
    }

    // تحديث Token عند التغيير
    _fcm.onTokenRefresh.listen(_saveFCMToken);

    // التعامل مع الإشعارات
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  Future<void> _saveFCMToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _fs.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(
      title: message.notification?.title ?? 'e_kafel',
      body: message.notification?.body ?? '',
      payload: message.data['type'] ?? '',
    );
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('تم فتح الإشعار: ${message.notification?.body}');
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String payload = '',
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'verification_channel',
      'قناة رمز التحقق',
      channelDescription: 'قناة لإشعارات رمز التحقق',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  // إرسال إشعار فوري برمز التحقق
  Future<void> sendVerificationNotification(String code) async {
    try {
      await _showLocalNotification(
        title: 'رمز التحقق - e_kafel',
        body: 'رمز التحقق الخاص بك هو: $code',
        payload: 'verification',
      );
      print('📲 تم إرسال الإشعار الفوري بنجاح');
    } catch (e) {
      print('⚠️ فشل في إرسال الإشعار المحلي: $e');
    }
  }

  // الدوال الأصلية للتوافق
  Future<bool> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'message': {
            'topic': topic,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': data,
          }
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('فشل إرسال الإشعار: $e');
      return false;
    }
  }

  Future<String?> _getUserFcmToken(String userId) async {
    final d = await _fs.collection('users').doc(userId).get();
    final data = d.data();
    return data?['fcmToken'] as String?;
  }

  Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final token = await _getUserFcmToken(userId);
    if (token == null || token.isEmpty) return;
    
    try {
      await _sendToToken.call(<String, dynamic>{
        'token': token,
        'notification': {'title': title, 'body': body},
        'data': data ?? <String, String>{},
      });
      print('📤 تم إرسال إشعار FCM إلى المستخدم: $userId');
    } catch (e) {
      print('❌ فشل إرسال إشعار FCM: $e');
    }
  }

  Future<String> _getAccessToken() async {
    return 'your-access-token-here';
  }

  // دالة مساعدة للاشتراك في المواضيع
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      print('✅ تم الاشتراك في الموضوع: $topic');
    } catch (e) {
      print('❌ فشل الاشتراك في الموضوع: $e');
    }
  }

  // دالة مساعدة لإلغاء الاشتراك من المواضيع
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      print('✅ تم إلغاء الاشتراك من الموضوع: $topic');
    } catch (e) {
      print('❌ فشل إلغاء الاشتراك من الموضوع: $e');
    }
  }
}