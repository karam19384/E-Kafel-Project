// lib/src/services/email_link_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/email_link_model.dart';

class EmailLinkService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إعدادات Resend
  static const String _resendApiKey = 're_MbWVjTCs_14z2etUWwwJbAHPhQgNnQF5n';
  static const String _fromEmail = 'e_kafel <onboarding@resend.dev>';

  Future<void> sendVerificationEmail({
    required String email,
    required String userId,
  }) async {
    try {
      // إنشاء رمز تحقق عشوائي
      final verificationCode = _generateVerificationCode();
      
      // حفظ طلب الربط في Firestore
      final request = EmailLinkRequest(
        email: email,
        userId: userId,
        requestedAt: DateTime.now(),
        verificationCode: verificationCode,
      );

      await _firestore
          .collection('emailLinkRequests')
          .doc(userId)
          .set(request.toMap());

      // إرسال البريد الإلكتروني عبر Resend
      await _sendEmailWithResend(email, verificationCode);
      
    } catch (e) {
      throw Exception('فشل إرسال رابط التحقق: $e');
    }
  }

  Future<void> _sendEmailWithResend(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $_resendApiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'from': _fromEmail,
          'to': [email],
          'subject': 'رمز التحقق - تطبيق e_kafel',
          'html': _buildEmailTemplate(code),
        }),
      );

      if (response.statusCode == 200) {
        print('📧 تم إرسال البريد الإلكتروني بنجاح إلى: $email');
      } else {
        print('❌ فشل إرسال البريد: ${response.statusCode} - ${response.body}');
        throw Exception('فشل إرسال البريد الإلكتروني');
      }
    } catch (e) {
      print('❌ فشل في إرسال البريد الإلكتروني: $e');
      throw Exception('فشل إرسال البريد الإلكتروني: $e');
    }
  }

  // التحقق من الرمز
  Future<void> verifyEmailCode({
    required String email,
    required String code,
    required String userId,
  }) async {
    try {
      final doc = await _firestore
          .collection('emailLinkRequests')
          .doc(userId)
          .get();

      if (!doc.exists) {
        throw Exception('لم يتم طلب ربط لهذا البريد الإلكتروني');
      }

      final request = EmailLinkRequest.fromMap(doc.data()!);

      // التحقق من انتهاء الصلاحية (24 ساعة)
      if (DateTime.now().difference(request.requestedAt).inHours > 24) {
        throw Exception('انتهت صلاحية رابط التحقق');
      }

      if (request.verificationCode != code) {
        throw Exception('رمز التحقق غير صحيح');
      }

      if (request.email != email) {
        throw Exception('البريد الإلكتروني غير متطابق');
      }

      // تحديث حالة المستخدم لربط البريد الإلكتروني
      await _firestore.collection('users').doc(userId).update({
        'linkedEmail': email,
        'emailVerified': true,
        'emailLinkedAt': FieldValue.serverTimestamp(),
      });

      // تحديث حالة الطلب
      await _firestore
          .collection('emailLinkRequests')
          .doc(userId)
          .update({'status': 'verified'});

    } catch (e) {
      throw Exception('فشل التحقق: $e');
    }
  }

  // فك ربط البريد الإلكتروني
  Future<void> unlinkEmail(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'linkedEmail': FieldValue.delete(),
        'emailVerified': false,
        'emailLinkedAt': FieldValue.delete(),
      });
    } catch (e) {
      throw Exception('فشل فك الربط: $e');
    }
  }

  // التحقق من حالة الربط
  Future<Map<String, dynamic>?> getEmailLinkStatus(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      
      if (data != null && data['linkedEmail'] != null) {
        return {
          'isLinked': true,
          'email': data['linkedEmail'],
          'verified': data['emailVerified'] ?? false,
          'linkedAt': data['emailLinkedAt'],
        };
      }
      return {'isLinked': false};
    } catch (e) {
      throw Exception('فشل التحقق من حالة الربط: $e');
    }
  }

  // توليد رمز تحقق عشوائي
  String _generateVerificationCode() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return random.substring(random.length - 6);
  }

  String _buildEmailTemplate(String code) {
    return '''
    <!DOCTYPE html>
    <html dir="rtl">
    <head>
        <meta charset="UTF-8">
        <style>
            body { 
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                direction: rtl;
                text-align: center;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                margin: 0;
                padding: 40px 20px;
            }
            .container { 
                max-width: 500px;
                margin: 0 auto;
                background: white;
                padding: 40px 30px;
                border-radius: 20px;
                box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            }
            .logo { 
                font-size: 28px;
                font-weight: bold;
                color: #2E86AB;
                margin-bottom: 20px;
            }
            .code { 
                font-size: 42px;
                font-weight: bold;
                color: #2E86AB;
                margin: 30px 0;
                padding: 15px;
                background: #f8f9fa;
                border-radius: 10px;
                border: 2px dashed #2E86AB;
                letter-spacing: 5px;
            }
            .note {
                color: #666;
                font-size: 14px;
                margin-top: 25px;
                line-height: 1.6;
            }
            .footer {
                margin-top: 40px;
                padding-top: 20px;
                border-top: 1px solid #eee;
                color: #888;
                font-size: 12px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="logo">📱 e_kafel</div>
            <h2 style="color: #333; margin-bottom: 10px;">مرحباً بك!</h2>
            <p style="color: #666; font-size: 16px;">استخدم رمز التحقق التالي لإكمال عملية التحقق:</p>
            <div class="code">$code</div>
            <p style="color: #ff6b6b; font-weight: bold;">⏰ هذا الرمز صالح لمدة 10 دقائق</p>
            
            <div class="note">
                <strong>ملاحظة:</strong> 
                <br>لقد تلقيت أيضاً إشعاراً فورياً في التطبيق
                <br>إذا لم تطلب هذا الرمز، يرجى تجاهل هذه الرسالة
            </div>
            
            <div class="footer">
                <p>© 2024 تطبيق e_kafel. جميع الحقوق محفوظة</p>
                <p>هذه رسالة تلقائية، يرجى عدم الرد عليها</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }
}