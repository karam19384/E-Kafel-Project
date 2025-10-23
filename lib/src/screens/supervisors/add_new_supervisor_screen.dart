// lib/src/screens/supervisors/add_new_supervisor_screen.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../blocs/supervisors/supervisors_bloc.dart';
import '../../services/firestore_service.dart';
import '../../utils/dropdown_utils_extended.dart';

class AddNewSupervisorScreen extends StatefulWidget {
  final String institutionId;
  final String kafalaHeadId;

  const AddNewSupervisorScreen({
    super.key,
    required this.institutionId,
    required this.kafalaHeadId,
  });

  @override
  State<AddNewSupervisorScreen> createState() => _AddNewSupervisorScreenState();
}

class _AddNewSupervisorScreenState extends State<AddNewSupervisorScreen> {
  final _form = GlobalKey<FormState>();

  // نصيّة
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  // Dropdown + "أخرى"
  String? _area; // القيمة المختارة من القائمة
  String? _functional; // القيمة المختارة من القائمة
  final _areaOther = TextEditingController(); // عند اختيار "أخرى"
  final _functionalOther = TextEditingController(); // عند اختيار "أخرى"

  // خيارات القوائم (عدّلها بما يناسبك أو اجلبها من Firestore)

  final _firestoreService = FirestoreService();
  String _institutionName = 'جاري التحميل...';

  final _picker = ImagePicker();
  File? _pickedImage;
  bool _uploadingPhoto = false;
  String? _uploadedPhotoUrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInstitutionName();
  }

  Future<void> _loadInstitutionName() async {
    final name = await _firestoreService.getInstitutionName(
      widget.institutionId,
    );
    if (!mounted) return;
    setState(() => _institutionName = name);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _areaOther.dispose();
    _functionalOther.dispose();
    super.dispose();
  }

  // ==== صورة المشرف ====
  Future<void> _pickImage(ImageSource source) async {
    final x = await _picker.pickImage(source: source, imageQuality: 70);
    if (x == null) return;
    setState(() {
      _pickedImage = File(x.path);
    });
  }

  Future<void> _uploadPhotoIfAny() async {
    if (_pickedImage == null) return;
    try {
      setState(() => _uploadingPhoto = true);
      final path =
          'supervisors/profile_photos/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(_pickedImage!);
      final url = await ref.getDownloadURL();
      setState(() => _uploadedPhotoUrl = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر رفع الصورة: $e')));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  // ==== حفظ ====
  void _save() async {
    if (!_form.currentState!.validate()) return;

    // تحقق من تحميل بيانات المؤسسة
    if (_institutionName == 'جاري التحميل...') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري تحميل بيانات المؤسسة...')),
      );
      return;
    }

    // كلمة المرور
    if (_password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
        ),
      );
      return;
    }
    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('كلمات المرور غير متطابقة')));
      return;
    }

    setState(() => _isLoading = true);

    // ارفع الصورة (إن وُجدت)
    await _uploadPhotoIfAny();

    final customId = _generateCustomId();

    // حسم قيم الدروب داون (مع "أخرى")
    final areaValue = _area == 'أخرى' ? _areaOther.text.trim() : (_area ?? '');
    final functionalValue = _functional == 'أخرى'
        ? _functionalOther.text.trim()
        : (_functional ?? '');

    context.read<SupervisorsBloc>().add(
      CreateSupervisorWithAuth(
        data: {
          'fullName': _name.text.trim(),
          'email': _email.text.trim(),
          'mobileNumber': _phone.text.trim(),
          'institutionId': widget.institutionId,
          'institutionName': _institutionName,
          'customId': customId,
          'kafalaHeadId': widget.kafalaHeadId,
          'areaResponsibleFor': areaValue,
          'functionalLodgment': functionalValue,
          'address': _address.text.trim(),
          'userRole': 'supervisor',
          'isActive': true,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
          'profileImageUrl': _uploadedPhotoUrl ?? '',
        },
        password: _password.text,
      ),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context, true);
  }

  String _generateCustomId() {
    final random = Random();
    const min = 100000;
    const max = 999999;
    return (min + random.nextInt(max - min)).toString();
  }

  void _showPickSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('اختيار من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('التقاط صورة بالكاميرا'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_pickedImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('إزالة الصورة'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _pickedImage = null;
                    _uploadedPhotoUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SupervisorsBloc, SupervisorsState>(
      listener: (context, state) {
        if (state is SupervisorsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('إضافة مشرف')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // اسم المؤسسة
                    Card(
                      color: Colors.grey[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.business,
                              color: Colors.teal,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'المؤسسة:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _institutionName,
                                style: const TextStyle(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // صورة المشرف
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: const Color(
                              0xFF6DAF97,
                            ).withOpacity(.15),
                            backgroundImage: _pickedImage != null
                                ? FileImage(_pickedImage!)
                                : (_uploadedPhotoUrl != null &&
                                      _uploadedPhotoUrl!.isNotEmpty)
                                ? NetworkImage(_uploadedPhotoUrl!)
                                      as ImageProvider
                                : null,
                            child:
                                (_pickedImage == null &&
                                    (_uploadedPhotoUrl == null ||
                                        _uploadedPhotoUrl!.isEmpty))
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Color(0xFF6DAF97),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _showPickSheet,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6DAF97),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(.15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_uploadingPhoto) ...[
                      const SizedBox(height: 8),
                      const Center(
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // الاسم
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الكامل',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'أدخل الاسم' : null,
                    ),
                    const SizedBox(height: 12),

                    // البريد
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'أدخل بريدًا صحيحًا'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // الجوال
                    TextFormField(
                      controller: _phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم الجوال',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_iphone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'أدخل رقم الجوال'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // العنوان
                    TextFormField(
                      controller: _address,
                      decoration: const InputDecoration(
                        labelText: 'العنوان',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // المنطقة المسؤولة (Dropdown)
                    DropdownHelper.dropdownWithOther(
                      label: 'المنطقة المسؤولة',
                      value: _area,
                      options: kAreasOptions,
                      onChanged: (v) => setState(() => _area = v),
                      otherController: _areaOther,
                    ),
                    SizedBox(height: 12),
                    DropdownHelper.dropdownWithOther(
                      label: 'المسمى/المهام الوظيفية',
                      value: _functional,
                      options: kFunctionalLodgmentOptions,
                      onChanged: (v) => setState(() => _functional = v),
                      otherController: _functionalOther,
                    ),
                    const SizedBox(height: 12),

                    // كلمة المرور
                    TextFormField(
                      controller: _password,
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),

                    // تأكيد كلمة المرور
                    TextFormField(
                      controller: _confirmPassword,
                      decoration: const InputDecoration(
                        labelText: 'تأكيد كلمة المرور',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_reset),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _save,
                        icon: const Icon(Icons.save),
                        label: const Text('حفظ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6DAF97),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
