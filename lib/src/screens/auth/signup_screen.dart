import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../screens/Home/home_screen.dart';
import '../..//utils/dropdown_utils.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _institutionNameController = TextEditingController();
  final _institutionAddressController = TextEditingController();
  final _institutionEmailController = TextEditingController();
  final _institutionWebsiteController = TextEditingController();
  final _headNameController = TextEditingController();
  final _headEmailController = TextEditingController();
  final _headMobileNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // القيم المختارة للدروبد داون
  String? _selectedArea;
  String? _selectedFunctionalLodgment;

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

  void _onSignUp() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
      SignUpButtonPressed(
        name: _institutionNameController.text.trim(),
        email: _institutionEmailController.text.trim(),
        password: _passwordController.text.trim(),
        address: _institutionAddressController.text.trim(),
        website: _institutionWebsiteController.text.trim(),
        headName: _headNameController.text.trim(),
        headEmail: _headEmailController.text.trim(),
        headMobileNumber: _headMobileNumberController.text.trim(),
        userRole: 'kafala_head',
        institutionId: '',
        areaResponsibleFor: _selectedArea ?? '',
        functionalLodgment: _selectedFunctionalLodgment ?? '',
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: suffix,
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _textField(
                          controller: _institutionNameController,
                          label: 'اسم المؤسسة',
                          validator: (v) => v == null || v.isEmpty
                              ? 'أدخل اسم المؤسسة'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _institutionAddressController,
                          label: 'عنوان المؤسسة',
                          validator: (v) =>
                              v == null || v.isEmpty ? 'أدخل العنوان' : null,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _institutionEmailController,
                          label: 'بريد المؤسسة الإلكتروني',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'أدخل البريد';
                            if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v)) {
                              return 'صيغة غير صحيحة';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _institutionWebsiteController,
                          label: 'موقع المؤسسة (اختياري)',
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _headNameController,
                          label: 'اسم رئيس قسم الكفالة',
                          validator: (v) =>
                              v == null || v.isEmpty ? 'أدخل الاسم' : null,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _headEmailController,
                          label: 'بريد رئيس القسم الإلكتروني',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'أدخل البريد';
                            if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v)) {
                              return 'صيغة غير صحيحة';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _headMobileNumberController,
                          label: 'رقم جوال رئيس القسم',
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'أدخل الرقم' : null,
                        ),
                        const SizedBox(height: 12),

                        // ❶ منطقة المسؤولية (Dropdown)
                        LabeledDropdown(
                          label: 'المنطقة المسؤولة',
                          items: kAreasOptions,
                          value: _selectedArea,
                          onChanged: (v) => setState(() => _selectedArea = v),
                        ),
                        const SizedBox(height: 12),

                        // ❷ المهام الوظيفية (Dropdown)
                        LabeledDropdown(
                          label: 'المهام الوظيفية',
                          items: kFunctionalLodgmentOptions,
                          value: _selectedFunctionalLodgment,
                          onChanged: (v) =>
                              setState(() => _selectedFunctionalLodgment = v),
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: _passwordController,
                          label: 'كلمة المرور',
                          obscure: _obscurePassword,
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'أدخل كلمة المرور';
                            if (v.length < 6) return '6 أحرف على الأقل';
                            return null;
                          },
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _confirmPasswordController,
                          label: 'تأكيد كلمة المرور',
                          obscure: _obscureConfirmPassword,
                          validator: (v) => v != _passwordController.text
                              ? 'غير متطابقة'
                              : null,
                          suffix: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        ElevatedButton(
                          onPressed: state is AuthLoading ? null : _onSignUp,
                          child: state is AuthLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('إنشاء حساب'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
