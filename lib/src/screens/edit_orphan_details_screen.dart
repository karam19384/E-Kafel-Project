import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../blocs/orphans/orphans_bloc.dart';
import '../themes/app_colors.dart';

class EditOrphanDetailsScreen extends StatefulWidget {
  final String orphanId;
  final String institutionId;

  const EditOrphanDetailsScreen({
    super.key,
    required this.orphanId,
    required this.institutionId, required Map<String, dynamic> orphanData,
  });

  @override
  State<EditOrphanDetailsScreen> createState() =>
      _EditOrphanDetailsScreenState();
}

class _EditOrphanDetailsScreenState extends State<EditOrphanDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _orphanIdNumberController =
      TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _motherIdNumberController =
      TextEditingController();
  final TextEditingController _guardianNameController = TextEditingController();
  final TextEditingController _guardianIdNoController = TextEditingController();
  final TextEditingController _guardianPhoneController =
      TextEditingController();
  final TextEditingController _guardianAddressController =
      TextEditingController();
  final TextEditingController _guardianRelationController =
      TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _schoolLevelController = TextEditingController();
  final TextEditingController _healthStatusController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _sponsorshipAmountController =
      TextEditingController();
  final TextEditingController _sponsorshipStartsController =
      TextEditingController();
  final TextEditingController _sponsorshipEndsController =
      TextEditingController();
  final TextEditingController _idCardUrlController = TextEditingController();
  final TextEditingController _deathCertificateUrlController =
      TextEditingController();
  final TextEditingController _orphanPhotoUrlController =
      TextEditingController();

  // Variables
  String _gender = 'ذكر';
  String _sponsorshipStatus = 'مكفول';
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? orphanData;

  @override
  void initState() {
    super.initState();
    _fetchOrphanDetails();
  }

  Future<void> _fetchOrphanDetails() async {
    try {
      final docSnapshot =
          await _firestore.collection('orphans').doc(widget.orphanId).get();

      if (docSnapshot.exists) {
        orphanData = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _birthdateController.text =
              _formatDate(orphanData?['dateOfBirth']) ;
          _nameController.text = orphanData?['name'] ?? '';
          _orphanIdNumberController.text =
              orphanData?['orphanIdNumber']?.toString() ?? '';
          _motherNameController.text = orphanData?['motherName'] ?? '';
          _motherIdNumberController.text =
              orphanData?['motherIdNumber']?.toString() ?? '';
          _gender = orphanData?['gender'] ?? 'ذكر';
          _sponsorshipStatus =
              orphanData?['sponsorship_status'] ?? 'مكفول';
          _sponsorshipAmountController.text =
              orphanData?['sponsorshipAmount']?.toString() ?? '';
          _schoolNameController.text = orphanData?['schoolName'] ?? '';
          _schoolLevelController.text = orphanData?['educationLevel'] ?? '';
          _healthStatusController.text = orphanData?['healthStatus'] ?? '';
          _notesController.text = orphanData?['notes'] ?? '';
          _idCardUrlController.text = orphanData?['idCardUrl'] ?? '';
          _deathCertificateUrlController.text =
              orphanData?['deathCertificateUrl'] ?? '';
          _orphanPhotoUrlController.text = orphanData?['orphanPhotoUrl'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'بيانات اليتيم غير موجودة.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في تحميل البيانات: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      return DateFormat('yyyy-MM-dd').format(date.toDate());
    } else if (date is DateTime) {
      return DateFormat('yyyy-MM-dd').format(date);
    }
    return date.toString();
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (pickedDate != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
    }
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        'name': _nameController.text.trim(),
        'orphanIdNumber': _orphanIdNumberController.text.trim(),
        'motherName': _motherNameController.text.trim(),
        'motherIdNumber': _motherIdNumberController.text.trim(),
        'gender': _gender,
        'sponsorship_status': _sponsorshipStatus,
        'sponsorshipAmount': _sponsorshipAmountController.text.trim(),
        'schoolName': _schoolNameController.text.trim(),
        'educationLevel': _schoolLevelController.text.trim(),
        'healthStatus': _healthStatusController.text.trim(),
        'notes': _notesController.text.trim(),
        'idCardUrl': _idCardUrlController.text.trim(),
        'deathCertificateUrl': _deathCertificateUrlController.text.trim(),
        'orphanPhotoUrl': _orphanPhotoUrlController.text.trim(),
      };

      context.read<OrphansBloc>().add(
            UpdateOrphan(widget.orphanId, updatedData, widget.institutionId),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrphansBloc, OrphansState>(
      listener: (context, state) {
        if (state is OrphansLoaded) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث بيانات اليتيم بنجاح')),
          );
        } else if (state is OrphansError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل التحديث: ${state.message}')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تعديل بيانات اليتيم'),
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(_nameController, 'اسم اليتيم'),
                          const SizedBox(height: 15),
                          _buildDateField(
                              _birthdateController, 'تاريخ الميلاد'),
                          const SizedBox(height: 15),
                          _buildDropdownField(
                            'الجنس',
                            _gender,
                            ['ذكر', 'أنثى'],
                            (val) => setState(() => _gender = val!),
                          ),
                          const SizedBox(height: 15),
                          _buildDropdownField(
                            'حالة الكفالة',
                            _sponsorshipStatus,
                            ['مكفول', 'غير مكفول'],
                            (val) => setState(() => _sponsorshipStatus = val!),
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            _sponsorshipAmountController,
                            'مبلغ الكفالة',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 15),
                          _buildDateField(_sponsorshipStartsController,
                              'تاريخ بدء الكفالة'),
                          const SizedBox(height: 15),
                          _buildDateField(_sponsorshipEndsController,
                              'تاريخ انتهاء الكفالة'),
                          const SizedBox(height: 15),
                          _buildTextField(
                              _guardianNameController, 'اسم ولي الأمر'),
                          const SizedBox(height: 15),
                          _buildTextField(
                            _guardianIdNoController,
                            'رقم هوية ولي الأمر',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            _guardianPhoneController,
                            'رقم جوال ولي الأمر',
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                              _guardianAddressController, 'عنوان السكن'),
                          const SizedBox(height: 15),
                          _buildTextField(
                              _guardianRelationController, 'صلة القرابة'),
                          const SizedBox(height: 15),
                          _buildTextField(_schoolNameController, 'اسم المدرسة'),
                          const SizedBox(height: 15),
                          _buildTextField(
                              _schoolLevelController, 'المستوى التعليمي'),
                          const SizedBox(height: 15),
                          _buildTextField(
                              _healthStatusController, 'الحالة الصحية'),
                          const SizedBox(height: 15),
                          _buildTextField(
                              _notesController, 'ملاحظات إضافية',
                              maxLines: 3),
                          const SizedBox(height: 30),
                          if (_idCardUrlController.text.isNotEmpty)
                            Image.network(
                              _idCardUrlController.text,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          _buildTextField(
                              _idCardUrlController, 'رابط صورة الهوية'),
                          const SizedBox(height: 15),
                          if (_deathCertificateUrlController.text.isNotEmpty)
                            Image.network(
                              _deathCertificateUrlController.text,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          _buildTextField(_deathCertificateUrlController,
                              'رابط شهادة الوفاة'),
                          const SizedBox(height: 15),
                          if (_orphanPhotoUrlController.text.isNotEmpty)
                            Image.network(
                              _orphanPhotoUrlController.text,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          _buildTextField(
                              _orphanPhotoUrlController, 'رابط صورة اليتيم'),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'حفظ التغييرات',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.secondaryColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildDateField(
      TextEditingController controller, String labelText) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: labelText,
        suffixIcon:
            const Icon(Icons.calendar_today, color: AppColors.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onTap: () => _selectDate(context, controller),
    );
  }

  Widget _buildDropdownField(
    String label,
    String currentValue,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: items
          .map((value) =>
              DropdownMenuItem<String>(value: value, child: Text(value)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
