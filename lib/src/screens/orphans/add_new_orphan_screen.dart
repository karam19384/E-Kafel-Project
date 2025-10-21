// add_new_orphan_screen.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/orphans/orphans_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/home/home_bloc.dart';
import '../../models/orphan_model.dart';

class AddNewOrphanScreen extends StatefulWidget {
  static const routeName = '/add_new_orphan_screen';

  final String institutionId;
  final String kafalaHeadId;

  const AddNewOrphanScreen({
    super.key,
    required this.institutionId,
    required this.kafalaHeadId,
  });

  @override
  _AddNewOrphanScreenState createState() => _AddNewOrphanScreenState();
}

class _AddNewOrphanScreenState extends State<AddNewOrphanScreen> {
  // ================== قوائم منسدلة ثابتة ==================
  final List<String> _grades = const [
    'لا يدرس',
    'روضة',
    'الصف الأول',
    'الصف الثاني',
    'الصف الثالث',
    'الصف الرابع',
    'الصف الخامس',
    'الصف السادس',
    'الصف السابع',
    'الصف الثامن',
    'الصف التاسع',
    'الصف العاشر',
    'الصف الحادي عشر',
    'الصف الثاني عشر',
  ];

  final List<String> _healthOptions = const [
    'سليم',
    'سكري',
    'ربو',
    'فقر دم',
    'حساسية',
    'أمراض قلب',
    'إعاقة سمعية',
    'إعاقة بصرية',
    'إعاقة حركية',
    'أخرى',
  ];

  // ================== حالة الواجهة ==================
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String? _birthDateErrorText;
  String? _deathDateErrorText;

  // اختيارات
  String? _selectedGender = 'ذكر';
  String? _selectedOrphanType =
      'يتيم الأب'; // القيم: يتيم الأب / يتيم الأم / يتيم الوالدين
  String? _selectedCauseOfDeath = 'استشهاد';
  String? _selectedBreadwinnerKinship = 'الأم';
  String? _selectedBreadwinnerMaritalStatus = 'أرمل/ة';
  final String _selectedEducationStatus = 'جيد';
  String? _selectedHousingCondition = 'جيد';
  String? _selectedHousingOwnership = 'ملك';
  String? _selectedMonthlyIncome = 'أقل من 300';

  String? _selectedGrade; // الصف الدراسي
  String? _selectedHealth; // الحالة الصحية

  String? _selectedGovernorate;
  String? _selectedCity;

  // ================== Controllers: الاسم الخماسي ==================
  final TextEditingController _orphanFirstController =
      TextEditingController(); // اسم اليتيم
  final TextEditingController _orphanFatherController =
      TextEditingController(); // اسم الأب
  final TextEditingController _orphanGrandController =
      TextEditingController(); // اسم الجد
  final TextEditingController _orphanGreatGrandController =
      TextEditingController(); // اسم جد الأب
  final TextEditingController _orphanFamilyController =
      TextEditingController(); // اسم العائلة

  // ================== Controllers: معلومات شخصية ==================
  final TextEditingController _orphanIdNumberController =
      TextEditingController();

  // ================== Controllers: الأب ==================
  final TextEditingController _fatherIdNumberController =
      TextEditingController();
  final TextEditingController _fatherAgeController = TextEditingController();

  // ================== Controllers: الأم ==================
  final TextEditingController _motherNameController =
      TextEditingController(); // اسم الأم الرباعي
  final TextEditingController _motherIdNumberController =
      TextEditingController();
  final TextEditingController _motherAgeController = TextEditingController();

  // ================== Controllers: المتوفي ==================
  final TextEditingController _deceasedNameController = TextEditingController();
  final TextEditingController _deceasedIdNumberController =
      TextEditingController();

  // ================== Controllers: المعيل ==================
  final TextEditingController _breadwinnerNameController =
      TextEditingController();
  final TextEditingController _breadwinnerIdNumberController =
      TextEditingController();
  final TextEditingController _breadwinnerAgeController =
      TextEditingController();

  // ================== Controllers: العنوان والتواصل ==================
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _alternativeMobileController =
      TextEditingController();
  final TextEditingController _whatsappNumberController =
      TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();

