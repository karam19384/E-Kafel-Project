// lib/src/screens/field_visits_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/blocs/visit/visit_bloc.dart';
import 'package:e_kafel/src/themes/app_colors.dart';
import 'package:e_kafel/src/widgets/app_drawer.dart';

import '../blocs/auth/auth_bloc.dart';
import 'login_screen.dart';

class FieldVisitsScreen extends StatefulWidget {
  const FieldVisitsScreen({super.key});

  @override
  State<FieldVisitsScreen> createState() => _FieldVisitsScreenState();
}

class _FieldVisitsScreenState extends State<FieldVisitsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
     final homeState = context.read<HomeBloc>().state;
    if (homeState is HomeLoaded) {
      _loadAllVisits(homeState.institutionId);
    }
  }

  void _loadAllVisits(String institutionId) {
    final homeState = context.read<HomeBloc>().state;
    if (homeState is HomeLoaded) {
      context
          .read<VisitBloc>()
          .add(LoadAllVisits(institutionId: homeState.institutionId));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) setState(() => _selectedDate = pickedDate);
  }

  void _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime != null) setState(() => _selectedTime = pickedTime);
  }

void _saveVisit() {
    if (_formKey.currentState!.validate()) {
      final finalDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final homeState = context.read<HomeBloc>().state;
      if (homeState is HomeLoaded) {
        final institutionId = homeState.institutionId; 
        context.read<VisitBloc>().add(AddVisit(
              date: finalDate,
              name: _titleController.text,
              location: _addressController.text,
              institutionId: institutionId,
            ));
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم حفظ الزيارة بنجاح')));
    }
}

  
void _showUpdateDialog(Map<String, dynamic> visit) {
    _titleController.text = visit['name'];
    _addressController.text = visit['location'];
    final visitDateTime = DateTime.parse(visit['date']);
    _selectedDate = visitDateTime;
    _selectedTime = TimeOfDay.fromDateTime(visitDateTime);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل الزيارة'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'عنوان الزيارة'),
                    validator: (value) => value!.isEmpty ? 'لا يمكن أن يكون العنوان فارغًا' : null,
                  ),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'موقع الزيارة'),
                    validator: (value) => value!.isEmpty ? 'لا يمكن أن يكون الموقع فارغًا' : null,
                  ),
                  ListTile(
                    title: Text("التاريخ: ${_selectedDate.toLocal().toString().split(' ')[0]}"),
                    trailing: const Icon(Icons.keyboard_arrow_down),
                    onTap: _selectDate,
                  ),
                  ListTile(
                    title: Text("الوقت: ${_selectedTime.format(context)}"),
                    trailing: const Icon(Icons.keyboard_arrow_down),
                    onTap: _selectTime,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('إلغاء'),
            ),
            if (visit['status'] == 'مجدولة')
              TextButton(
                onPressed: () {
                  final homeState = context.read<HomeBloc>().state;
                  if (homeState is HomeLoaded) {
                    context.read<VisitBloc>().add(
                          UpdateVisit(
                            id: visit['id'],
                            updates: {
                              'status': 'مكتملة',
                              'name': visit['name'],
                            },
                            institutionId: homeState.institutionId, // ✅ إضافة الـ ID
                          ),
                        );
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('تمت الزيارة'),
              ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final finalDate = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  );
                  final homeState = context.read<HomeBloc>().state;
                  if (homeState is HomeLoaded) {
                    context.read<VisitBloc>().add(
                          UpdateVisit(
                            id: visit['id'],
                            updates: {
                              'name': _titleController.text,
                              'location': _addressController.text,
                              'date': finalDate.toIso8601String(),
                            },
                            institutionId: homeState.institutionId, // ✅ إضافة الـ ID
                          ),
                        );
                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text('حفظ التغييرات'),
            ),
          ],
        );
      },
    );
}

Widget _buildVisitList(List<Map<String, dynamic>> visits, String status) {
    if (visits.isEmpty) {
      return Center(child: Text('لا توجد زيارات ${status} حاليًا.'));
    }
    return ListView.builder(
      itemCount: visits.length,
      itemBuilder: (context, index) {
        final visit = visits[index];
        final visitDate = DateTime.parse(visit['date']);
        return Dismissible(
          key: Key(visit['id']),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            final homeState = context.read<HomeBloc>().state;
            if (homeState is HomeLoaded) {
              context.read<VisitBloc>().add(
                    DeleteVisit(
                      id: visit['id'],
                      status: visit['status'],
                      institutionId: homeState.institutionId, // ✅ إضافة الـ ID
                    ),
                  );
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تم حذف زيارة ${visit['name']}')),
            );
          },
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: ListTile(
            title: Text(visit['name']),
            subtitle: Text('الموقع: ${visit['location']}'),
            trailing: Text(
              '${visitDate.year}-${visitDate.month.toString().padLeft(2, '0')}-${visitDate.day.toString().padLeft(2, '0')} '
              '${visitDate.hour.toString().padLeft(2, '0')}:${visitDate.minute.toString().padLeft(2, '0')}',
            ),
            onTap: () => _showUpdateDialog(visit),
          ),
        );
      },
    );
}

  @override
  Widget build(BuildContext context) {
    return BlocListener<VisitBloc, VisitState>(
      listener: (context, state) {
        if (state is VisitLoaded) {
          context.read<HomeBloc>().add(LoadHomeData());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الزيارات الميدانية'),
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'الزيارات المجدولة'),
              Tab(text: 'الزيارات المكتملة'),
            ],
          ),
        ),
        drawer: _buildDrawer(),
        body: BlocBuilder<VisitBloc, VisitState>(
          builder: (context, state) {
            if (state is VisitLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is VisitLoaded) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildVisitList(state.scheduledVisits, 'مجدولة'),
                  _buildVisitList(state.completedVisits, 'مكتملة'),
                ],
              );
            } else if (state is VisitError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return const Center(child: Text('ابدأ بإضافة زيارات جديدة'));
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _titleController.clear();
            _addressController.clear();
            _selectedDate = DateTime.now();
            _selectedTime = TimeOfDay.now();
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('إضافة زيارة جديدة'),
                  content: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(labelText: 'عنوان الزيارة'),
                            validator: (value) => value!.isEmpty ? 'لا يمكن أن يكون العنوان فارغًا' : null,
                          ),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(labelText: 'موقع الزيارة'),
                            validator: (value) => value!.isEmpty ? 'لا يمكن أن يكون الموقع فارغًا' : null,
                          ),
                          ListTile(
                            title: Text("التاريخ: ${_selectedDate.toLocal().toString().split(' ')[0]}"),
                            trailing: const Icon(Icons.keyboard_arrow_down),
                            onTap: _selectDate,
                          ),
                          ListTile(
                            title: Text("الوقت: ${_selectedTime.format(context)}"),
                            trailing: const Icon(Icons.keyboard_arrow_down),
                            onTap: _selectTime,
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
                      child: const Text('حفظ'),
                    ),
                  ],
                );
              },
            );
          },
          backgroundColor: AppColors.primaryColor,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoaded) {
          return AppDrawer(
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
        // حالة التحميل أو الخطأ
        return AppDrawer(
          userName: 'Loading...',
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