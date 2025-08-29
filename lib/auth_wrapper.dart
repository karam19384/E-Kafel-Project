import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_kafel/src/screens/login_screen.dart';
import 'package:e_kafel/src/screens/home_screen.dart';
import 'package:e_kafel/src/screens/splash_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // عرض شاشة تحميل بسيطة أو CircularProgressIndicator بينما يتم التحقق من حالة المصادقة
          return const SplashScreen();
        } else if (snapshot.hasData) {
          // المستخدم مسجل الدخول، انتقل إلى الشاشة الرئيسية (Home Screen)
          return const HomeScreen();
        } else {
          // المستخدم غير مسجل الدخول، انتقل إلى شاشة تسجيل الدخول (Login Screen)
          return LoginScreen();
        }
      },
    );
  }
}