  // ================== Controllers: العائلة ==================
  final TextEditingController _numberOfMalesController =
      TextEditingController();
  final TextEditingController _numberOfFemalesController =
      TextEditingController();
  final TextEditingController _totalFamilyMembersController =
      TextEditingController();

  // ================== Controllers: التعليم والصحة ==================
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _diseaseDetailsController =
      TextEditingController(); // تفاصيل الأمراض عند عدم اختيار "سليم"

  // ================== Controllers: الدخل ==================
  final TextEditingController _incomeSourcesController =
      TextEditingController();

  // ================== Controllers: ملاحظات ==================
  final TextEditingController _notesController = TextEditingController();

  // ================== ملفات ==================
  File? _orphanPhotoFile;
  File? _fatherIdPhotoFile;
  File? _motherIdPhotoFile;
  File? _deceasedPhotoFile;
  File? _deathCertificateFile;
  File? _birthCertificateFile;
  File? _breadwinnerIdPhotoFile;

  // ================== تواريخ ==================
  DateTime? _dateOfBirth;
  DateTime? _dateOfDeath;

  // ================== المحافظات والمدن ==================
  final Map<String, List<String>> _governoratesAndCities = const {
    'غزة': [
      'الشجاعية',
      'الزيتون',
      'التفاح',
      'الدرج',
      'النصر',
      'الرمال',
      'تل الهوا',
      'الشاطئ',
      'الجلاء',
      'الشيخ رضوان',
    ],
    'شمال غزة': [
      'الكرامة',
      'جباليا البلد',
      'بيت لاهيا',
      'بيت حانون',
      'الصفطاوي',
      'التوام',
      'مشروع بيت لاهيا',
      'العطاطرة',
    ],
    'خان يونس': [
      'خان يونس البلد',
      'عبسان الكبيرة',
      'عبسان الصغيرة',
      'بني سهيلا',
      'الفخاري',
      'المنارة',
      'معن',
      'مدينة حمد',
    ],
    'رفح': [
      'رفح',
      'الشوكة',
      'الزوارعة',
      'النجمة',
      'العودة',
      'حي السلام',
      'الحي البرازيلي',
      'الحي السعودي',
    ],
    'المنطقة الوسطى': ['دير البلح', 'النصيرات', 'البريج', 'المغازي', 'المصدر'],
  };

  // ================== Lifecycle ==================
  @override
  void initState() {
    super.initState();
    _setupAutoFillListeners();
    _applyOrphanTypeRules();
  }

  void _setupAutoFillListeners() {
    // عند تغيير اسم الأم - إذا كان يتيم الأب يتم نسخه للمعيل
    _motherNameController.addListener(() {
      if (_selectedOrphanType == 'يتيم الأب') {
        _breadwinnerNameController.text = _motherNameController.text;
      }
    });

    // عند تغيير رقم هوية الأم - إذا كان يتيم الأب يتم نسخه للمتوفى
    _motherIdNumberController.addListener(() {
      if (_selectedOrphanType == 'يتيم الأب') {
        _deceasedIdNumberController.text = _motherIdNumberController.text;
      }
    });

    // عند تغيير عمر الأم - إذا كان يتيم الأب يتم نسخه للمعيل
    _motherAgeController.addListener(() {
      if (_selectedOrphanType == 'يتيم الأب') {
        _breadwinnerAgeController.text = _motherAgeController.text;
      }
    });

    // عند تغيير اسم الأب - إذا كان يتيم الأم يتم نسخه للمعيل
    _orphanFatherController.addListener(() {
      if (_selectedOrphanType == 'يتيم الأم') {
        _breadwinnerNameController.text = _buildFatherFullName();
      }
    });

    // عند تغيير رقم هوية الأب - إذا كان يتيم الأم يتم نسخه للمتوفى
    _fatherIdNumberController.addListener(() {
      if (_selectedOrphanType == 'يتيم الأم') {
        _deceasedIdNumberController.text = _fatherIdNumberController.text;
      }
    });

    // عند تغيير عمر الأب - إذا كان يتيم الأم يتم نسخه للمعيل
    _fatherAgeController.addListener(() {
      if (_selectedOrphanType == 'يتيم الأم') {
        _breadwinnerAgeController.text = _fatherAgeController.text;
      }
    });

    // عند تغيير أي من أسماء الأب (لبناء الاسم الكامل)
    _orphanFatherController.addListener(_updateFatherRelatedFields);
    _orphanGrandController.addListener(_updateFatherRelatedFields);
    _orphanGreatGrandController.addListener(_updateFatherRelatedFields);
    _orphanFamilyController.addListener(_updateFatherRelatedFields);
  }

