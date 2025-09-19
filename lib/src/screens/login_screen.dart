// lib/src/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'package:e_kafel/src/screens/home_screen.dart';
import 'package:e_kafel/src/screens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // تم تغيير اسم المتحكم إلى _loginIdentifierController
  final _loginIdentifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _loginIdentifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
              print("User role: ${state.userRole}");
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (state is AuthErrorState) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  child: Column(
                    children: [
                      // حقل إدخال البريد الإلكتروني أو المعرف الفريد
                      _buildInputField(
                        controller: _loginIdentifierController,
                        // تم تغيير التسمية لتعكس الدعم الجديد
                        labelText: 'البريد الإلكتروني أو المعرف الفريد',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _passwordController,
                        labelText: 'كلمة المرور',
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFF4C7F7F),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      // زر تسجيل الدخول
                      ElevatedButton(
                        onPressed: state is AuthLoading
                            ? null
                            : () {
                                context.read<AuthBloc>().add(
                                  LoginButtonPressed(
                                    loginIdentifier: _loginIdentifierController
                                        .text
                                        .trim(),
                                    password: _passwordController.text.trim(),
                                    email: _loginIdentifierController.text
                                        .trim(),
                                  ),
                                );
                              },
                        child: const Text('تسجيل الدخول'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {},
                        child: const Text('نسيت كلمة المرور؟'),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: const Text('إضافة مؤسسة جديدة'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0BBE4), width: 2),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Color(0xFF4C7F7F)),
          border: InputBorder.none,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
