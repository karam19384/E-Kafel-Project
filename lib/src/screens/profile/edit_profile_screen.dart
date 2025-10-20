// lib/src/screens/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../models/profile_model.dart';
import '../../utils/dropdown_utils_extended.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile profile;
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
  late TextEditingController _currentLocation;
  late TextEditingController _notes;

  String? _functionalLodgment;
  String? _areaResponsibleFor;

  // خيارات السلكت
  static const List<String> lodgmentOptions = ['Office', 'Field', 'Remote'];
  static const List<String> areaOptions = ['North', 'South', 'East', 'West', 'Central'];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _fullName = TextEditingController(text: p.fullName);
    _email = TextEditingController(text: p.email);
    _phone = TextEditingController(text: p.mobileNumber);
    _address = TextEditingController(text: p.address ?? '');
    _currentLocation = TextEditingController(text: p.currentLocation ?? '');
    _notes = TextEditingController(text: p.notes ?? '');
    _functionalLodgment = DropdownHelper.getSafeValue(p.functionalLodgment, lodgmentOptions);
    _areaResponsibleFor = DropdownHelper.getSafeValue(p.areaResponsibleFor, areaOptions);
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _currentLocation.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canEditAll = widget.profile.canEditAll;

    return Scaffold(
      appBar: AppBar(title: const Text('تعديل الملف الشخصي')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _readonlyField('المؤسسة', widget.profile.institutionName),
            _readonlyField('المعرف الوظيفي', widget.profile.customId),
            const SizedBox(height: 8),

            // مشرف يستطيع تعديل: الجوال، الإيميل، كلمة المرور (عبر زر منفصل إن أردت)، العنوان الحالي
            // رئيس قسم الكفالة/أدمن: كل شيء
            if (canEditAll)
              TextFormField(
                controller: _fullName,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
              ),

            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(
                labelText: 'رقم الجوال',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _currentLocation,
              decoration: const InputDecoration(
                labelText: 'العنوان الحالي',
                border: OutlineInputBorder(),
              ),
            ),

            if (canEditAll) ...[
              const SizedBox(height: 12),
              
              // المسمى الوظيفي - باستخدام الدروب داون الآمن
              DropdownHelper.createSafeDropdown(
                label: 'المسمى الوظيفي',
                value: _functionalLodgment,
                items: DropdownHelper.createMenuItems(lodgmentOptions),
                onChanged: (v) => setState(() => _functionalLodgment = v),
              ),
              const SizedBox(height: 12),
              
              // المنطقة الوظيفية - باستخدام الدروب داون الآمن
              DropdownHelper.createSafeDropdown(
                label: 'المنطقة الوظيفية',
                value: _areaResponsibleFor,
                items: DropdownHelper.createMenuItems(areaOptions),
                onChanged: (v) => setState(() => _areaResponsibleFor = v),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],

            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('حفظ'),
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _readonlyField(String label, String value) {
    return TextFormField(
      initialValue: value,
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        disabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final fields = <String, dynamic>{
      'email': _email.text.trim(),
      'mobileNumber': _phone.text.trim(),
      'address': _address.text.trim(),
      'currentLocation': _currentLocation.text.trim(),
      'updatedAt': DateTime.now(),
    };

    if (widget.profile.canEditAll) {
      fields.addAll({
        'fullName': _fullName.text.trim(),
        'functionalLodgment': _functionalLodgment,
        'areaResponsibleFor': _areaResponsibleFor,
        'notes': _notes.text.trim(),
      });
    }

    context.read<ProfileBloc>().add(UpdateProfileRequested(fields));
    Navigator.of(context).pop();
  }
}