// lib/src/screens/settings/email_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'package:e_kafel/src/utils/app_colors.dart';

class EmailVerificationScreen extends StatefulWidget {
  static const routeName = '/email_verification_screen';
  const EmailVerificationScreen({super.key});

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isCodeSent = false;
  bool _isVerified = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _sendVerificationCode() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        SendEmailVerificationRequested(_emailController.text.trim()),
      );
    }
  }

  void _verifyCode() {
    if (_codeController.text.length == 6) {
      context.read<AuthBloc>().add(
        VerifyEmailCodeRequested(
          _emailController.text.trim(),
          _codeController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ربط البريد الإلكتروني'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is EmailVerificationSent) {
            setState(() {
              _isCodeSent = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إرسال رمز التحقق إلى بريدك الإلكتروني'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is EmailVerified) {
            setState(() {
              _isVerified = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم ربط البريد الإلكتروني بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.of(context).pop();
            });
          } else if (state is AuthErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // العنوان
                Text(
                  _isVerified 
                      ? 'تم الربط بنجاح!'
                      : _isCodeSent
                          ? 'أدخل رمز التحقق'
                          : 'ربط البريد الإلكتروني',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  _isVerified
                      ? 'يمكنك الآن استخدام بريدك الإلكتروني لاستعادة كلمة المرور'
                      : _isCodeSent
                          ? 'أدخل الرمز المكون من 6 أرقام الذي تم إرساله إلى بريدك الإلكتروني'
                          : 'أدخل بريدك الإلكتروني لربطه بحسابك وإمكانية استعادة كلمة المرور',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                
                const SizedBox(height: 32),

                if (!_isVerified) ...[
                  // حقل البريد الإلكتروني
                  _buildEmailField(),
                  const SizedBox(height: 20),

                  if (_isCodeSent) ...[
                    // حقل رمز التحقق
                    _buildCodeField(),
                    const SizedBox(height: 20),
                    
                    // زر التحقق
                    _buildVerifyButton(),
                  ] else ...[
                    // زر إرسال الرمز
                    _buildSendButton(),
                  ],
                ] else ...[
                  // رسالة النجاح
                  _buildSuccessMessage(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      enabled: !_isCodeSent,
      decoration: const InputDecoration(
        labelText: 'البريد الإلكتروني',
        hintText: 'أدخل بريدك الإلكتروني',
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'الرجاء إدخال البريد الإلكتروني';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'الرجاء إدخال بريد إلكتروني صحيح';
        }
        return null;
      },
    );
  }

  Widget _buildCodeField() {
    return TextFormField(
      controller: _codeController,
      keyboardType: TextInputType.number,
      maxLength: 6,
      decoration: const InputDecoration(
        labelText: 'رمز التحقق',
        hintText: 'أدخل الرمز المكون من 6 أرقام',
        prefixIcon: Icon(Icons.lock),
        border: OutlineInputBorder(),
        counterText: '',
      ),
      onChanged: (value) {
        if (value.length == 6) {
          _verifyCode();
        }
      },
    );
  }

  Widget _buildSendButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state is AuthLoading ? null : _sendVerificationCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                    'إرسال رمز التحقق',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildVerifyButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state is AuthLoading ? null : _verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                    'تحقق من الرمز',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 48),
          SizedBox(height: 16),
          Text(
            'تم ربط البريد الإلكتروني بنجاح',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'يمكنك الآن استخدام بريدك الإلكتروني لاستعادة كلمة المرور في حالة نسيانها',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}