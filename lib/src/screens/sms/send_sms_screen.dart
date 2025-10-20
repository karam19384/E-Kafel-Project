import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/utils/app_colors.dart';
import 'package:e_kafel/src/widgets/app_drawer.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'package:e_kafel/src/services/sms_service.dart';
import '../../blocs/send_sms/send_sms_bloc.dart';
import '../../models/massege_model.dart';
import '../Auth/login_screen.dart';

class SendSMSScreen extends StatefulWidget {
  static const routeName = '/send_sms_screen';

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

  List<Map<String, dynamic>> _selectedRecipients = [];
  List<Map<String, dynamic>> _allRecipients = [];
  late String _currentUserId;
  late String _currentUserName;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  void _initializeUserData() {
    final state = context.read<HomeBloc>().state;
    if (state is HomeLoaded) {
      _currentUserId = state.kafalaHeadId;
      _currentUserName = state.userName;
    }
  }

  void _loadRecipients() {
    context.read<SMSBloc>().add(LoadRecipientsEvent(_selectedRecipientType));
  }

  void _loadSMSStats() {
    context.read<SMSBloc>().add(LoadSMSStatsEvent());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SMSBloc(SMSService()),
      child: Scaffold(
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
        drawer: _buildDrawer(),
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
      ),
    );
  }

  Widget _buildSMSContent(BuildContext context, HomeState state) {
    return BlocListener<SMSBloc, SMSState>(
      listener: (context, smsState) {
        if (smsState is RecipientsLoaded) {
          setState(() {
            _allRecipients = smsState.recipients;
            // تحديد جميع المستلمين افتراضياً
            _selectedRecipients = List.from(_allRecipients);
          });
        } else if (smsState is SMSSentSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال الرسالة بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
          _resetForm();
        } else if (smsState is SMSError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(smsState.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // إحصائيات SMS
            _buildSMSStats(),
            const SizedBox(height: 24),

            // نموذج إرسال SMS
            _buildSMSForm(),
            const SizedBox(height: 24),

            // قائمة المستلمين المقترحين
            _buildRecipientsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSMSStats() {
    return BlocBuilder<SMSBloc, SMSState>(
      builder: (context, state) {
        int totalMessages = 0;
        int sentMessages = 0;
        int failedMessages = 0;

        if (state is SMSStatsLoaded) {
          totalMessages = state.stats['totalMessages'] ?? 0;
          sentMessages = state.stats['sentMessages'] ?? 0;
          failedMessages = state.stats['failedMessages'] ?? 0;
        }

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'إحصائيات الرسائل',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadSMSStats,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'إجمالي الرسائل',
                        totalMessages.toString(),
                        Icons.message,
                        AppColors.primaryColor,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'تم الإرسال',
                        sentMessages.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'فشل الإرسال',
                        failedMessages.toString(),
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
      },
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
                    _loadRecipients();
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المستلمون المقترحون (${_selectedRecipients.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                if (_allRecipients.isNotEmpty)
                  TextButton(
                    onPressed: _toggleSelectAll,
                    child: Text(
                      _selectedRecipients.length == _allRecipients.length
                          ? 'إلغاء الكل'
                          : 'تحديد الكل',
                    ),
                  ),
              ],
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
                _filterRecipients(value);
              },
            ),
            const SizedBox(height: 16),

            // قائمة المستلمين
            BlocBuilder<SMSBloc, SMSState>(
              builder: (context, state) {
                if (state is SMSLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_allRecipients.isEmpty) {
                  return const Center(
                    child: Text('لا توجد بيانات للمستلمين'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _allRecipients.length,
                  itemBuilder: (context, index) {
                    final recipient = _allRecipients[index];
                    final isSelected = _selectedRecipients.any((r) => r['id'] == recipient['id']);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryColor,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(recipient['name'] ?? 'غير معروف'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('رقم الهاتف: ${recipient['phoneNumber'] ?? 'غير متوفر'}'),
                          if (recipient['governorate'] != null)
                            Text('المحافظة: ${recipient['governorate']}'),
                          if (recipient['sponsorshipStatus'] != null)
                            Text('حالة الكفالة: ${recipient['sponsorshipStatus']}'),
                        ],
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) {
                          _toggleRecipientSelection(recipient, value ?? false);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedRecipients.length == _allRecipients.length) {
        _selectedRecipients.clear();
      } else {
        _selectedRecipients = List.from(_allRecipients);
      }
    });
  }

  void _toggleRecipientSelection(Map<String, dynamic> recipient, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedRecipients.add(recipient);
      } else {
        _selectedRecipients.removeWhere((r) => r['id'] == recipient['id']);
      }
    });
  }

  void _filterRecipients(String query) {
    if (query.isEmpty) {
      _loadRecipients();
    } else {
      context.read<SMSBloc>().add(SearchRecipientsEvent(query, _selectedRecipientType));
    }
  }

  String _getTemplateMessage(String template) {
    switch (template) {
      case 'تذكير بتحديث البيانات':
        return 'مرحباً، يرجى تحديث بيانات اليتيم في أقرب وقت ممكن. شكراً لكم.';
      case 'تذكير بموعد الكفالة':
        return 'مرحباً، يرجى تذكر موعد الكفالة الشهرية. شكراً لكم.';
      case 'رسالة ترحيب':
        return 'مرحباً بكم في نظام الكفالة الإلكتروني. نتمنى لكم تجربة ممتعة.';
      case 'رسالة شكر':
        return 'نشكركم على دعمكم المستوتر ودوركم الفعال في رعاية الأيتام.';
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
    if (_formKey.currentState!.validate() && _selectedRecipients.isNotEmpty) {
      final scheduledDateTime = _isScheduled
          ? DateTime(
              _scheduledDate.year,
              _scheduledDate.month,
              _scheduledDate.day,
              _scheduledTime.hour,
              _scheduledTime.minute,
            )
          : DateTime.now();

      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        recipientType: _selectedRecipientType,
        recipientIds: _selectedRecipients.map((r) => r['id'] as String).toList(),
        recipientPhones: _selectedRecipients
            .map((r) => r['phoneNumber'] as String? ?? '')
            .where((phone) => phone.isNotEmpty)
            .toList(),
        messageText: _messageController.text,
        scheduledTime: scheduledDateTime,
        isSent: !_isScheduled, // إذا لم تكن مجدولة، تعتبر مرسلة فوراً
        sentAt: _isScheduled ? null : DateTime.now(),
        createdAt: DateTime.now(),
        senderId: _currentUserId,
        senderName: _currentUserName,
      );

      context.read<SMSBloc>().add(SendSMSEvent(message));
    } else if (_selectedRecipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار مستلم واحد على الأقل'),
          backgroundColor: Colors.red,
        ),
      );
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
              Text('عدد المستلمين: ${_selectedRecipients.length}'),
              const SizedBox(height: 8),
              const Text('الرسالة:'),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_messageController.text),
              ),
              const SizedBox(height: 8),
              Text('عدد الأحرف: ${_messageController.text.length}'),
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
    context.read<SMSBloc>().add(LoadMessagesHistoryEvent());
    
    showDialog(
      context: context,
      builder: (context) => BlocBuilder<SMSBloc, SMSState>(
        builder: (context, state) {
          List<Message> messages = [];
          if (state is MessagesHistoryLoaded) {
            messages = state.messages;
          }

          return AlertDialog(
            title: const Text('سجل الرسائل المرسلة'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: state is SMSLoading
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                      ? const Center(child: Text('لا توجد رسائل مرسلة'))
                      : ListView.builder(
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(
                                  message.messageText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('المستلمون: ${message.recipientType}'),
                                    Text('المرسل: ${message.senderName}'),
                                    Text('الوقت: ${_formatDate(message.scheduledTime)}'),
                                    Text('الحالة: ${message.isSent ? 'تم الإرسال' : 'مجدولة'}'),
                                    Text('عدد المستلمين: ${message.recipientPhones.length}'),
                                  ],
                                ),
                                trailing: Icon(
                                  message.isSent ? Icons.check_circle : Icons.schedule,
                                  color: message.isSent ? Colors.green : Colors.orange,
                                ),
                              ),
                            );
                          },
                        ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _resetForm() {
    _messageController.clear();
    setState(() {
      _isScheduled = false;
      _selectedTemplate = 'رسالة مخصصة';
    });
  }

  Widget _buildDrawer() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoaded) {
          return AppDrawer(
            institutionId: state.institutionId,
            kafalaHeadId: state.kafalaHeadId,
            userName: state.userName,
            userRole: state.userRole,
            profileImageUrl: state.profileImageUrl,
            orphanCount: state.totalOrphans,
            taskCount: state.totalTasks,
            visitCount: state.totalVisits,
            onLogout: () {
              context.read<AuthBloc>().add(LogoutButtonPressed());
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          );
        }
        return AppDrawer(
          institutionId: '',
          kafalaHeadId: '',
          userName: 'جاري التحميل...',
          userRole: '...',
          profileImageUrl: '',
          orphanCount: 0,
          taskCount: 0,
          visitCount: 0,
          onLogout: () {},
        );
      },
    );
  }
}