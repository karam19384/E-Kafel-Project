import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/themes/app_colors.dart';
import 'package:e_kafel/src/widgets/app_drawer.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';

import 'login_screen.dart';

class FieldVisitsScreen extends StatefulWidget {
  const FieldVisitsScreen({super.key});

  @override
  State<FieldVisitsScreen> createState() => _FieldVisitsScreenState();
}

class _FieldVisitsScreenState extends State<FieldVisitsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  // ignore: unused_field
  final String _selectedStatus = 'مجدولة';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الزيارات الميدانية'),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      drawer: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoaded) {
            return AppDrawer(
              userName: state.userName,
              userRole: state.userRole,
              profileImageUrl: state.profileImageUrl,
              orphanCount: state.orphanSponsored,
              taskCount: state.completedTasksPercentage
                  .toInt(), // عدلها حسب المتغير المناسب
              visitCount: state.completedFieldVisits
                  .toInt(), // عدلها حسب المتغير المناسب
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
            return _buildFieldVisitsContent(context, state);
          }

          return const Center(child: Text('لا توجد بيانات متاحة'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVisitDialog,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFieldVisitsContent(BuildContext context, HomeState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // إحصائيات الزيارات
          _buildVisitStats(state),
          const SizedBox(height: 24),

          // قائمة الزيارات
          _buildVisitsList(),
        ],
      ),
    );
  }

  Widget _buildVisitStats(HomeState state) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إحصائيات الزيارات',
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
                    'إجمالي الزيارات',
                    '25',
                    Icons.visibility,
                    AppColors.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'مكتملة',
                    '18',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'مجدولة',
                    '7',
                    Icons.schedule,
                    Colors.orange,
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
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildVisitsList() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الزيارات المجدولة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildVisitItem(
              'زيارة دار الأيتام A',
              '2024-01-15',
              '10:00 ص',
              'مجدولة',
              Icons.schedule,
              Colors.orange,
            ),
            _buildVisitItem(
              'زيارة يتيم B',
              '2024-01-16',
              '2:00 م',
              'مكتملة',
              Icons.check_circle,
              Colors.green,
            ),
            _buildVisitItem(
              'زيارة دار الأيتام C',
              '2024-01-17',
              '9:00 ص',
              'مجدولة',
              Icons.schedule,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitItem(
    String title,
    String date,
    String time,
    String status,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Icon(icon, color: color, size: 30),
      title: Text(title),
      subtitle: Text('$date - $time'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () => _showVisitDetails(title, date, time, status),
    );
  }

  void _showAddVisitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة زيارة ميدانية جديدة'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الزيارة',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال عنوان الزيارة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'وصف الزيارة',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الزيارة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('اختيار التاريخ'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectTime,
                        icon: const Icon(Icons.access_time),
                        label: const Text('اختيار الوقت'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _saveVisit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveVisit() {
    if (_formKey.currentState!.validate()) {
      // حفظ الزيارة في قاعدة البيانات
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حفظ الزيارة بنجاح')));
    }
  }

  void _showVisitDetails(
    String title,
    String date,
    String time,
    String status,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('التاريخ: $date'),
            Text('الوقت: $time'),
            Text('الحالة: $status'),
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
