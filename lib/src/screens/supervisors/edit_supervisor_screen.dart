// lib/src/screens/supervisors/edit_supervisor_screen.dart
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/dropdown_utils.dart';
import '../../utils/dropdown_utils_extended.dart';

class EditSupervisorScreen extends StatefulWidget {
  final UserModel user;
  const EditSupervisorScreen({super.key, required this.user});

  @override
  State<EditSupervisorScreen> createState() => _EditSupervisorScreenState();
}

class _EditSupervisorScreenState extends State<EditSupervisorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullName;
  late TextEditingController _email;
  late TextEditingController _mobile;
  late TextEditingController _address;

  String? _functionalLodgment;
  String? _area;
  String _userRole = 'supervisor';
  bool _isActive = true;

  final _service = FirestoreService();

  // قوائم الخيارات
  static const List<String> _roleOptions = ['supervisor', 'kafala_head'];
  static const List<String> _roleLabels = ['مشرف', 'رئيس قسم كفالة'];

  static const List<String> _lodgmentOptions = ['office', 'field'];
  static const List<String> _lodgmentLabels = ['مكتب', 'ميداني'];

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _fullName = TextEditingController(text: u.fullName);
    _email = TextEditingController(text: u.email);
    _mobile = TextEditingController(text: u.mobileNumber);
    _address = TextEditingController(text: u.address ?? '');
    _functionalLodgment = DropdownHelper.getSafeValue(
      u.functionalLodgment,
      _lodgmentOptions,
    );
    _area = DropdownHelper.getSafeValue(u.areaResponsibleFor, kAreasOptions);
    _userRole =
        DropdownHelper.getSafeValue(u.userRole, _roleOptions) ?? 'supervisor';
    _isActive = u.isActive;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _mobile.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'fullName': _fullName.text.trim(),
      'email': _email.text.trim(),
      'mobileNumber': _mobile.text.trim(),
      'address': _address.text.trim(),
      'functionalLodgment': _functionalLodgment,
      'areaResponsibleFor': _area,
      'userRole': _userRole,
      'isActive': _isActive,
      'updatedAt': DateTime.now(),
    };

    try {
      await _service.updateSupervisor(widget.user.uid, data);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تحديث بيانات المشرف')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل التحديث: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final readOnlyStyle = TextStyle(color: Colors.grey[700]);

    return Scaffold(
      appBar: AppBar(title: const Text('تعديل المشرف')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ثوابت لا تعدل
            TextFormField(
              initialValue: widget.user.customId,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'الرقم المخصص (ثابت)',
                border: OutlineInputBorder(),
              ),
              style: readOnlyStyle,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.user.institutionName,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'اسم المؤسسة (ثابت)',
                border: OutlineInputBorder(),
              ),
              style: readOnlyStyle,
            ),
            const SizedBox(height: 12),

            // قابل للتعديل
            TextFormField(
              controller: _fullName,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'بريد غير صالح' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobile,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الجوال',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 7) ? 'رقم غير صالح' : null,
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

            // الدور - باستخدام الدروب داون الآمن
            DropdownHelper.createSafeDropdown(
              label: 'الدور',
              value: _userRole,
              items: [
                for (int i = 0; i < _roleOptions.length; i++)
                  DropdownMenuItem(
                    value: _roleOptions[i],
                    child: Text(_roleLabels[i]),
                  ),
              ],
              onChanged: (v) => setState(() => _userRole = v!),
              validator: (v) => v == null ? 'اختر الدور' : null,
            ),
            const SizedBox(height: 12),

            // المرفق الوظيفي - باستخدام الدروب داون الآمن
            DropdownHelper.createSafeDropdown(
              label: 'المرفق الوظيفي',
              value: _functionalLodgment,
              items: [
                for (int i = 0; i < _lodgmentOptions.length; i++)
                  DropdownMenuItem(
                    value: _lodgmentOptions[i],
                    child: Text(_lodgmentLabels[i]),
                  ),
              ],
              onChanged: (v) => setState(() => _functionalLodgment = v),
            ),
            const SizedBox(height: 12),

            // المنطقة المسؤولة - باستخدام الدروب داون الآمن
            DropdownHelper.createSafeDropdown(
              label: 'المنطقة المسؤولة',
              value: _area,
              items: DropdownHelper.createMenuItems(kAreasOptions),
              onChanged: (v) => setState(() => _area = v),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('مفعل'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
