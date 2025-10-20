// ملف: fcm_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class FCMService {
  final String _projectId = '508451456084'; // استخدم Server ID من الصورة
  
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

  Future<String> _getAccessToken() async {
    // في التطبيق، يمكنك استخدام Service Account
    // أو إرسال من خلال Cloud Functions
    // هذا مثال مبسط
    return 'your-access-token-here';
  }
}