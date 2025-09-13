// ignore_for_file: unused_local_variable

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:e_kafel/src/models/orphan_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/orphans/orphans_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/home/home_bloc.dart'; // ✅ تم استيراد HomeBloc

class AddNewOrphanScreen extends StatefulWidget {
  static const routeName = '/add-orphan';

  final String institutionId;

  const AddNewOrphanScreen({super.key, required this.institutionId});

  @override
  _AddNewOrphanScreenState createState() => _AddNewOrphanScreenState();
}

class _AddNewOrphanScreenState extends State<AddNewOrphanScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String? _deathDateErrorText;
  String? _birthDateErrorText;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _deceasedNameController = TextEditingController();
  final TextEditingController _deceasedIdNumberController = TextEditingController();
  final TextEditingController _orphanIdNumberController = TextEditingController();
  final TextEditingController _motherIdNumberController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _breadwinnerIdNumberController = TextEditingController();
  final TextEditingController _breadwinnerNameController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _numberOfMalesController = TextEditingController();
  final TextEditingController _numberOfFemalesController = TextEditingController();
  final TextEditingController _totalFamilyMembersController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _educationLevelController = TextEditingController();

  // القوائم المنسدلة
  String? _selectedCauseOfDeath = 'استشهاد';
  String? _selectedGender = 'ذكر';
  String? _selectedMaritalStatus = 'أرمل/ة';
  String? _selectedKinship = 'الأم';
  String? _selectedGovernorate;
  String? _selectedCity;

 // قائمة المحافظات والمدن
  final Map<String, List<String>> _governoratesAndCities = {
    'غزة': ['الشجاعية', 'الزيتون', 'التفاح', 'الدرج','النصر','الرمال','تل الهوا','الشاطئ','الجلاء','الشيخ رضوان'],
    'شمال غزة': ['الكرامة',' جباليا البلد', 'بيت لاهيا', 'بيت حانون','الصفطاوي','التوام','مشروع بيت لاهيا','العطاطرة'],
    'خان يونس': [' خان يونس البلد', 'عبسان الكبيرة', 'عبسان الصغيرة', 'بني سهيلا','الفخاري','المنارة','معن','مدينة حمد'],
    'رفح': ['رفح', 'الشوكة', 'الزوارعة','النجمة','العودة','حي السلام','الحي البرازيلي','الحي السعودي'],
    'المنطقة الوسطى': ['دير البلح', 'النصيرات', 'البريج', 'المغازي','المصدر'],
  };

  File? _idCardFile;
  File? _deathCertificateFile;
  File? _orphanPhotoFile;
  Uint8List? _idCardBytes;
  Uint8List? _deathCertificateBytes;
  Uint8List? _orphanPhotoBytes;

  DateTime? _dateOfDeath;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    _motherNameController.addListener(_updateBreadwinnerName);
    _motherIdNumberController.addListener(_updateBreadwinnerId);
  }

  void _updateBreadwinnerName() {
    setState(() {
      _breadwinnerNameController.text = _motherNameController.text;
    });
  }

  void _updateBreadwinnerId() {
    setState(() {
      _breadwinnerIdNumberController.text = _motherIdNumberController.text;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deceasedNameController.dispose();
    _deceasedIdNumberController.dispose();
    _orphanIdNumberController.dispose();
    _motherIdNumberController.dispose();
    _motherNameController.dispose();
    _breadwinnerIdNumberController.dispose();
    _breadwinnerNameController.dispose();
    _neighborhoodController.dispose();
    _numberOfMalesController.dispose();
    _numberOfFemalesController.dispose();
    _totalFamilyMembersController.dispose();
    _mobileNumberController.dispose();
    _phoneNumberController.dispose();
    _schoolNameController.dispose();
    _gradeController.dispose();
    _educationLevelController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {required bool isDateOfBirth}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDateOfBirth ? DateTime.now() :_dateOfDeath ?? DateTime.now(),
      firstDate: isDateOfBirth ? DateTime(DateTime.now().year - 18)  : DateTime(2000),
      lastDate:  DateTime.now() ,
    );
    if (picked != null) {
      setState(() {
        if (isDateOfBirth) {
          _dateOfBirth = picked;
          _birthDateErrorText = null; //  إزالة رسالة الخطأ عند اختيار التاريخ صح
        } else {
          _dateOfDeath = picked;
          _deathDateErrorText = null; //  إزالة رسالة الخطأ عند اختيار التاريخ صح
        }
      });
    }
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dateOfDeath == null) {
      setState(() {
        _deathDateErrorText = 'الرجاء إدخال تاريخ الوفاة';
      });
      return;
    }
    if (_dateOfBirth == null) {
      setState(() {
        _birthDateErrorText = 'الرجاء إدخال تاريخ الميلاد';
      });
      return;
    }

        setState(() {
      _isLoading = true;
    });

    final orphan = Orphan(
      institutionId: widget.institutionId,
      name: _nameController.text,
      deceasedName: _deceasedNameController.text,
      causeOfDeath: _selectedCauseOfDeath,
      dateOfDeath: _dateOfDeath,
      deceasedIdNumber: _deceasedIdNumberController.text,
      gender: _selectedGender,
      orphanIdNumber: _orphanIdNumberController.text,
      dateOfBirth: _dateOfBirth,
      motherIdNumber: _motherIdNumberController.text,
      motherName: _motherNameController.text,
      breadwinnerIdNumber: _breadwinnerIdNumberController.text,
      breadwinnerName: _breadwinnerNameController.text,
      breadwinnerMaritalStatus: _selectedMaritalStatus,
      breadwinnerKinship: _selectedKinship,
      governorate: _selectedGovernorate,
      city: _selectedCity,
      neighborhood: _neighborhoodController.text,
      numberOfMales: int.tryParse(_numberOfMalesController.text) ?? 0,
      numberOfFemales: int.tryParse(_numberOfFemalesController.text) ?? 0,
      totalFamilyMembers: int.tryParse(_totalFamilyMembersController.text) ?? 0,
      mobileNumber: _mobileNumberController.text,
      phoneNumber: _phoneNumberController.text,
      orphanNo: '', // سيتم توليده تلقائياً
      schoolName: _schoolNameController.text,
      grade: _gradeController.text,
      educationLevel: _educationLevelController.text,
      idCardUrl: null,
      deathCertificateUrl: null,
      orphanPhotoUrl: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    context.read<OrphansBloc>().add(
          AddOrphan(
            orphan: orphan,
            idCardFile: _idCardFile,
            deathCertificateFile: _deathCertificateFile,
            orphanPhotoFile: _orphanPhotoFile,
            idCardBytes: _idCardBytes,
            deathCertificateBytes: _deathCertificateBytes,
            orphanPhotoBytes: _orphanPhotoBytes,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrphansBloc, OrphansState>(
      listener: (context, state) {
        if (state is OrphanAdded) {
          setState(() {
            _isLoading = false;
          });
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Center(
                  child: Text(
                    'تمت الإضافة بنجاح',
                    style: TextStyle(
                      color: Color(0xFF6DAF97),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('تمت إضافة اليتيم بنجاح.', textAlign: TextAlign.center),
                    SizedBox(height: 16),
                    Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF6DAF97),
                      size: 60,
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.read<HomeBloc>().add(LoadHomeData());
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'موافق',
                      style: TextStyle(
                        color: Color(0xFF6DAF97),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        } else if (state is OrphansError) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add orphan: ${state.message}')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة يتيم جديد'),
          backgroundColor: const Color(0xFF6DAF97),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildSectionTitle('البيانات الشخصية'),
                _buildTextField(
                    controller: _nameController,
                    label: 'اسم اليتيم',
                    isRequired: true),
                _buildTextField(
                    controller: _deceasedNameController,
                    label: 'اسم المتوفى',
                    isRequired: true),
                _buildDropdownField(
                  label: 'سبب الوفاة',
                  value: _selectedCauseOfDeath,
                  items: ['استشهاد', 'مرض', 'حادث', 'أخرى'],
                  onChanged: (value) {
                    setState(() {
                      _selectedCauseOfDeath = value;
                    });
                  },
                ),
                // ✅ استخدام دالة بناء حقل التاريخ المعدلة
                _buildDateField(
                  label: 'تاريخ الوفاة',
                  date: _dateOfDeath,
                  onPressed: () => _selectDate(context, isDateOfBirth: false),
                  errorText: _deathDateErrorText,
                ),
                _buildTextField(
                    controller: _deceasedIdNumberController,
                    label: 'رقم هوية المتوفى',
                    isRequired: true),
                _buildDropdownField(
                  label: 'الجنس',
                  value: _selectedGender,
                  items: ['ذكر', 'أنثى'],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
                _buildTextField(
                    controller: _orphanIdNumberController,
                    label: 'رقم هوية اليتيم',
                    isRequired: true),
                _buildDateField(
                  label: 'تاريخ الميلاد',
                  date: _dateOfBirth,
                  onPressed: () => _selectDate(context, isDateOfBirth: true),
                  errorText: _birthDateErrorText,
                ),
                _buildTextField(
                    controller: _schoolNameController, label: 'اسم المدرسة'),
                _buildTextField(controller: _gradeController, label: 'الصف'),
                _buildTextField(
                    controller: _educationLevelController,
                    label: 'المستوى التعليمي'),
                const SizedBox(height: 20),
                _buildSectionTitle('بيانات العائلة'),
                _buildTextField(
                    controller: _motherNameController,
                    label: 'اسم الأم',
                    isRequired: true),
                _buildTextField(
                    controller: _motherIdNumberController,
                    label: 'رقم هوية الأم',
                    isRequired: true),
                _buildTextField(
                    controller: _breadwinnerNameController,
                    label: 'اسم المعيل',
                    isRequired: true,
                    readOnly: true),
                _buildTextField(
                    controller: _breadwinnerIdNumberController,
                    label: 'رقم هوية المعيل',
                    isRequired: true,
                    readOnly: true),
                _buildDropdownField(
                  label: 'الحالة الاجتماعية للمعيل',
                  value: _selectedMaritalStatus,
                  items: ['أرمل/ة', 'أعزب/ة', 'متزوج/ة', 'مطلق/ة'],
                  onChanged: (value) {
                    setState(() {
                      _selectedMaritalStatus = value;
                    });
                  },
                ),
                _buildDropdownField(
                  label: 'صلة القرابة بالمعيل',
                  value: _selectedKinship,
                  items: [
                    'الأم',
                    'الأب',
                    'أخ',
                    'أخت',
                    'عم',
                    'عمة',
                    'جد',
                    'جدة',
                    'أخرى'
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedKinship = value;
                    });
                  },
                ),
                _buildDropdownField(
                  label: 'المحافظة',
                  value: _selectedGovernorate,
                  items: _governoratesAndCities.keys.toList(),
                  isRequired: true,
                  onChanged: (value) {
                    setState(() {
                      _selectedGovernorate = value;
                      _selectedCity = null;
                    });
                  },
                ),
                if (_selectedGovernorate != null)
                  _buildDropdownField(
                    label: 'المدينة',
                    value: _selectedCity,
                    items: _governoratesAndCities[_selectedGovernorate!]!,
                    isRequired: true,
                    onChanged: (value) {
                      setState(() {
                        _selectedCity = value;
                      });
                    },
                  ),
                _buildTextField(
                    controller: _neighborhoodController, label: 'الحي'),
                _buildTextField(
                    controller: _numberOfMalesController,
                    label: 'عدد الذكور',
                    keyboardType: TextInputType.number),
                _buildTextField(
                    controller: _numberOfFemalesController,
                    label: 'عدد الإناث',
                    keyboardType: TextInputType.number),
                _buildTextField(
                    controller: _totalFamilyMembersController,
                    label: 'إجمالي أفراد العائلة',
                    keyboardType: TextInputType.number,
                    isRequired: true),
                _buildTextField(
                    controller: _mobileNumberController,
                    label: 'رقم الجوال',
                    keyboardType: TextInputType.phone,
                    isRequired: true),
                _buildTextField(
                    controller: _phoneNumberController,
                    label: 'رقم الهاتف',
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 20),
                _buildSectionTitle('المستندات'),
                _buildFilePicker(
                  label: 'بطاقة الهوية',
                  file: _idCardFile,
                  bytes: _idCardBytes,
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['jpg', 'png', 'pdf'],
                      withData: kIsWeb,
                    );
                    if (result != null) {
                      if (kIsWeb) {
                        setState(() {
                          _idCardBytes = result.files.first.bytes;
                        });
                      } else {
                        setState(() {
                          _idCardFile = File(result.files.single.path!);
                        });
                      }
                    }
                  },
                ),
                _buildFilePicker(
                  label: 'شهادة الوفاة',
                  file: _deathCertificateFile,
                  bytes: _deathCertificateBytes,
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['jpg', 'png', 'pdf'],
                      withData: kIsWeb,
                    );
                    if (result != null) {
                      if (kIsWeb) {
                        setState(() {
                          _deathCertificateBytes = result.files.first.bytes;
                        });
                      } else {
                        setState(() {
                          _deathCertificateFile = File(result.files.single.path!);
                        });
                      }
                    }
                  },
                ),
                _buildFilePicker(
                  label: 'صورة اليتيم',
                  file: _orphanPhotoFile,
                  bytes: _orphanPhotoBytes,
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['jpg', 'png', 'pdf'],
                      withData: kIsWeb,
                    );
                    if (result != null) {
                      if (kIsWeb) {
                        setState(() {
                          _orphanPhotoBytes = result.files.first.bytes;
                        });
                      } else {
                        setState(() {
                          _orphanPhotoFile = File(result.files.single.path!);
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6DAF97),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'إضافة يتيم',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لإنشاء عنوان القسم
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4C7F7F),
        ),
      ),
    );
  }

  // دالة مساعدة لإنشاء حقل الإدخال
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF6DAF97)),
          ),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'الرجاء إدخال $label';
          }
          return null;
        },
      ),
    );
  }

  // دالة مساعدة لإنشاء حقل القائمة المنسدلة
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF6DAF97)),
          ),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (isRequired && value == null) {
            return 'الرجاء اختيار $label';
          }
          return null;
        },
      ),
    );
  }

  // ✅ دالة بناء حقل التاريخ المعدلة
  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onPressed,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onPressed,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6DAF97)),
            ),
            errorText: errorText, // ✅ استخدام متغير الحالة لعرض الخطأ
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                date != null
                    ? DateFormat('d/M/yyyy').format(date)
                    : 'اختر التاريخ',
                style: const TextStyle(fontSize: 16),
              ),
              const Icon(Icons.calendar_today, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لإنشاء حقل رفع الملف
  Widget _buildFilePicker({
    required String label,
    File? file,
    Uint8List? bytes,
    required Function() onPressed,
  }) {
    String fileName = '';
    if (kIsWeb) {
      if (bytes != null) {
        fileName = 'تم اختيار ملف';
      }
    } else {
      if (file != null) {
        fileName = file.path.split('/').last;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6DAF97),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('اختر ملف', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Text(
                  fileName,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}