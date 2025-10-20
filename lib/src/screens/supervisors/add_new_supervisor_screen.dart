import 'dart:math';

import 'package:e_kafel/src/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/dropdown_utils.dart';
import '../../blocs/supervisors/supervisors_bloc.dart';

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
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  String? _area;
  String? _functional;
  String _institutionName = 'جاري التحميل...';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _form = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadInstitutionName();
  }

  Future<void> _loadInstitutionName() async {
    try {
      final name = await _firestoreService.getInstitutionName(widget.institutionId);
      if (mounted) {
        setState(() {
          _institutionName = name;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _institutionName = 'غير محدد';
        });
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;

    // التحقق من أن جميع المتحكمات مهيأة
    if (!_isControllersInitialized()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ في تهيئة البيانات')),
      );
      return;
    }

    // التحقق من أن اسم المؤسسة تم تحميله
    if (_institutionName == 'جاري التحميل...') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري تحميل بيانات المؤسسة...')),
      );
      return;
    }

    // التحقق من كلمة المرور
    if (_password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل')),
      );
      return;
    }

    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمات المرور غير متطابقة')),
      );
      return;
    }

    _createSupervisorWithAuth();
  }

  void _createSupervisorWithAuth() {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final customId = _generateCustomId();

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
          'areaResponsibleFor': _area ?? '',
          'functionalLodgment': _functional ?? '',
          'address': _address.text.trim(),
          'userRole': 'supervisor',
          'isActive': true,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
          'profileImageUrl': '',
        },
        password: _password.text,
      ),
    );
    
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.pop(context, true);
      }
    });
  }

  String _generateCustomId() {
    final random = Random();
    const min = 100000;
    const max = 999999;
    return (min + random.nextInt(max - min)).toString();
  }

  bool _isControllersInitialized() {
    return _name.text.isNotEmpty &&
           _email.text.isNotEmpty &&
           _phone.text.isNotEmpty &&
           _address.text.isNotEmpty &&
           _password.text.isNotEmpty &&
           _confirmPassword.text.isNotEmpty;
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
          setState(() {
            _isLoading = false;
          });
        } else if (state is SupervisorsLoaded) {
          // تمت الإضافة بنجاح
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة المشرف بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('إضافة مشرف')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _form,
                  child: ListView(
                    children: [
                      // عرض اسم المؤسسة
                      Card(
                        color: Colors.grey[50],
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.business, color: Colors.teal, size: 20),
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
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'أدخل البريد الإلكتروني';
                          if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v))
                            return 'صيغة البريد الإلكتروني غير صحيحة';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        decoration: const InputDecoration(
                          labelText: 'رقم الجوال',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'أدخل رقم الجوال';
                          if (v.length < 7) return 'رقم الجوال غير صالح';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _address,
                        decoration: const InputDecoration(
                          labelText: 'العنوان',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        keyboardType: TextInputType.streetAddress,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'أدخل العنوان' : null,
                      ),
                      const SizedBox(height: 12),

                      // حقل كلمة المرور
                      TextFormField(
                        controller: _password,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'أدخل كلمة المرور';
                          }
                          if (v.length < 6) {
                            return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // حقل تأكيد كلمة المرور
                      TextFormField(
                        controller: _confirmPassword,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'تأكيد كلمة المرور',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'أدخل تأكيد كلمة المرور';
                          }
                          if (v != _password.text) {
                            return 'كلمات المرور غير متطابقة';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      LabeledDropdown(
                        label: 'المنطقة المسؤولة',
                        items: kAreasOptions,
                        value: _area,
                        onChanged: (v) => setState(() => _area = v),
                        validator: (v) => v == null ? 'اختر المنطقة المسؤولة' : null,
                      ),
                      const SizedBox(height: 12),

                      LabeledDropdown(
                        label: 'المهام الوظيفية',
                        items: kFunctionalLodgmentOptions,
                        value: _functional,
                        onChanged: (v) => setState(() => _functional = v),
                        validator: (v) => v == null ? 'اختر المهام الوظيفية' : null,
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: _isLoading ? Colors.grey : Colors.teal,
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('جاري الإضافة...'),
                                ],
                              )
                            : const Text('حفظ المشرف'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}