  void _updateFatherRelatedFields() {
    final fatherFullName = _buildFatherFullName();

    if (_selectedOrphanType == 'يتيم الأم') {
      _deceasedNameController.text = _motherNameController.text;
      _breadwinnerNameController.text = fatherFullName;
    } else if (_selectedOrphanType == 'يتيم الأب') {
      _deceasedNameController.text = fatherFullName;
      _breadwinnerNameController.text = _motherNameController.text;
    }
  }

  @override
  void dispose() {
    // الأسماء
    _orphanFirstController.dispose();
    _orphanFatherController.dispose();
    _orphanGrandController.dispose();
    _orphanGreatGrandController.dispose();
    _orphanFamilyController.dispose();

    // شخصية
    _orphanIdNumberController.dispose();

    // أب
    _fatherIdNumberController.dispose();
    _fatherAgeController.dispose();

    // أم
    _motherNameController.dispose();
    _motherIdNumberController.dispose();
    _motherAgeController.dispose();

    // متوفي
    _deceasedNameController.dispose();
    _deceasedIdNumberController.dispose();

    // معيل
    _breadwinnerNameController.dispose();
    _breadwinnerIdNumberController.dispose();
    _breadwinnerAgeController.dispose();

    // عنوان وتواصل
    _neighborhoodController.dispose();
    _mobileNumberController.dispose();
    _alternativeMobileController.dispose();
    _whatsappNumberController.dispose();
    _landmarkController.dispose();

    // عائلة
    _numberOfMalesController.dispose();
    _numberOfFemalesController.dispose();
    _totalFamilyMembersController.dispose();

    // تعليم وصحة
    _schoolNameController.dispose();
    _diseaseDetailsController.dispose();

    // دخل
    _incomeSourcesController.dispose();

    // ملاحظات
    _notesController.dispose();

    super.dispose();
  }

  // ================== منطق نوع اليُتم ==================
  void _onOrphanTypeChanged(String? value) {
    setState(() {
      _selectedOrphanType = value;
      _applyOrphanTypeRules();
    });
  }

  void _applyOrphanTypeRules() {
    // إذا يتيم الأب: المتوفى = الأب | المعيل = الأم
    if (_selectedOrphanType == 'يتيم الأب') {
      _deceasedNameController.text = _buildFatherFullName();
      _deceasedIdNumberController.text = _fatherIdNumberController.text;
      _breadwinnerNameController.text = _motherNameController.text;
      _breadwinnerIdNumberController.text = _motherIdNumberController.text;
      _breadwinnerAgeController.text = _motherAgeController.text;
      _selectedBreadwinnerKinship = 'الأم';
      _selectedBreadwinnerMaritalStatus = 'أرمل/ة';
    }
    // إذا يتيم الأم: المتوفى = الأم | المعيل = الأب
    else if (_selectedOrphanType == 'يتيم الأم') {
      _deceasedNameController.text = _motherNameController.text;
      _deceasedIdNumberController.text = _motherIdNumberController.text;
      _breadwinnerNameController.text = _buildFatherFullName();
      _breadwinnerIdNumberController.text = _fatherIdNumberController.text;
      _breadwinnerAgeController.text = _fatherAgeController.text;
      _selectedBreadwinnerKinship = 'الأب';
      _selectedBreadwinnerMaritalStatus = 'أرمل/ة';
    }
    // إذا يتيم الوالدين: مسح الحقول التلقائية
    else if (_selectedOrphanType == 'يتيم الوالدين') {
      _deceasedNameController.clear();
      _deceasedIdNumberController.clear();
      _breadwinnerNameController.clear();
      _breadwinnerIdNumberController.clear();
      _breadwinnerAgeController.clear();
      _selectedBreadwinnerKinship = null;
      _selectedBreadwinnerMaritalStatus = null;
    }
  }

