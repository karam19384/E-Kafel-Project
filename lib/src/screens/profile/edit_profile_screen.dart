// lib/src/screens/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../models/profile_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/dropdown_utils_extended.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile? profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullName;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _address;

  String? _functionalLodgment;
  String? _areaResponsibleFor;

  // تحديد الحقول القابلة للتعديل حسب الصلاحيات
  bool get _canEditAll => widget.profile?.canEditAll ?? false;
  bool get _canEditContactInfo => true; // أي مستخدم يمكنه تعديل معلومات الاتصال

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    
    // التحقق من وجود البروفايل وتعيين القيم
    if (p != null) {
      _fullName = TextEditingController(text: p.fullName);
      _email = TextEditingController(text: p.email);
      _phone = TextEditingController(text: p.mobileNumber);
      _address = TextEditingController(text: p.address ?? '');
      
      // الحقول الوظيفية - استخدام القيمة مباشرة مع fallback
      _functionalLodgment = p.functionalLodgment ?? 'غير محدد';
      _areaResponsibleFor = p.areaResponsibleFor ?? 'غير محدد';
    } else {
      // قيم افتراضية إذا كان البروفايل null
      _fullName = TextEditingController();
      _email = TextEditingController();
      _phone = TextEditingController();
      _address = TextEditingController();
      _functionalLodgment = 'غير محدد';
      _areaResponsibleFor = 'غير محدد';
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdated) {
            _showSuccessMessage('تم تحديث الملف الشخصي بنجاح');
            Navigator.of(context).pop(true);
          } else if (state is ProfileError) {
            _showErrorMessage('فشل في تحديث الملف الشخصي: ${state.message}');
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // قسم المعلومات الأساسية (غير قابلة للتعديل)
              _buildSectionHeader('المعلومات الأساسية'),
              const SizedBox(height: 10),

              _buildReadOnlyField(
                label: 'المؤسسة',
                value: widget.profile?.institutionName ?? 'غير محدد',
                icon: Icons.business,
              ),
              const SizedBox(height: 12),

              _buildReadOnlyField(
                label: 'المعرف الوظيفي',
                value: widget.profile?.customId ?? 'غير محدد',
                icon: Icons.badge,
              ),

              const SizedBox(height: 16),

              // قسم المعلومات الشخصية
              _buildSectionHeader('المعلومات الشخصية'),
              const SizedBox(height: 12),

              _buildEditableField(
                controller: _fullName,
                label: 'الاسم الكامل',
                icon: Icons.person,
                enabled: _canEditAll,
                required: true,
                hintText: _canEditAll ? null : 'لا يمكن تعديل هذا الحقل',
              ),

              const SizedBox(height: 16),

              // قسم معلومات الاتصال (قابل للتعديل للجميع)
              _buildSectionHeader('معلومات الاتصال'),
              const SizedBox(height: 12),

              _buildEditableField(
                controller: _email,
                label: 'البريد الإلكتروني',
                icon: Icons.email,
                enabled: _canEditContactInfo,
                required: true,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 12),

              _buildEditableField(
                controller: _phone,
                label: 'رقم الجوال',
                icon: Icons.phone,
                enabled: _canEditContactInfo,
                required: true,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 12),

              _buildEditableField(
                controller: _address,
                label: 'العنوان',
                icon: Icons.location_on,
                enabled: _canEditContactInfo,
                required: false,
                maxLines: 2,
              ),

              // قسم المعلومات الوظيفية (تظهر للجميع ولكن يمكن تعديلها فقط للمستخدمين ذوي الصلاحيات)
              const SizedBox(height: 24),
              _buildSectionHeader('المعلومات الوظيفية'),
              const SizedBox(height: 16),

              // المسمى الوظيفي - يظهر للجميع
              _canEditAll
                  ? _buildEditableDropdown(
                      value: _functionalLodgment,
                      label: 'المسمى الوظيفي',
                      icon: Icons.work,
                      items: kFunctionalLodgmentOptions,
                      onChanged: (String? newValue) {
                        setState(() {
                          _functionalLodgment = newValue;
                        });
                      },
                    )
                  : _buildReadOnlyField(
                      label: 'المسمى الوظيفي',
                      value: _functionalLodgment ?? 'غير محدد',
                      icon: Icons.work,
                    ),

              const SizedBox(height: 16),

              // المنطقة الوظيفية - تظهر للجميع
              _canEditAll
                  ? _buildEditableDropdown(
                      value: _areaResponsibleFor,
                      label: 'المنطقة الوظيفية',
                      icon: Icons.map,
                      items: kAreasOptions,
                      onChanged: (String? newValue) {
                        setState(() {
                          _areaResponsibleFor = newValue;
                        });
                      },
                    )
                  : _buildReadOnlyField(
                      label: 'المنطقة الوظيفية',
                      value: _areaResponsibleFor ?? 'غير محدد',
                      icon: Icons.map,
                    ),

              const SizedBox(height: 16),

              // الملاحظات - تظهر للجميع ولكن يمكن تعديلها فقط للمستخدمين ذوي الصلاحيات
             

              const SizedBox(height: 32),

              // أزرار الحفظ والإلغاء
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryColor),
      ),
      child: Row(
        children: [
          Icon(Icons.category, color: AppColors.primaryColor, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    required bool required,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: enabled ? AppColors.primaryColor : Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        hintText: hintText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'هذا الحقل مطلوب';
              }
              return null;
            }
          : null,
      style: TextStyle(color: enabled ? Colors.black : Colors.grey),
    );
  }

  Widget _buildEditableDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يرجى اختيار $label';
        }
        return null;
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // زر الإلغاء
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.cancel),
            label: const Text('إلغاء'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey[400]!),
            ),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
        ),

        const SizedBox(width: 12),

        // زر الحفظ
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('حفظ التغييرات'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            onPressed: _saveProfile,
          ),
        ),
      ],
    );
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      _showErrorMessage('يرجى تصحيح الأخطاء قبل الحفظ');
      return;
    }

    final fields = <String, dynamic>{
      'email': _email.text.trim(),
      'mobileNumber': _phone.text.trim(),
      'address': _address.text.trim(),
      'updatedAt': DateTime.now(),
    };

    // إضافة الحقول الإضافية للمستخدمين ذوي الصلاحيات
    if (_canEditAll) {
      fields.addAll({
        'fullName': _fullName.text.trim(),
        'functionalLodgment': _functionalLodgment,
        'areaResponsibleFor': _areaResponsibleFor,
      });
    }

    context.read<ProfileBloc>().add(UpdateProfileRequested(fields));
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}