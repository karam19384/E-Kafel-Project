// ملف: fcm_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FCMService {
  final String _projectId = '508451456084'; // استخدم Server ID من الصورة
   final HttpsCallable _sendToToken =
      FirebaseFunctions.instance.httpsCallable('sendToToken');
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  Future<bool> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // الحصول على access token
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
    await _sendToToken.call(<String, dynamic>{
      'token': token,
      'notification': {'title': title, 'body': body},
      'data': data ?? <String, String>{},
    });
  }

  Future<String> _getAccessToken() async {
    // في التطبيق، يمكنك استخدام Service Account
    // أو إرسال من خلال Cloud Functions
    // هذا مثال مبسط
    return 'your-access-token-here';
  }
}