  String _buildFatherFullName() {
    final p = _orphanFatherController.text.trim();
    final g = _orphanGrandController.text.trim();
    final gg = _orphanGreatGrandController.text.trim();
    final f = _orphanFamilyController.text.trim();
    return [p, g, gg, f].where((e) => e.isNotEmpty).join(' ');
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return BlocListener<OrphansBloc, OrphansState>(
      listener: (context, state) {
        if (state is OrphanAdded) {
          setState(() => _isLoading = false);
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
                    Text(
                      'تمت إضافة اليتيم بنجاح.',
                      textAlign: TextAlign.center,
                    ),
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
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل في إضافة اليتيم: ${state.message}')),
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
                // ========== المعلومات الشخصية ==========
                _buildSectionTitle('المعلومات الشخصية'),
                _buildFiveNameSection(),
                _buildTextField(
                  controller: _orphanIdNumberController,
                  label: 'رقم هوية اليتيم',
                  isRequired: true,
                  keyboardType: TextInputType.number,
                ),
                _buildDateField(
                  label: 'تاريخ الميلاد',
                  date: _dateOfBirth,
                  onPressed: () => _selectDate(context, isDateOfBirth: true),
                  errorText: _birthDateErrorText,
                ),
                _buildDropdownField(
                  label: 'الجنس',
                  value: _selectedGender,
                  items: const ['ذكر', 'أنثى'],
                  onChanged: (value) => setState(() => _selectedGender = value),
                  isRequired: true,
                ),
                _buildDropdownField(
                  label: 'نوع اليُتم',
                  value: _selectedOrphanType,
                  items: const ['يتيم الأب', 'يتيم الأم', 'يتيم الوالدين'],
                  onChanged: _onOrphanTypeChanged,
                  isRequired: true,
                ),
                _buildFilePicker(
                  label: 'صورة اليتيم',
                  file: _orphanPhotoFile,
                  onPressed: () => _pickFile(
                    onFilePicked: (file) => setState(() {
                      _orphanPhotoFile = file;
                    }),
                  ),
                ),

                // ========== بيانات الأب ==========
                _buildSectionTitle('بيانات الأب'),
                _buildTextField(
                  controller: _orphanFatherController,
                  label: 'اسم الأب',
                  isRequired: true,
                ),
                _buildTextField(
                  controller: _orphanGrandController,
                  label: 'اسم الجد',
                  isRequired: true,
                ),
                _buildTextField(
                  controller: _orphanGreatGrandController,
                  label: 'اسم جدّ الأب',
                  isRequired: true,
                ),
                _buildTextField(
                  controller: _orphanFamilyController,
                  label: 'اسم العائلة',
                  isRequired: true,
                ),
                _buildTextField(
                  controller: _fatherIdNumberController,
                  label: 'رقم هوية الأب',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  controller: _fatherAgeController,
                  label: 'عمر الأب',
                  keyboardType: TextInputType.number,
                ),
                _buildFilePicker(
                  label: 'صورة هوية الأب',
                  file: _fatherIdPhotoFile,
                  onPressed: () => _pickFile(
                    onFilePicked: (file) => setState(() {
                      _fatherIdPhotoFile = file;
                    }),
                  ),
                ),

                // ========== بيانات الأم ==========
                _buildSectionTitle('بيانات الأم'),
                _buildTextField(
                  controller: _motherNameController,
                  label: 'اسم الأم الرباعي',
                ),
                _buildTextField(
                  controller: _motherIdNumberController,
                  label: 'رقم هوية الأم',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  controller: _motherAgeController,
                  label: 'عمر الأم',
                  keyboardType: TextInputType.number,
                ),
                _buildFilePicker(
                  label: 'صورة هوية الأم',
                  file: _motherIdPhotoFile,
                  onPressed: () => _pickFile(
                    onFilePicked: (file) => setState(() {
                      _motherIdPhotoFile = file;
                    }),
                  ),
                ),

                // ========== بيانات المتوفى ==========
                _buildSectionTitle('بيانات المتوفّى'),
                _buildTextField(
                  controller: _deceasedNameController,
                  label: 'اسم المتوفّى الرباعي',
                  readOnly: _selectedOrphanType != 'يتيم الوالدين',
                ),
                _buildTextField(
                  controller: _deceasedIdNumberController,
                  label: 'رقم هوية المتوفّى',
                  keyboardType: TextInputType.number,
                  readOnly: _selectedOrphanType != 'يتيم الوالدين',
                ),
                _buildDropdownField(
                  label: 'سبب الوفاة',
                  value: _selectedCauseOfDeath,
                  items: const ['استشهاد', 'مرض', 'حادث', 'أخرى'],
                  onChanged: (value) => setState(() {
                    _selectedCauseOfDeath = value;
                  }),
                ),
                _buildDateField(
                  label: 'تاريخ الوفاة',
                  date: _dateOfDeath,
                  onPressed: () => _selectDate(context, isDateOfBirth: false),
                  errorText: _deathDateErrorText,
                ),

                // إظهار حقلين لشهادة المتوفى فقط عندما يكون يتيم الوالدين
                if (_selectedOrphanType == 'يتيم الوالدين') ...[
                  _buildFilePicker(
                    label: 'صورة المتوفّى (الأب)',
                    file: _deceasedPhotoFile,
                    onPressed: () => _pickFile(
                      onFilePicked: (file) => setState(() {
                        _deceasedPhotoFile = file;
                      }),
                    ),
                  ),
                  _buildFilePicker(
                    label: 'شهادة الوفاة (الأب)',
                    file: _deathCertificateFile,
                    onPressed: () => _pickFile(
                      onFilePicked: (file) => setState(() {
                        _deathCertificateFile = file;
                      }),
                    ),
                  ),
                  _buildFilePicker(
                    label: 'صورة المتوفّى (الأم)',
                    file:
                        _deceasedPhotoFile, // يمكنك إضافة ملف منفصل للأم إذا أردت
                    onPressed: () => _pickFile(
                      onFilePicked: (file) => setState(() {
                        // يمكنك التعامل مع ملف الأم بشكل منفصل
                        _deceasedPhotoFile = file;
                      }),
                    ),
                  ),
                  _buildFilePicker(
                    label: 'شهادة الوفاة (الأم)',
                    file:
                        _deathCertificateFile, // يمكنك إضافة ملف منفصل للأم إذا أردت
                    onPressed: () => _pickFile(
                      onFilePicked: (file) => setState(() {
                        // يمكنك التعامل مع ملف الأم بشكل منفصل
                        _deathCertificateFile = file;
                      }),
                    ),
                  ),
                ] else ...[
                  _buildFilePicker(
                    label: 'صورة المتوفّى',
                    file: _deceasedPhotoFile,
                    onPressed: () => _pickFile(
                      onFilePicked: (file) => setState(() {
                        _deceasedPhotoFile = file;
                      }),
                    ),
                  ),
                  _buildFilePicker(
                    label: 'شهادة الوفاة',
                    file: _deathCertificateFile,
                    onPressed: () => _pickFile(
                      onFilePicked: (file) => setState(() {
                        _deathCertificateFile = file;
                      }),
                    ),
                  ),
                ],

                // ========== بيانات المعيل ==========
                _buildSectionTitle('بيانات المعيل'),
                _buildTextField(
                  controller: _breadwinnerNameController,
                  label: 'اسم المعيل الرباعي',
                  readOnly: _selectedOrphanType != 'يتيم الوالدين',
                ),
                _buildTextField(
                  controller: _breadwinnerIdNumberController,
                  label: 'رقم هوية المعيل',
                  keyboardType: TextInputType.number,
                  readOnly: _selectedOrphanType != 'يتيم الوالدين',
                ),
                _buildTextField(
                  controller: _breadwinnerAgeController,
                  label: 'عمر المعيل',
                  keyboardType: TextInputType.number,
                  readOnly: _selectedOrphanType != 'يتيم الوالدين',
                ),
                _buildDropdownField(
                  label: 'صلة القرابة',
                  value: _selectedBreadwinnerKinship,
                  items: const [
                    'الأم',
                    'الأب',
                    'أخ',
                    'أخت',
                    'عم',
                    'عمة',
                    'جد',
                    'جدة',
                    'أخرى',
                  ],
                  onChanged: (String? value) {
                    if (_selectedOrphanType == 'يتيم الوالدين') {
                      setState(() => _selectedBreadwinnerKinship = value);
                    }
                  },
                ),
                _buildDropdownField(
                  label: 'الحالة الاجتماعية',
                  value: _selectedBreadwinnerMaritalStatus,
                  items: const ['أرمل/ة', 'أعزب/ة', 'متزوج/ة', 'مطلق/ة'],
                  onChanged: (String? value) {
                    if (_selectedOrphanType == 'يتيم الوالدين') {
                      setState(() => _selectedBreadwinnerMaritalStatus = value);
                    }
                  },
                ),
                _buildFilePicker(
                  label: 'صورة هوية المعيل',
                  file: _breadwinnerIdPhotoFile,
                  onPressed: () => _pickFile(
                    onFilePicked: (file) => setState(() {
                      _breadwinnerIdPhotoFile = file;
                    }),
                  ),
                ),

                // ... باقي الكود بدون تغيير (بيانات العائلة، الاتصال، التعليم، السكن، إلخ)

                // ========== بيانات العائلة ==========
                _buildSectionTitle('بيانات العائلة'),
                _buildTextField(
                  controller: _numberOfMalesController,
                  label: 'عدد الذكور',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  controller: _numberOfFemalesController,
                  label: 'عدد الإناث',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  controller: _totalFamilyMembersController,
                  label: 'إجمالي أفراد العائلة',
                  keyboardType: TextInputType.number,
                  isRequired: true,
                ),

                // ========== الاتصال ==========
                _buildSectionTitle('التواصل'),
                _buildTextField(
                  controller: _mobileNumberController,
                  label: 'رقم الجوال',
                  keyboardType: TextInputType.phone,
                  isRequired: true,
                ),
                _buildTextField(
                  controller: _alternativeMobileController,
                  label: 'رقم جوال بديل',
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField(
                  controller: _whatsappNumberController,
                  label: 'رقم الواتساب',
                  keyboardType: TextInputType.phone,
                ),

                // ========== التعليم والصحة ==========
                _buildSectionTitle('التعليم والصحة'),
                _buildTextField(
                  controller: _schoolNameController,
                  label: 'اسم المدرسة',
                ),
                _buildGradeDropdown(),
                _buildHealthDropdown(),
                if (_selectedHealth != null && _selectedHealth != 'سليم')
                  _buildTextField(
                    controller: _diseaseDetailsController,
                    label: 'تفاصيل الأمراض',
                    maxLines: 2,
                  ),

                // ========== السكن والوضع المادي ==========
                _buildSectionTitle('السكن والوضع المادي'),
                _buildDropdownField(
                  label: 'المحافظة',
                  value: _selectedGovernorate,
                  items: _governoratesAndCities.keys.toList(),
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
                    onChanged: (value) => setState(() => _selectedCity = value),
                  ),
                _buildTextField(
                  controller: _neighborhoodController,
                  label: 'الحي',
                ),
                _buildTextField(
                  controller: _landmarkController,
                  label: 'أقرب معلم مشهور',
                ),
                _buildDropdownField(
                  label: 'حالة السكن',
                  value: _selectedHousingCondition,
                  items: const ['ممتاز', 'جيد', 'سيء'],
                  onChanged: (value) =>
                      setState(() => _selectedHousingCondition = value),
                ),
                _buildDropdownField(
                  label: 'ملكية السكن',
                  value: _selectedHousingOwnership,
                  items: const ['ملك', 'إيجار', 'حكومي', 'منزل عائلة'],
                  onChanged: (value) =>
                      setState(() => _selectedHousingOwnership = value),
                ),
                _buildDropdownField(
                  label: 'الدخل الشهري',
                  value: _selectedMonthlyIncome,
                  items: const ['أقل من 300', '300 - 600', 'أكثر من 600'],
                  onChanged: (value) =>
                      setState(() => _selectedMonthlyIncome = value),
                ),
                _buildTextField(
                  controller: _incomeSourcesController,
                  label: 'مصادر الدخل',
                  maxLines: 2,
                ),

                // ========== مستندات إضافية ==========
                _buildSectionTitle('المستندات الإضافية'),
                _buildFilePicker(
                  label: 'شهادة ميلاد اليتيم',
                  file: _birthCertificateFile,
                  onPressed: () => _pickFile(
                    onFilePicked: (file) => setState(() {
                      _birthCertificateFile = file;
                    }),
                  ),
                ),

                // ========== ملاحظات ==========
                _buildSectionTitle('ملاحظات'),
                _buildTextField(
                  controller: _notesController,
                  label: 'ملاحظات أخرى',
                  maxLines: 3,
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

  // ... باقي الدوال المساعدة بدون تغيير (_buildFiveNameSection, _buildGradeDropdown, إلخ)

  // ================== أدوات بناء واجهة ==================
  Widget _buildFiveNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _orphanFirstController,
          label: 'اسم اليتيم',
          isRequired: true,
        ),
        _buildTextField(
          controller: _orphanFatherController,
          label: 'اسم الأب',
          isRequired: true,
        ),
        _buildTextField(
          controller: _orphanGrandController,
          label: 'اسم الجد',
          isRequired: true,
        ),
        _buildTextField(
          controller: _orphanGreatGrandController,
          label: 'اسم جدّ الأب',
          isRequired: true,
        ),
        _buildTextField(
          controller: _orphanFamilyController,
          label: 'اسم العائلة',
          isRequired: true,
        ),
      ],
    );
  }

  Widget _buildGradeDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'الصف الدراسي'),
      value: _selectedGrade,
      items: _grades
          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
          .toList(),
      onChanged: (v) => setState(() => _selectedGrade = v),
    );
  }

  Widget _buildHealthDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'الحالة الصحية'),
      value: _selectedHealth,
      items: _healthOptions
          .map((h) => DropdownMenuItem(value: h, child: Text(h)))
          .toList(),
      onChanged: (v) => setState(() {
        _selectedHealth = v;
        if (v == 'سليم') {
          _diseaseDetailsController.clear();
        }
      }),
    );
  }

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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        maxLines: maxLines,
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
        items: items
            .map(
              (item) =>
                  DropdownMenuItem<String>(value: item, child: Text(item)),
            )
            .toList(),
        onChanged: onChanged,
        validator: (v) {
          if (isRequired && v == null) {
            return 'الرجاء اختيار $label';
          }
          return null;
        },
      ),
    );
  }

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
            errorText: errorText,
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
                  child: const Text(
                    'اختر ملف',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Text(
                  file != null
                      ? file.path.split('/').last
                      : 'لم يتم اختيار ملف',
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

  // ================== منطق الحفظ ==================
  Future<void> _selectDate(
    BuildContext context, {
    required bool isDateOfBirth,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDateOfBirth ? _dateOfBirth ?? now : _dateOfDeath ?? now,
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        if (isDateOfBirth) {
          _dateOfBirth = picked;
          _birthDateErrorText = null;
        } else {
          _dateOfDeath = picked;
          _deathDateErrorText = null;
        }
      });
    }
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    if (_dateOfBirth == null) {
      setState(() => _birthDateErrorText = 'الرجاء إدخال تاريخ الميلاد');
      return;
    }
    int _generateCustomId() {
      final random = Random();
      const min = 10000;
      const max = 99999;
      return (min + random.nextInt(max - min));
    }

    setState(() => _isLoading = true);

    // تطبيق قواعد نوع اليتم قبل الإنشاء (للتأكد)
    _applyOrphanTypeRules();

    final orphan = Orphan(
      institutionId: widget.institutionId,
      kafalaHeadId: widget.kafalaHeadId,
      orphanNo: _generateCustomId(),
      orphanName: _orphanFirstController.text.trim(),
      fatherName: _orphanFatherController.text.trim(),
      grandfatherName: _orphanGrandController.text.trim(),
      greatGrandfatherName: _orphanGreatGrandController.text.trim(),
      familyName: _orphanFamilyController.text.trim(),

      // معلومات شخصية
      orphanIdNumber: int.tryParse(_orphanIdNumberController.text) ?? 0,
      dateOfBirth: _dateOfBirth!,
      gender: _selectedGender ?? 'ذكر',
      orphanType: _selectedOrphanType ?? 'يتيم الأب',
      healthStatus: _selectedHealth == null || _selectedHealth == 'سليم'
          ? null
          : _selectedHealth,

      // الأب
      fatherFullName: _buildFatherFullName(),
      fatherIdNumber: int.tryParse(_fatherIdNumberController.text),

      // الأم
      motherFullName: _motherNameController.text.trim().isEmpty
          ? null
          : _motherNameController.text.trim(),
      motherIdNumber: int.tryParse(_motherIdNumberController.text),

      // المتوفى
      deceasedFullName: _deceasedNameController.text.trim().isEmpty
          ? null
          : _deceasedNameController.text.trim(),
      deceasedIdNumber: int.tryParse(_deceasedIdNumberController.text),
      causeOfDeath: _selectedCauseOfDeath,
      dateOfDeath: _dateOfDeath,

      // المعيل
      breadwinnerFullName: _breadwinnerNameController.text.trim().isEmpty
          ? null
          : _breadwinnerNameController.text.trim(),
      breadwinnerIdNumber: int.tryParse(_breadwinnerIdNumberController.text),
      breadwinnerKinship: _selectedBreadwinnerKinship,
      breadwinnerMaritalStatus: _selectedBreadwinnerMaritalStatus,
      breadwinnerAge: int.tryParse(_breadwinnerAgeController.text),

      // العائلة
      numberOfMales: int.tryParse(_numberOfMalesController.text) ?? 0,
      numberOfFemales: int.tryParse(_numberOfFemalesController.text) ?? 0,
      totalFamilyMembers: int.tryParse(_totalFamilyMembersController.text) ?? 0,

      mobileNumber: int.tryParse(_mobileNumberController.text) ?? 0,
      alternativeMobileNumber:
          int.tryParse(_alternativeMobileController.text) ?? 0,
      whatsappNumber: int.tryParse(_whatsappNumberController.text) ?? 0,

      // التعليم والصحة
      schoolName: _selectedGrade == null || _selectedGrade == 'لا يدرس'
          ? null
          : _selectedGrade,
      educationStatus: _selectedEducationStatus,
      healthCondition: _diseaseDetailsController.text.trim().isEmpty
          ? null
          : _diseaseDetailsController.text.trim(),

      // السكن والدخل
      governorate: _selectedGovernorate,
      city: _selectedCity,
      neighborhood: _neighborhoodController.text.trim().isEmpty
          ? null
          : _neighborhoodController.text.trim(),
      landmark: _landmarkController.text.trim().isEmpty
          ? null
          : _landmarkController.text.trim(),
      housingCondition: _selectedHousingCondition,
      housingOwnership: _selectedHousingOwnership,
      monthlyIncome: _selectedMonthlyIncome,
      incomeSources: _incomeSourcesController.text.trim().isEmpty
          ? null
          : _incomeSourcesController.text.trim(),

      // مستندات إضافية (روابط تُملأ بعد الرفع إن وجد)
      birthCertificateUrl: null,
      otherDocumentsUrl: null,

      // الكفالة
      sponsorshipStatus: null,
      sponsorshipAmount: null,
      sponsorshipType: null,
      sponsorshipDate: null,

      // ملاحظات
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),

      // نظام
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    context.read<OrphansBloc>().add(
      AddOrphan(
        orphan: orphan,
        orphanPhotoFile: _orphanPhotoFile,
        fatherIdPhotoFile: _fatherIdPhotoFile,
        motherIdPhotoFile: _motherIdPhotoFile,
        deceasedPhotoFile: _deceasedPhotoFile,
        deathCertificateFile: _deathCertificateFile,
        birthCertificateFile: _birthCertificateFile,
        breadwinnerIdPhotoFile: _breadwinnerIdPhotoFile,
      ),
    );
  }

  // ================== رفع الملفات ==================
  Future<void> _pickFile({
    required Function(File?) onFilePicked,
    List<String> allowedExtensions = const ['jpg', 'png', 'pdf', 'jpeg'],
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (result != null && result.files.single.path != null) {
      onFilePicked(File(result.files.single.path!));
    }
  }
}
