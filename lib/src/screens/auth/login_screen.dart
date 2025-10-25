// lib/src/screens/Auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'package:e_kafel/src/screens/Home/home_screen.dart';
import 'package:e_kafel/src/screens/Auth/signup_screen.dart';
import 'package:e_kafel/src/screens/Auth/forgot_password_screen.dart';
import 'package:e_kafel/src/utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login_screen';
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginIdentifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // التحقق من حالة ربط Gmail عند بدء التشغيل
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(CheckGoogleLinkStatus());
    });
  }

  @override
  void dispose() {
    _loginIdentifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  void _handleSignIn() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        LoginButtonPressed(
          loginIdentifier: _loginIdentifierController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (state is AuthErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(32.0),
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // شعار التطبيق
                      _buildAppLogo(),
                      const SizedBox(height: 40),
                      
                      // نموذج التسجيل
                      _buildLoginForm(state),
                      
                      // معلومات ربط Gmail
                      _buildGoogleLinkInfo(state),
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

  Widget _buildAppLogo() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.family_restroom,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'e-Kafel',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'نظام إدارة الكفالات',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(AuthState state) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // حقل User ID
          _buildInputField(
            controller: _loginIdentifierController,
            labelText: 'البريد الإلكتروني أو المعرف',
            hintText: 'أدخل البريد الإلكتروني أو المعرف الفريد',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال المعرف';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // حقل Password
          _buildInputField(
            controller: _passwordController,
            labelText: 'كلمة المرور',
            hintText: 'أدخل كلمة المرور',
            prefixIcon: Icons.lock_outline,
            obscureText: !_isPasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال كلمة المرور';
              }
              if (value.length < 6) {
                return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
              }
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: AppColors.secondaryColor,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // روابط إضافية
          _buildAdditionalLinks(),
          const SizedBox(height: 10),

          // زر تسجيل الدخول
          _buildLoginButton(state),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    FormFieldValidator<String>? validator,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            color: AppColors.secondaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.7),
                fontSize: 14,
              ),
              hintTextDirection: TextDirection.ltr,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: Icon(
                prefixIcon,
                color: AppColors.secondaryColor,
                size: 20,
              ),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalLinks() {
    return Column(
      children: [
        // رابط نسيت كلمة المرور
        GestureDetector(
          onTap: _handleForgotPassword,
          child: Text(
            'نسيت كلمة المرور؟',
            style: TextStyle(
              color: AppColors.secondaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // رابط إنشاء حساب جديد
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SignUpScreen()),
            );
          },
          child: Text(
            'إنشاء حساب جديد',
            style: TextStyle(
              color: AppColors.secondaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(AuthState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state is AuthLoading ? null : _handleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: AppColors.primaryColor.withOpacity(0.3),
        ),
        child: state is AuthLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'تسجيل الدخول',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildGoogleLinkInfo(AuthState state) {
    final isGoogleLinked = state is GoogleLinkChecked && state.isLinked;
    
    if (isGoogleLinked) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.green.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'الحساب مرتبط بـ Gmail - يمكنك استخدامه لاستعادة كلمة المرور',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'للاستفادة من استعادة كلمة المرور بسهولة، يرجى ربط حسابك بـ Gmail من الإعدادات',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}