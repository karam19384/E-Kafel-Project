import 'package:e_kafel/src/utils/dropdown_utils_extended.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../screens/Home/home_screen.dart';
import '../../utils/app_colors.dart';

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
  String? _profileImageUrl;

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

  void _pickProfileImage() {
    // هنا يمكن إضافة منطق اختيار الصورة من المعرض أو الكاميرا
    // حالياً سنضيف صورة افتراضية للعرض
    setState(() {
      _profileImageUrl = 'https://via.placeholder.com/150';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('سيتم إضافة خاصية رفع الصورة قريباً'),
        backgroundColor: AppColors.primaryColor,
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
    IconData? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.secondaryColor,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: suffix,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.secondaryColor, size: 20) : null,
      ),
      validator: validator,
      style: TextStyle(
        color: AppColors.textColor,
        fontSize: 16,
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryColor,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey[200],
                backgroundImage: _profileImageUrl != null 
                    ? NetworkImage(_profileImageUrl!) 
                    : null,
                child: _profileImageUrl == null
                    ? Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey[400],
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    onPressed: _pickProfileImage,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'صورة رئيس القسم',
          style: TextStyle(
            color: AppColors.secondaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إنشاء حساب جديد',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
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
                backgroundColor: AppColors.errorColor,
              )
            );
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
                        // صورة الملف الشخصي
                        _buildProfileImageSection(),

                        // معلومات المؤسسة
                        _buildSectionTitle('معلومات المؤسسة'),
                        const SizedBox(height: 16),
                        
                        _textField(
                          controller: _institutionNameController,
                          label: 'اسم المؤسسة',
                          prefixIcon: Icons.business,
                          validator: (v) => v == null || v.isEmpty
                              ? 'أدخل اسم المؤسسة'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _institutionAddressController,
                          label: 'عنوان المؤسسة',
                          prefixIcon: Icons.location_on,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'أدخل العنوان' : null,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _institutionEmailController,
                          label: 'بريد المؤسسة الإلكتروني',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email,
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
                          prefixIcon: Icons.language,
                        ),
                        const SizedBox(height: 20),

                        // معلومات رئيس القسم
                        _buildSectionTitle('معلومات رئيس قسم الكفالة'),
                        const SizedBox(height: 16),

                        _textField(
                          controller: _headNameController,
                          label: 'اسم رئيس قسم الكفالة',
                          prefixIcon: Icons.person,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'أدخل الاسم' : null,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _headEmailController,
                          label: 'بريد رئيس القسم الإلكتروني',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email,
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
                          prefixIcon: Icons.phone,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'أدخل الرقم' : null,
                        ),
                        const SizedBox(height: 20),

                        // المعلومات الوظيفية
                        _buildSectionTitle('المعلومات الوظيفية'),
                        const SizedBox(height: 16),

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
                        const SizedBox(height: 20),

                        // كلمة المرور
                        _buildSectionTitle('كلمة المرور'),
                        const SizedBox(height: 16),

                        _textField(
                          controller: _passwordController,
                          label: 'كلمة المرور',
                          obscure: _obscurePassword,
                          prefixIcon: Icons.lock,
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
                              color: AppColors.secondaryColor,
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
                          prefixIcon: Icons.lock_outline,
                          validator: (v) => v != _passwordController.text
                              ? 'غير متطابقة'
                              : null,
                          suffix: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.secondaryColor,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword = !_obscureConfirmPassword,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // زر إنشاء الحساب
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: state is AuthLoading ? null : _onSignUp,
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
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'إنشاء حساب',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
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