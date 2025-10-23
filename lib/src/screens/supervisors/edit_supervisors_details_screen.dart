import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/supervisors/supervisors_bloc.dart';
import '../../models/user_model.dart';
import '../../utils/dropdown_utils_extended.dart';

class EditSupervisorsDetailsScreen extends StatefulWidget {
  final UserModel user;
  const EditSupervisorsDetailsScreen({super.key, required this.user});

  @override
  State<EditSupervisorsDetailsScreen> createState() =>
      _EditSupervisorsDetailsScreenState();
}

class _EditSupervisorsDetailsScreenState
    extends State<EditSupervisorsDetailsScreen> {
  final _form = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late String? _area;
  late String? _functional;
  final _areaOther = TextEditingController();
  final _functionalOther = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.fullName);
    _phone = TextEditingController(text: (widget.user.mobileNumber));
    _address = TextEditingController(text: widget.user.address ?? '');
    _area = widget.user.areaResponsibleFor;
    _functional = widget.user.functionalLodgment;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _areaOther.dispose();
    _functionalOther.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;

    final areaValue = _area == 'أخرى' ? _areaOther.text.trim() : (_area ?? '');
    final functionalValue =
        _functional == 'أخرى' ? _functionalOther.text.trim() : (_functional ?? '');

    context.read<SupervisorsBloc>().add(
          UpdateSupervisor(
            uid: widget.user.uid,
            data: {
              'fullName': _name.text.trim(),
              // لا نغيّر email ولا password هنا
              'mobileNumber': _phone.text.trim(),
              'address': _address.text.trim(),
              'areaResponsibleFor': areaValue,
              'functionalLodgment': functionalValue,
              'updatedAt': DateTime.now(),
            },
          ),
        );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل بيانات مشرف')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => v == null || v.isEmpty ? 'أدخل الاسم' : null,
            ),
            const SizedBox(height: 12),
            // البريد يظهر “للعرض” فقط
            TextFormField(
              initialValue: widget.user.email,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'البريد (غير قابل للتعديل)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(
                labelText: 'رقم الجوال',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_iphone),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'أدخل رقم الجوال' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home_outlined),
              ),
            ),
            const SizedBox(height: 12),

            DropdownHelper.dropdownWithOther(
              label: 'المنطقة المسؤولة',
              value: _area,
              options: kAreasOptions,
              onChanged: (v) => setState(() => _area = v),
              otherController: _areaOther,
            ),
            const SizedBox(height: 12),
            DropdownHelper.dropdownWithOther(
              label: 'المسمى/المهام الوظيفية',
              value: _functional,
              options: kFunctionalLodgmentOptions,
              onChanged: (v) => setState(() => _functional = v),
              otherController: _functionalOther,
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
