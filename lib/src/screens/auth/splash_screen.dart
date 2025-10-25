import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'package:e_kafel/src/screens/Home/home_screen.dart';
import 'package:e_kafel/src/screens/Auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // نرسل حدث AppStarted للتحقق من حالة المصادقة بعد 3 ثوانٍ
    Future.delayed(const Duration(seconds: 3), () {
      BlocProvider.of<AuthBloc>(context).add(AppStarted());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // في حالة نجاح المصادقة، ننتقل إلى الشاشة الرئيسية (HomeScreen)
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (state is AuthUnauthenticated) {
            // في حالة الفشل، ننتقل إلى شاشة تسجيل الدخول (LoginScreen)
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        },
        child: Center(
          child: Image(image: AssetImage('assets/images/logo.png'),),
        ),
      ),
    );
  }
}
