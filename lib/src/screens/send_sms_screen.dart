import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/themes/app_colors.dart';
import 'package:e_kafel/src/widgets/app_drawer.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'login_screen.dart';

class SendSMSScreen extends StatefulWidget {
  const SendSMSScreen({super.key});

  @override
  State<SendSMSScreen> createState() => _SendSMSScreenState();
}

class _SendSMSScreenState extends State<SendSMSScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();

  String _selectedRecipientType = 'جميع الأيتام';
  String _selectedTemplate = 'رسالة مخصصة';
  bool _isScheduled = false;
  DateTime _scheduledDate = DateTime.now();
  TimeOfDay _scheduledTime = TimeOfDay.now();

  final List<String> _recipientTypes = [
    'جميع الأيتام',
    'أيتام محددون',
    'المشرفين',
    'رؤساء الكفالة',
    'أيتام يحتاجون تحديث بيانات',
    'أيتام في انتظار الكفالة',
  ];

  final List<String> _messageTemplates = [
    'رسالة مخصصة',
    'تذكير بتحديث البيانات',
    'تذكير بموعد الكفالة',
    'رسالة ترحيب',
    'رسالة شكر',
    'تذكير بموعد زيارة',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إرسال رسائل SMS'),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showSMSSentHistory,
          ),
        ],
      ),
      drawer: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoaded) {
            return AppDrawer(
              userName: state.userName,
              userRole: state.userRole,
              profileImageUrl: state.profileImageUrl,
              orphanCount: state.orphanSponsored,
              taskCount:
                  state.completedTasksPercentage, // عدلها حسب المتغير المناسب
              visitCount:
                  state.completedFieldVisits, // عدلها حسب المتغير المناسب
              onLogout: () {
                context.read<AuthBloc>().add(LogoutButtonPressed());
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            );
          }
          return AppDrawer(
            userName: '',
            userRole: '',
            orphanCount: 0,
            taskCount: 0,
            visitCount: 0,
            onLogout: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          );
        },
      ),

      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HomeLoaded) {
            return _buildSMSContent(context, state);
          }

          return const Center(child: Text('لا توجد بيانات متاحة'));
        },
      ),
    );
  }

  Widget _buildSMSContent(BuildContext context, HomeState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // إحصائيات SMS
          _buildSMSStats(state),
          const SizedBox(height: 24),

          // نموذج إرسال SMS
          _buildSMSForm(),
          const SizedBox(height: 24),

          // قائمة المستلمين المقترحين
          _buildRecipientsList(),
        ],
      ),
    );
  }

  Widget _buildSMSStats(HomeState state) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إحصائيات الرسائل',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'إجمالي الرسائل',
                    '150',
                    Icons.message,
                    AppColors.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'تم الإرسال',
                    '142',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'فشل الإرسال',
                    '8',
                    Icons.error,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSMSForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إرسال رسالة جديدة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              // نوع المستلم
              DropdownButtonFormField<String>(
                value: _selectedRecipientType,
                decoration: const InputDecoration(
                  labelText: 'نوع المستلم',
                  border: OutlineInputBorder(),
                ),
                items: _recipientTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRecipientType = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // قالب الرسالة
              DropdownButtonFormField<String>(
                value: _selectedTemplate,
                decoration: const InputDecoration(
                  labelText: 'قالب الرسالة',
                  border: OutlineInputBorder(),
                ),
                items: _messageTemplates.map((String template) {
                  return DropdownMenuItem<String>(
                    value: template,
                    child: Text(template),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTemplate = newValue!;
                    if (newValue != 'رسالة مخصصة') {
                      _messageController.text = _getTemplateMessage(newValue);
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // نص الرسالة
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                maxLength: 160,
                decoration: const InputDecoration(
                  labelText: 'نص الرسالة',
                  border: OutlineInputBorder(),
                  hintText: 'اكتب رسالتك هنا...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى كتابة رسالة';
                  }
                  if (value.length > 160) {
                    return 'الرسالة طويلة جداً (الحد الأقصى 160 حرف)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // جدولة الرسالة
              Row(
                children: [
                  Checkbox(
                    value: _isScheduled,
                    onChanged: (bool? value) {
                      setState(() {
                        _isScheduled = value!;
                      });
                    },
                  ),
                  const Text('جدولة الرسالة'),
                ],
              ),
              if (_isScheduled) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          'التاريخ: ${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectTime,
                        icon: const Icon(Icons.access_time),
                        label: Text('الوقت: ${_scheduledTime.format(context)}'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // أزرار الإرسال
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _sendSMS,
                      icon: const Icon(Icons.send),
                      label: const Text('إرسال فوري'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _previewSMS,
                      icon: const Icon(Icons.preview),
                      label: const Text('معاينة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientsList() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المستلمون المقترحون',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // حقل البحث
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'البحث في المستلمين',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                // تطبيق البحث
              },
            ),
            const SizedBox(height: 16),

            // قائمة المستلمين
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5, // عدد المستلمين المقترحين
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryColor,
                    child: Text('${index + 1}'),
                  ),
                  title: Text('مستلم ${index + 1}'),
                  subtitle: Text('رقم الهاتف: 05${index + 1}2345678'),
                  trailing: Checkbox(
                    value: true, // يمكن تغييرها حسب الحاجة
                    onChanged: (bool? value) {
                      // تحديث حالة الاختيار
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getTemplateMessage(String template) {
    switch (template) {
      case 'تذكير بتحديث البيانات':
        return 'مرحباً، يرجى تحديث بيانات اليتيم في أقرب وقت ممكن. شكراً لكم.';
      case 'تذكير بموعد الكفالة':
        return 'مرحباً، يرجى تذكر موعد الكفالة الشهرية. شكراً لكم.';
      case 'رسالة ترحيب':
        return 'مرحباً بكم في نظام الكفالة الإلكتروني. نتمنى لكم تجربة ممتعة.';
      case 'تذكير بموعد زيارة':
        return 'مرحباً، يرجى تذكر موعد الزيارة الميدانية غداً. شكراً لكم.';
      default:
        return '';
    }
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _scheduledDate) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  void _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (picked != null && picked != _scheduledTime) {
      setState(() {
        _scheduledTime = picked;
      });
    }
  }

  void _sendSMS() {
    if (_formKey.currentState!.validate()) {
      // إرسال الرسالة
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال الرسالة بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );

      // إعادة تعيين النموذج
      _messageController.clear();
      setState(() {
        _isScheduled = false;
      });
    }
  }

  void _previewSMS() {
    if (_messageController.text.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('معاينة الرسالة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('المستلمون: $_selectedRecipientType'),
              const SizedBox(height: 8),
              Text('الرسالة:'),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_messageController.text),
              ),
              if (_isScheduled) ...[
                const SizedBox(height: 8),
                Text(
                  'موعد الإرسال: ${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year} في ${_scheduledTime.format(context)}',
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    }
  }

  void _showSMSSentHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سجل الرسائل المرسلة'),
        content: const SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              Text('هنا سيتم عرض سجل الرسائل المرسلة'),
              SizedBox(height: 16),
              Text('يمكن إضافة تفاصيل مثل:'),
              Text('• تاريخ الإرسال'),
              Text('• حالة الإرسال'),
              Text('• عدد المستلمين'),
              Text('• نوع الرسالة'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
