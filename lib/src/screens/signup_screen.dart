import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _institutionNameController = TextEditingController();
  final _institutionAddressController = TextEditingController(); // حقل جديد
  final _institutionEmailController = TextEditingController(); // حقل جديد
  final _institutionWebsiteController = TextEditingController(); // حقل جديد
  final _headNameController = TextEditingController();
  final _headEmailController = TextEditingController();
  final _headMobileNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _institutionNameController.dispose();
    _institutionAddressController.dispose();
    _institutionEmailController.dispose();
    _institutionWebsiteController.dispose();
    _headNameController.dispose();
    _headEmailController.dispose();
    _headMobileNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0E8EB),
      appBar: AppBar(
        title: const Text('Add a new institution'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4C7F7F)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (Route<dynamic> route) => false,
            );
          } else if (state is AuthErrorState) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 100,
                    width: 100,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4C7F7F),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // حقول تفاصيل الجمعية
                  const Text(
                    'Institution Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4C7F7F),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildInputField(
                    controller: _institutionNameController,
                    labelText: 'Name of the institution',
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter institution name'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _institutionEmailController,
                    labelText: 'Institution Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value == null || !value.contains('@')
                        ? 'Please enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _institutionAddressController,
                    labelText: 'Institution Address',
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter institution address'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _institutionWebsiteController,
                    labelText: 'Institution Website (Optional)',
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 40),

                  // حقول تفاصيل المسؤول (Kafala Head)
                  const Text(
                    'Kafala Head Account Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4C7F7F),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildInputField(
                    controller: _headNameController,
                    labelText: 'Name of the Kafala Head',
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter the name of the Kafala Head'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _headEmailController,
                    labelText: 'Enter your email (for login)',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value == null || !value.contains('@')
                        ? 'Please enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _headMobileNumberController,
                    labelText: 'Enter mobile number',
                    keyboardType: TextInputType.phone,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter mobile number'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _passwordController,
                    labelText: 'Enter your password',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) => value == null || value.length < 6
                        ? 'Password must be at least 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _confirmPasswordController,
                    labelText: 'Retype your password',
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                    validator: (value) => value != _passwordController.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                  const SizedBox(height: 40),

                  // زر التسجيل (SIGN UP)
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return state is AuthLoading
                          ? const CircularProgressIndicator(
                              color: Color(0xFF6DAF97),
                            )
                          : ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  BlocProvider.of<AuthBloc>(context).add(
                                    SignUpButtonPressed(
                                      name: _institutionNameController.text.trim(),
                                      address: _institutionAddressController.text.trim(),
                                      email: _institutionEmailController.text.trim(),
                                      website: _institutionWebsiteController.text.trim(),
                                      headName: _headNameController.text.trim(),
                                      headEmail: _headEmailController.text.trim(),
                                      headMobileNumber: _headMobileNumberController.text.trim(),
                                      password: _passwordController.text.trim(), 
                                      userRole: '',
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6DAF97),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'SIGN UP',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to build input fields
  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
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
        validator: validator,
      ),
    );
  }
}
