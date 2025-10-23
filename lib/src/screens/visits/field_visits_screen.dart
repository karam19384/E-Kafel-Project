// lib/src/screens/field_visits_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/blocs/visit/visit_bloc.dart';
import 'package:e_kafel/src/utils/app_colors.dart';
import 'package:e_kafel/src/widgets/app_drawer.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../Auth/login_screen.dart';

class FieldVisitsScreen extends StatefulWidget {
  static const routeName = '/field_visits_screen';

  const FieldVisitsScreen({super.key});

  @override
  State<FieldVisitsScreen> createState() => _FieldVisitsScreenState();
}

class _FieldVisitsScreenState extends State<FieldVisitsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _searchController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  late TabController _tabController;
  
  // متغيرات البحث والتصفية
  bool _showSearchField = false;
  String _searchQuery = '';
  String? _statusFilter;
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final homeState = context.read<HomeBloc>().state;
    if (homeState is HomeLoaded) {
      context.read<VisitBloc>().add(
        LoadAllVisits(institutionId: homeState.institutionId),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _addressController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
        context.read<VisitBloc>().add(
          AddVisit(
            date: finalDate,
            name: _titleController.text,
            location: _addressController.text,
            institutionId: institutionId,
          ),
        );
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم حفظ الزيارة بنجاح'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.filter_list, color: AppColors.primaryColor),
              SizedBox(width: 8),
              Text('تصفية الزيارات'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // تصفية حسب الحالة
                const Text(
                  'حالة الزيارة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('الكل'),
                      selected: _statusFilter == null,
                      onSelected: (selected) {
                        setDialogState(() => _statusFilter = null);
                      },
                    ),
                    FilterChip(
                      label: const Text('مجدولة'),
                      selected: _statusFilter == 'scheduled',
                      onSelected: (selected) {
                        setDialogState(() => _statusFilter = 'scheduled');
                      },
                    ),
                    FilterChip(
                      label: const Text('مكتملة'),
                      selected: _statusFilter == 'completed',
                      onSelected: (selected) {
                        setDialogState(() => _statusFilter = 'completed');
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                
                // تصفية حسب التاريخ
                const Text(
                  'النطاق الزمني',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _startDateFilter == null 
                              ? 'من تاريخ' 
                              : '${_startDateFilter!.day}/${_startDateFilter!.month}/${_startDateFilter!.year}',
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDateFilter ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => _startDateFilter = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _endDateFilter == null 
                              ? 'إلى تاريخ' 
                              : '${_endDateFilter!.day}/${_endDateFilter!.month}/${_endDateFilter!.year}',
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDateFilter ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => _endDateFilter = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                
                if (_startDateFilter != null || _endDateFilter != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton(
                      onPressed: () {
                        setDialogState(() {
                          _startDateFilter = null;
                          _endDateFilter = null;
                        });
                      },
                      child: const Text('مسح التواريخ'),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _statusFilter = null;
                  _startDateFilter = null;
                  _endDateFilter = null;
                });
                Navigator.pop(context);
              },
              child: const Text('مسح الكل', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('تطبيق'),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> visits) {
    return visits.where((visit) {
      // تطبيق البحث
      final matchesSearch = _searchQuery.isEmpty ||
          visit['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          visit['location'].toLowerCase().contains(_searchQuery.toLowerCase());
      
      // تطبيق تصفية الحالة
      final matchesStatus = _statusFilter == null || visit['status'] == _statusFilter;
      
      // تطبيق تصفية التاريخ
      final visitDate = DateTime.parse(visit['date']);
      final matchesStartDate = _startDateFilter == null || 
          visitDate.isAfter(_startDateFilter!.subtract(const Duration(days: 1)));
      final matchesEndDate = _endDateFilter == null || 
          visitDate.isBefore(_endDateFilter!.add(const Duration(days: 1)));
      
      return matchesSearch && matchesStatus && matchesStartDate && matchesEndDate;
    }).toList();
  }

  void _showUpdateDialog(Map<String, dynamic> visit) {
    _titleController.text = visit['name'];
    _addressController.text = visit['location'];

    final visitDateTime = DateTime.tryParse(visit['date']) ?? DateTime.now();
    _selectedDate = visitDateTime;
    _selectedTime = TimeOfDay.fromDateTime(visitDateTime);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                visit['status'] == 'scheduled' ? Icons.access_time : Icons.check_circle,
                color: visit['status'] == 'scheduled' ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                visit['status'] == 'scheduled' ? 'تعديل الزيارة' : 'تفاصيل الزيارة',
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الزيارة',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty
                        ? 'لا يمكن أن يكون العنوان فارغًا'
                        : null,
                    enabled: visit['status'] == 'scheduled',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'موقع الزيارة',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'لا يمكن أن يكون الموقع فارغًا' : null,
                    enabled: visit['status'] == 'scheduled',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.grey),
                      title: Text(
                        "التاريخ: ${_selectedDate.toLocal().toString().split(' ')[0]}",
                      ),
                      trailing: const Icon(Icons.keyboard_arrow_down),
                      onTap: visit['status'] == 'scheduled' ? _selectDate : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.access_time, color: Colors.grey),
                      title: Text("الوقت: ${_selectedTime.format(context)}"),
                      trailing: const Icon(Icons.keyboard_arrow_down),
                      onTap: visit['status'] == 'scheduled' ? _selectTime : null,
                    ),
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
            if (visit['status'] == 'scheduled')
              ElevatedButton(
                onPressed: () {
                  final homeState = context.read<HomeBloc>().state;
                  if (homeState is HomeLoaded) {
                    context.read<VisitBloc>().add(
                      UpdateVisit(
                        id: visit['id'],
                        updates: {
                          'status': 'completed',
                          'name': visit['name'],
                          'institutionId': homeState.institutionId,
                        },
                        institutionId: homeState.institutionId,
                      ),
                    );
                  }
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('تمت الزيارة'),
              ),
            if (visit['status'] == 'completed')
              ElevatedButton(
                onPressed: () {
                  final homeState = context.read<HomeBloc>().state;
                  if (homeState is HomeLoaded) {
                    context.read<VisitBloc>().add(
                      UpdateVisit(
                        id: visit['id'],
                        updates: {
                          'status': 'scheduled',
                          'name': visit['name'],
                          'institutionId': homeState.institutionId,
                        },
                        institutionId: homeState.institutionId,
                      ),
                    );
                  }
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('إعادة إلى المجدولة'),
              ),
            if (visit['status'] == 'scheduled')
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
                            'institutionId': homeState.institutionId,
                          },
                          institutionId: homeState.institutionId,
                        ),
                      );
                    }
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('حفظ التغييرات'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildVisitList(List<Map<String, dynamic>> visits, String status) {
    final filteredVisits = _applyFilters(visits);
    
    if (filteredVisits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد زيارات ${status == 'scheduled' ? 'مجدولة' : 'مكتملة'}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'استخدم زر الإضافة لإنشاء زيارة جديدة',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredVisits.length,
      itemBuilder: (context, index) {
        final visit = filteredVisits[index];
        final visitDate = DateTime.parse(visit['date']);
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: Key(visit['id']),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              final homeState = context.read<HomeBloc>().state;
              if (homeState is HomeLoaded) {
                context.read<VisitBloc>().add(
                  DeleteVisit(
                    id: visit['id'],
                    status: visit['status'],
                    institutionId: homeState.institutionId,
                  ),
                );
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم حذف زيارة ${visit['name']}'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            background: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white, size: 30),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: status == 'scheduled' 
                      ? Colors.orange.withOpacity(0.1) 
                      : Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  status == 'scheduled' ? Icons.access_time : Icons.check_circle,
                  color: status == 'scheduled' ? Colors.orange : Colors.green,
                ),
              ),
              title: Text(
                visit['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          visit['location'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${visitDate.year}-${visitDate.month.toString().padLeft(2, '0')}-${visitDate.day.toString().padLeft(2, '0')} '
                        '${visitDate.hour.toString().padLeft(2, '0')}:${visitDate.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_left, color: Colors.grey),
              onTap: () => _showUpdateDialog(visit),
            ),
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
        appBar: _buildAppBar(),
        drawer: _buildDrawer(),
        body: BlocBuilder<VisitBloc, VisitState>(
          builder: (context, state) {
            if (state is VisitLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              );
            } else if (state is VisitLoaded) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildVisitList(state.scheduledVisits, 'scheduled'),
                  _buildVisitList(state.completedVisits, 'completed'),
                ],
              );
            } else if (state is VisitError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'حدث خطأ: ${state.message}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        final homeState = context.read<HomeBloc>().state;
                        if (homeState is HomeLoaded) {
                          context.read<VisitBloc>().add(
                            LoadAllVisits(institutionId: homeState.institutionId),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'ابدأ بإضافة زيارات جديدة',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
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
                  title: const Row(
                    children: [
                      Icon(Icons.add_location, color: AppColors.primaryColor),
                      SizedBox(width: 8),
                      Text('إضافة زيارة جديدة'),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'عنوان الزيارة',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value!.isEmpty
                                ? 'لا يمكن أن يكون العنوان فارغًا'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'موقع الزيارة',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value!.isEmpty
                                ? 'لا يمكن أن يكون الموقع فارغًا'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.calendar_today, color: Colors.grey),
                              title: Text(
                                "التاريخ: ${_selectedDate.toLocal().toString().split(' ')[0]}",
                              ),
                              trailing: const Icon(Icons.keyboard_arrow_down),
                              onTap: _selectDate,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.access_time, color: Colors.grey),
                              title: Text("الوقت: ${_selectedTime.format(context)}"),
                              trailing: const Icon(Icons.keyboard_arrow_down),
                              onTap: _selectTime,
                            ),
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
                      child: const Text('حفظ الزيارة'),
                    ),
                  ],
                );
              },
            );
          },
          backgroundColor: AppColors.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: _showSearchField 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'ابحث في الزيارات...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            )
          : const Text('الزيارات الميدانية'),
      centerTitle: true,
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(
            icon: Icon(Icons.access_time),
            text: 'المجدولة',
          ),
          Tab(
            icon: Icon(Icons.check_circle),
            text: 'المكتملة',
          ),
        ],
      ),
      actions: [
        // أيقونة البحث
        if (!_showSearchField)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _showSearchField = true;
              });
            },
          ),
        
        // أيقونة التصفية
        IconButton(
          icon: Badge(
            isLabelVisible: _statusFilter != null || 
                           _startDateFilter != null || 
                           _endDateFilter != null,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.filter_list),
          ),
          onPressed: _showFilterDialog,
          tooltip: 'تصفية الزيارات',
        ),
        
        // أيقونة إغلاق البحث
        if (_showSearchField)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _showSearchField = false;
                _searchQuery = '';
                _searchController.clear();
              });
            },
          ),
      ],
    );
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