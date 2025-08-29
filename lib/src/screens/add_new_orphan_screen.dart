// ignore_for_file: unused_local_variable, library_private_types_in_public_api

import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:e_kafel/src/models/orphan.dart';
import 'package:e_kafel/src/providers/orphan_provider.dart';
import 'package:file_picker/file_picker.dart';

class AddNewOrphanScreen extends StatefulWidget {
  static const routeName = '/add-orphan';

  const AddNewOrphanScreen({super.key});

  @override
  _AddNewOrphanScreenState createState() => _AddNewOrphanScreenState();
}

class _AddNewOrphanScreenState extends State<AddNewOrphanScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // القوائم المنسدلة
  String? _selectedGender;
  String? _selectedMaritalStatus;
  String? _selectedKinship;
  String? _selectedGovernorate;
  String? _selectedCity;

  // الملفات
  File? _idCardFile;
  File? _deathCertificateFile;
  File? _orphanPhotoFile;
  // ignore: unused_field
  final ImagePicker _picker = ImagePicker();

  // Controllers لكل الحقول النصية
  final _nameController = TextEditingController();
  final _deceasedNameController = TextEditingController();
  final _causeOfDeathController = TextEditingController();
  final _deceasedIdController = TextEditingController();
  final _orphanIdController = TextEditingController();
  final _motherIdController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _breadwinnerIdController = TextEditingController();
  final _breadwinnerNameController = TextEditingController();
  final _malesCountController = TextEditingController();
  final _femalesCountController = TextEditingController();
  final _totalMembersController = TextEditingController();
  final _mobileController = TextEditingController();
  final _phoneController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _educationLevelController = TextEditingController();
  final _neighborhoodController = TextEditingController();

  // التواريخ
  DateTime? _dateOfDeath;
  DateTime? _orphanDateOfBirth;

  @override
  void dispose() {
    // تنظيف جميع الـ Controllers
    _nameController.dispose();
    _deceasedNameController.dispose();
    _causeOfDeathController.dispose();
    _deceasedIdController.dispose();
    _orphanIdController.dispose();
    _motherIdController.dispose();
    _motherNameController.dispose();
    _breadwinnerIdController.dispose();
    _breadwinnerNameController.dispose();
    _malesCountController.dispose();
    _femalesCountController.dispose();
    _totalMembersController.dispose();
    _mobileController.dispose();
    _phoneController.dispose();
    _schoolNameController.dispose();
    _gradeController.dispose();
    _educationLevelController.dispose();
    _neighborhoodController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(bool isIdCard, bool isOrphanPhoto) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image, // يمكنك تحديد نوع الملف كصور فقط
      );

      if (result != null) {
        if (kIsWeb) {
          Uint8List? fileBytes = result.files.first.bytes;
          String? fileName = result.files.first.name;

          if (kDebugMode) {
            print('Web file name: $fileName');
          }
        } else {
          // إذا كان التطبيق يعمل على الأندرويد أو iOS
          File file = File(result.files.first.path!);

          // الآن يمكنك استخدام file لرفع الملف
          // ...
          if (kDebugMode) {
            print('Mobile file path: ${file.path}');
          }

          setState(() {
            if (isOrphanPhoto) {
              _orphanPhotoFile = file;
            } else if (isIdCard) {
              _idCardFile = file;
            } else {
              _deathCertificateFile = file;
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل في اختيار الملف: $e')));
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDateOfDeath) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isDateOfDeath) {
          _dateOfDeath = picked;
        } else {
          _orphanDateOfBirth = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String orphanNo = (100000 + Random().nextInt(900000)).toString();
      Orphan newOrphan = Orphan(
        name: _nameController.text,
        deceasedName: _deceasedNameController.text,
        causeOfDeath: _causeOfDeathController.text,
        dateOfDeath: _dateOfDeath,
        deceasedIdNumber: _deceasedIdController.text,
        gender: _selectedGender,
        orphanIdNumber: _orphanIdController.text,
        dateOfBirth: _orphanDateOfBirth,
        motherIdNumber: _motherIdController.text,
        motherName: _motherNameController.text,
        breadwinnerIdNumber: _breadwinnerIdController.text,
        breadwinnerName: _breadwinnerNameController.text,
        breadwinnerMaritalStatus: _selectedMaritalStatus,
        breadwinnerKinship: _selectedKinship,
        governorate: _selectedGovernorate,
        city: _selectedCity,
        neighborhood: _neighborhoodController.text,
        numberOfMales: int.tryParse(_malesCountController.text) ?? 0,
        numberOfFemales: int.tryParse(_femalesCountController.text) ?? 0,
        totalFamilyMembers: int.tryParse(_totalMembersController.text) ?? 0,
        mobileNumber: _mobileController.text,
        phoneNumber: _phoneController.text,
        orphanNo: orphanNo,
        schoolName: _schoolNameController.text,
        grade: _gradeController.text,
        educationLevel: _educationLevelController.text,
        idCardUrl: null,
        deathCertificateUrl: null,
        orphanPhotoUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await Provider.of<OrphanProvider>(context, listen: false).addOrphan(
        newOrphan,
        _idCardFile,
        _deathCertificateFile,
        _orphanPhotoFile,
      );

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت إضافة اليتيم بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في الإضافة: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إضافة يتيم جديد'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _submitForm,
            icon: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Icon(Icons.save),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // القسم 1: المعلومات الأساسية
                    Text(
                      'المعلومات الأساسية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildFilePicker(
                      label: 'صورة شخصية لليتيم',
                      file: _orphanPhotoFile,
                      onPressed: () => _pickFile(false, true),
                    ),
                    _buildTextFormField(
                      controller: _nameController,
                      labelText: 'الاسم الرباعي لليتيم',
                      validator: (value) =>
                          value!.isEmpty ? 'هذا الحقل مطلوب' : null,
                    ),
                    _buildDropdown(
                      value: _selectedGender,
                      items: ['ذكر', 'أنثى'],
                      hint: 'اختر الجنس',
                      label: 'الجنس',
                      onChanged: (value) =>
                          setState(() => _selectedGender = value),
                      validator: (value) =>
                          value == null ? 'هذا الحقل مطلوب' : null,
                    ),
                    _buildTextFormField(
                      controller: _orphanIdController,
                      labelText: 'رقم هوية اليتيم',
                      keyboardType: TextInputType.number,
                    ),
                    _buildDateField(
                      date: _orphanDateOfBirth,
                      label: 'تاريخ ميلاد اليتيم',
                      onTap: () => _selectDate(context, false),
                    ),

                    // القسم 2: معلومات المتوفى
                    SizedBox(height: 20),
                    Text(
                      'معلومات المتوفى',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildTextFormField(
                      controller: _deceasedNameController,
                      labelText: 'الاسم الرباعي للمتوفى',
                      validator: (value) =>
                          value!.isEmpty ? 'هذا الحقل مطلوب' : null,
                    ),
                    _buildTextFormField(
                      controller: _causeOfDeathController,
                      labelText: 'سبب الوفاة',
                    ),
                    _buildDateField(
                      date: _dateOfDeath,
                      label: 'تاريخ الوفاة',
                      onTap: () => _selectDate(context, true),
                    ),
                    _buildTextFormField(
                      controller: _deceasedIdController,
                      labelText: 'رقم هوية المتوفى',
                      keyboardType: TextInputType.number,
                    ),

                    // القسم 3: معلومات الأم
                    SizedBox(height: 20),
                    Text(
                      'معلومات الأم',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildTextFormField(
                      controller: _motherNameController,
                      labelText: 'اسم الأم',
                    ),
                    _buildTextFormField(
                      controller: _motherIdController,
                      labelText: 'رقم هوية الأم',
                      keyboardType: TextInputType.number,
                    ),

                    // القسم 4: معلومات المعيل
                    SizedBox(height: 20),
                    Text(
                      'معلومات المعيل',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildTextFormField(
                      controller: _breadwinnerNameController,
                      labelText: 'اسم المعيل',
                    ),
                    _buildTextFormField(
                      controller: _breadwinnerIdController,
                      labelText: 'رقم هوية المعيل',
                      keyboardType: TextInputType.number,
                    ),
                    _buildDropdown(
                      value: _selectedMaritalStatus,
                      items: ['أعزب', 'متزوج', 'مطلق', 'أرمل'],
                      hint: 'الحالة الاجتماعية',
                      label: 'الحالة الاجتماعية للمعيل',
                      onChanged: (value) =>
                          setState(() => _selectedMaritalStatus = value),
                    ),
                    _buildDropdown(
                      value: _selectedKinship,
                      items: [
                        'أب',
                        'أم',
                        'جد',
                        'جدة',
                        'عم',
                        'عمة',
                        'خال',
                        'خالة',
                        'أخ',
                        'أخت',
                      ],
                      hint: 'صلة القرابة',
                      label: 'صلة القرابة باليتيم',
                      onChanged: (value) =>
                          setState(() => _selectedKinship = value),
                    ),

                    // القسم 5: العنوان
                    SizedBox(height: 20),
                    Text(
                      'العنوان',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildDropdown(
                      value: _selectedGovernorate,
                      items: ['شمال غزة', 'غزة', 'الوسطى', 'خانيونس', 'رفح'],
                      hint: 'اختر المحافظة',
                      label: 'المحافظة',
                      onChanged: (value) =>
                          setState(() => _selectedGovernorate = value),
                      validator: (value) =>
                          value == null ? 'هذا الحقل مطلوب' : null,
                    ),
                    _buildDropdown(
                      value: _selectedCity,
                      items: [
                        'غزة',
                        'جباليا',
                        'بيت لاهيا',
                        'بيت حانون',
                        'دير البلح',
                        'خزاعة',
                        'عبسان',
                        'رفح',
                      ],
                      hint: 'اختر المدينة/البلدية',
                      label: 'المدينة/البلدية',
                      onChanged: (value) =>
                          setState(() => _selectedCity = value),
                    ),
                    _buildTextFormField(
                      controller: _neighborhoodController,
                      labelText: 'الحي/المنطقة',
                    ),

                    // القسم 6: معلومات العائلة
                    SizedBox(height: 20),
                    Text(
                      'معلومات العائلة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildTextFormField(
                      controller: _malesCountController,
                      labelText: 'عدد الذكور',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'هذا الحقل مطلوب';
                        if (int.tryParse(value) == null)
                          return 'أدخل رقمًا صحيحًا';
                        return null;
                      },
                    ),
                    _buildTextFormField(
                      controller: _femalesCountController,
                      labelText: 'عدد الإناث',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'هذا الحقل مطلوب';
                        if (int.tryParse(value) == null)
                          return 'أدخل رقمًا صحيحًا';
                        return null;
                      },
                    ),
                    _buildTextFormField(
                      controller: _totalMembersController,
                      labelText: 'إجمالي أفراد الأسرة',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'هذا الحقل مطلوب';
                        if (int.tryParse(value) == null)
                          return 'أدخل رقمًا صحيحًا';
                        return null;
                      },
                    ),

                    // القسم 7: الاتصال
                    SizedBox(height: 20),
                    Text(
                      'معلومات الاتصال',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildTextFormField(
                      controller: _mobileController,
                      labelText: 'رقم الجوال',
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextFormField(
                      controller: _phoneController,
                      labelText: 'رقم الهاتف',
                      keyboardType: TextInputType.phone,
                    ),

                    // القسم 8: التعليم
                    SizedBox(height: 20),
                    Text(
                      'معلومات التعليم',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildTextFormField(
                      controller: _schoolNameController,
                      labelText: 'اسم المدرسة',
                    ),
                    _buildTextFormField(
                      controller: _gradeController,
                      labelText: 'الصف',
                    ),
                    _buildTextFormField(
                      controller: _educationLevelController,
                      labelText: 'المستوى التعليمي',
                    ),

                    // القسم 9: المستندات
                    SizedBox(height: 20),
                    Text(
                      'المستندات المطلوبة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildFilePicker(
                      label: 'صورة هوية المعيل',
                      file: _idCardFile,
                      onPressed: () => _pickFile(true, false),
                    ),
                    _buildFilePicker(
                      label: 'شهادة الوفاة',
                      file: _deathCertificateFile,
                      onPressed: () => _pickFile(false, false),
                    ),

                    // زر الحفظ
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator()
                          : Text(
                              'حفظ البيانات',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // دالة مساعدة لإنشاء TextFormField
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  // دالة مساعدة لإنشاء Dropdown
  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required String label,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: validator,
      ),
    );
  }

  // دالة مساعدة لإنشاء حقل التاريخ
  Widget _buildDateField({
    required DateTime? date,
    required String label,
    required Function() onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date != null
                    ? "${date.day}/${date.month}/${date.year}"
                    : 'اختر التاريخ',
                style: TextStyle(fontSize: 16),
              ),
              Icon(Icons.calendar_today, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لإنشاء حقل رفع الملف
  Widget _buildFilePicker({
    required String label,
    required File? file,
    required Function() onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(onPressed: onPressed, child: Text('اختر ملف')),
              SizedBox(width: 16),
              if (file != null)
                Expanded(
                  child: Text(
                    file.path.split('/').last,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
