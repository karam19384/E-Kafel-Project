import 'package:e_kafel/src/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/blocs/tasks/tasks_bloc.dart';
import 'package:e_kafel/src/utils/app_colors.dart';
import 'package:e_kafel/src/widgets/app_drawer.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import '../../models/tasks_model.dart';
import '../Auth/login_screen.dart';

class TasksScreen extends StatefulWidget {
  static const routeName = '/tasks_screen';

  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  
  final String _selectedPriority = 'متوسط';
  final String _selectedStatus = 'pending';
  final DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  Map<String, dynamic>? _currentUserData;
  
  // متغيرات البحث والتصفية
  bool _showSearchField = false;
  String _searchQuery = '';
  String? _statusFilter;
  String? _priorityFilter;
  String? _typeFilter;
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  String _sortBy = 'dueDate'; // dueDate, priority, createdAt

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userData = await FirestoreService().getUserData(uid);
    setState(() {
      _currentUserData = userData;
    });

    context.read<TasksBloc>().add(
      LoadTasksEvent(_currentUserData?['institutionId'] ?? ''),
    );
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
              Text('تصفية وترتيب المهام'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // تصفية حسب الحالة
                _buildFilterSection(
                  title: 'حالة المهمة',
                  value: _statusFilter,
                  options: const ['معلقة', 'مكتملة'],
                  onChanged: (value) => setDialogState(() => _statusFilter = value),
                ),
                
                const SizedBox(height: 16),
                
                // تصفية حسب الأولوية
                _buildFilterSection(
                  title: 'الأولوية',
                  value: _priorityFilter,
                  options: const ['عالي', 'متوسط', 'منخفض'],
                  onChanged: (value) => setDialogState(() => _priorityFilter = value),
                ),
                
                const SizedBox(height: 16),
                
                // تصفية حسب النوع
                _buildFilterSection(
                  title: 'نوع المهمة',
                  value: _typeFilter,
                  options: const ['إدارية', 'ميدانية', 'متابعة'],
                  onChanged: (value) => setDialogState(() => _typeFilter = value),
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
                
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                
                // ترتيب النتائج
                _buildSortSection(setDialogState),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _statusFilter = null;
                  _priorityFilter = null;
                  _typeFilter = null;
                  _startDateFilter = null;
                  _endDateFilter = null;
                  _sortBy = 'dueDate';
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

  Widget _buildFilterSection({
    required String title,
    required String? value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('الكل'),
              selected: value == null,
              onSelected: (selected) {
                onChanged(null);
              },
              backgroundColor: Colors.grey[200],
              selectedColor: AppColors.primaryColor.withOpacity(0.2),
              checkmarkColor: AppColors.primaryColor,
              labelStyle: TextStyle(
                color: value == null ? AppColors.primaryColor : Colors.black87,
                fontWeight: value == null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            ...options.map((option) {
              final isSelected = value == option;
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  onChanged(selected ? option : null);
                },
                backgroundColor: Colors.grey[200],
                selectedColor: AppColors.primaryColor.withOpacity(0.2),
                checkmarkColor: AppColors.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primaryColor : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildSortSection(StateSetter setDialogState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ترتيب النتائج',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSortOption('تاريخ الاستحقاق', 'dueDate', setDialogState),
            _buildSortOption('الأولوية', 'priority', setDialogState),
            _buildSortOption('تاريخ الإنشاء', 'createdAt', setDialogState),
          ],
        ),
      ],
    );
  }

  Widget _buildSortOption(String label, String value, StateSetter setDialogState) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setDialogState(() => _sortBy = value);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: AppColors.primaryColor.withOpacity(0.2),
      checkmarkColor: AppColors.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  List<TaskModel> _applyFilters(List<TaskModel> tasks) {
    var filteredTasks = tasks.where((task) {
      // تطبيق البحث
      final matchesSearch = _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (task.description).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (task.taskLocation ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      
      // تطبيق تصفية الحالة
      final taskStatus = task.status == 'completed' ? 'مكتملة' : 'معلقة';
      final matchesStatus = _statusFilter == null || taskStatus == _statusFilter;
      
      // تطبيق تصفية الأولوية
      final matchesPriority = _priorityFilter == null || task.priority == _priorityFilter;
      
      // تطبيق تصفية النوع
      final matchesType = _typeFilter == null || task.taskType == _typeFilter;
      
      // تطبيق تصفية التاريخ
      final matchesStartDate = _startDateFilter == null || 
          task.dueDate.isAfter(_startDateFilter!.subtract(const Duration(days: 1)));
      final matchesEndDate = _endDateFilter == null || 
          task.dueDate.isBefore(_endDateFilter!.add(const Duration(days: 1)));
      
      return matchesSearch && matchesStatus && matchesPriority && matchesType && matchesStartDate && matchesEndDate;
    }).toList();

    // تطبيق الترتيب
    filteredTasks.sort((a, b) {
      switch (_sortBy) {
        case 'priority':
          final priorityOrder = {'عالي': 3, 'متوسط': 2, 'منخفض': 1};
          return (priorityOrder[b.priority] ?? 0).compareTo(priorityOrder[a.priority] ?? 0);
        case 'createdAt':
          return b.createdAt.compareTo(a.createdAt);
        case 'dueDate':
        default:
          return a.dueDate.compareTo(b.dueDate);
      }
    });

    return filteredTasks;
  }

  bool _hasActiveFilters() {
    return _statusFilter != null ||
           _priorityFilter != null ||
           _typeFilter != null ||
           _startDateFilter != null ||
           _endDateFilter != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: BlocBuilder<TasksBloc, TasksState>(
        builder: (context, state) {
          if (state is TasksLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            );
          } else if (state is TasksLoaded) {
            return _buildTasksContent(state.tasks);
          } else if (state is TasksError) {
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
                    'خطأ: ${state.message}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      context.read<TasksBloc>().add(
                        LoadTasksEvent(_currentUserData?['institutionId'] ?? ''),
                      );
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
                Icon(Icons.task, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا توجد بيانات متاحة',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
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
                hintText: 'ابحث في المهام...',
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
          : const Text('إدارة المهام'),
      centerTitle: true,
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
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
        
        // أيقونة التصفية والترتيب
        IconButton(
          icon: Badge(
            isLabelVisible: _hasActiveFilters(),
            backgroundColor: Colors.orange,
            child: const Icon(Icons.filter_list),
          ),
          onPressed: _showFilterDialog,
          tooltip: 'فرز وتصفية المهام',
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

  Widget _buildTasksContent(List<TaskModel> tasks) {
    final filteredTasks = _applyFilters(tasks);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTaskStats(filteredTasks),
          const SizedBox(height: 24),
          _buildTasksList(filteredTasks),
        ],
      ),
    );
  }

  Widget _buildTaskStats(List<TaskModel> tasks) {
    final total = tasks.length;
    final completed = tasks
        .where(
          (t) => t.status == 'مكتملة' || t.status.toLowerCase() == 'completed',
        )
        .length;
    final pending = tasks
        .where(
          (t) => t.status == 'معلقة' || t.status.toLowerCase() == 'pending',
        )
        .length;
    final highPriority = tasks.where((t) => t.priority == 'عالي').length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إحصائيات المهام',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'إجمالي المهام',
                    '$total',
                    Icons.assignment,
                    AppColors.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'مكتملة',
                    '$completed',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'معلقة',
                    '$pending',
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'عالي أولوية',
                    '$highPriority',
                    Icons.priority_high,
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
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: color),
        ),
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTasksList(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return _buildEmptyTasks();
    }
    
    return Column(
      children: [
        // رأس عدد النتائج
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عدد المهام: ${tasks.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (_hasActiveFilters() || _searchQuery.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _statusFilter = null;
                      _priorityFilter = null;
                      _typeFilter = null;
                      _startDateFilter = null;
                      _endDateFilter = null;
                      _searchController.clear();
                    });
                  },
                  child: const Text('مسح الفلاتر'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // قائمة المهام
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _buildTaskItem(task);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyTasks() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد مهام حالياً',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'استخدم زر الإضافة لإنشاء مهمة جديدة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TaskModel task) {
    String displayStatus = task.status == 'completed'
        ? 'مكتملة'
        : task.status == 'pending'
        ? 'معلقة'
        : task.status;

    Color statusColor = displayStatus == 'مكتملة' ? Colors.green : Colors.orange;
    Color priorityColor = _getPriorityColor(task.priority);
    bool isOverdue = task.dueDate.isBefore(DateTime.now()) && displayStatus == 'معلقة';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getTaskIcon(task.taskType),
            color: priorityColor,
            size: 24,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            if ((task.description).isNotEmpty)
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.taskLocation ?? 'غير محدد',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  task.dueDate.toLocal().toString().split(' ')[0],
                  style: TextStyle(
                    fontSize: 14,
                    color: isOverdue ? Colors.red : Colors.grey[600],
                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isOverdue)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'متأخرة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildChip(task.priority, priorityColor),
            _buildChip(displayStatus, statusColor),
          ],
        ),
        onTap: () => _showTaskDetails(task),
      ),
    );
  }

  IconData _getTaskIcon(String? taskType) {
    switch (taskType) {
      case 'ميدانية':
        return Icons.location_on;
      case 'متابعة':
        return Icons.track_changes;
      case 'إدارية':
      default:
        return Icons.assignment;
    }
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'عالي':
        return Colors.red;
      case 'متوسط':
        return Colors.orange;
      case 'منخفض':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showAddTaskDialog() {
    _showTaskDialog();
  }

  void _showEditTaskDialog(TaskModel task) {
    _showTaskDialog(editingTask: task);
  }

  void _showTaskDialog({TaskModel? editingTask}) async {
    final isEditing = editingTask != null;

    // 🔹 Controllers لكل حقل
    final titleController = TextEditingController(
      text: editingTask?.title ?? '',
    );
    final descController = TextEditingController(
      text: editingTask?.description ?? '',
    );
    final locationController = TextEditingController(
      text: editingTask?.taskLocation ?? '',
    );
    String selectedPriority = editingTask?.priority ?? 'متوسط';
    String selectedStatus = editingTask?.status ?? 'pending';
    String selectedTaskType = editingTask?.taskType ?? 'إدارية';
    String? selectedSupervisorId = editingTask?.assignedTo;

    DateTime selectedDate =
        editingTask?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(
      editingTask?.dueDate ?? DateTime.now(),
    );

    // 🔹 جلب المشرفين حسب المؤسسة
    final supervisors = await FirestoreService().listSupervisors(
      _currentUserData?['institutionId'] ?? '',
    );

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'تعديل المهمة' : 'إضافة مهمة جديدة'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // عنوان المهمة
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان المهمة',
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'أدخل عنوان المهمة' : null,
                  ),
                  const SizedBox(height: 12),

                  // وصف المهمة
                  TextFormField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'وصف المهمة'),
                  ),
                  const SizedBox(height: 12),

                  // مكان المهمة
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'مكان المهمة'),
                  ),
                  const SizedBox(height: 12),

                  // نوع المهمة
                  DropdownButtonFormField<String>(
                    value: selectedTaskType,
                    items: const [
                      DropdownMenuItem(value: 'إدارية', child: Text('إدارية')),
                      DropdownMenuItem(
                        value: 'ميدانية',
                        child: Text('ميدانية'),
                      ),
                      DropdownMenuItem(value: 'متابعة', child: Text('متابعة')),
                    ],
                    onChanged: (val) => setState(() => selectedTaskType = val!),
                    decoration: const InputDecoration(labelText: 'نوع المهمة'),
                  ),
                  const SizedBox(height: 12),

                  // الأولوية
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    items: const [
                      DropdownMenuItem(value: 'عالي', child: Text('عالي')),
                      DropdownMenuItem(value: 'متوسط', child: Text('متوسط')),
                      DropdownMenuItem(value: 'منخفض', child: Text('منخفض')),
                    ],
                    onChanged: (val) => setState(() => selectedPriority = val!),
                    decoration: const InputDecoration(labelText: 'الأولوية'),
                  ),
                  const SizedBox(height: 12),

                  // الحالة
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'pending', child: Text('معلقة')),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('مكتملة'),
                      ),
                    ],
                    onChanged: (val) => setState(() => selectedStatus = val!),
                    decoration: const InputDecoration(labelText: 'الحالة'),
                  ),
                  const SizedBox(height: 12),

                  // اختيار المشرف
                  DropdownButtonFormField<String>(
                    value: selectedSupervisorId,
                    items: supervisors
                        .map<DropdownMenuItem<String>>(
                          (sup) => DropdownMenuItem(
                            value: sup.uid,
                            child: Text(sup.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => selectedSupervisorId = val),
                    decoration: const InputDecoration(
                      labelText: 'المشرف المسؤول',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // اختيار التاريخ والوقت
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      'تاريخ الاستحقاق: ${selectedDate.toLocal().toString().split(' ')[0]}',
                    ),
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null)
                        setState(() => selectedDate = pickedDate);
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text('الوقت: ${selectedTime.format(context)}'),
                    onPressed: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (pickedTime != null)
                        setState(() => selectedTime = pickedTime);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                final dueDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                final task = TaskModel(
                  id: isEditing ? editingTask.id : '', // 🔹 مهم جدًا
                  title: titleController.text,
                  description: descController.text,
                  priority: selectedPriority,
                  status: selectedStatus,
                  dueDate: dueDateTime,
                  createdAt: isEditing ? editingTask.createdAt : DateTime.now(),
                  institutionId: _currentUserData?['institutionId'] ?? '',
                  kafalaHeadId: _currentUserData?['uid'] ?? '',
                  taskType: selectedTaskType,
                  assignedTo: selectedSupervisorId ?? '',
                  taskLocation: locationController.text,
                );

                if (isEditing) {
                  context.read<TasksBloc>().add(
                    UpdateTaskEvent(task, task.institutionId),
                  );
                } else {
                  context.read<TasksBloc>().add(
                    AddTaskEvent(task, task.institutionId),
                  );
                }

                Navigator.pop(context);

                // 🔹 إعادة تحميل المهام بعد الحفظ
                context.read<TasksBloc>().add(
                  LoadTasksEvent(_currentUserData?['institutionId'] ?? ''),
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

void _showTaskDetails(TaskModel task) {
  String displayStatus = task.status == 'completed' ? 'مكتملة' : 'معلقة';
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(
            _getTaskIcon(task.taskType),
            color: AppColors.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(task.title)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((task.description ).isNotEmpty) ...[
              const Text(
                'الوصف:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(task.description),
              const SizedBox(height: 16),
            ],
            
            _buildDetailRow('نوع المهمة:', task.taskType),
            _buildDetailRow('الأولوية:', task.priority),
            _buildDetailRow('الحالة:', displayStatus),
            _buildDetailRow('المكان:', task.taskLocation ?? 'غير محدد'),
            _buildDetailRow(
              'تاريخ الاستحقاق:', 
              task.dueDate.toLocal().toString().split(' ')[0]
            ),
            _buildDetailRow(
              'تاريخ الإنشاء:', 
              task.createdAt.toLocal().toString().split(' ')[0]
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
        ElevatedButton(
          onPressed: () => _showEditTaskDialog(task),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('تعديل'),
        ),
      ],
    ),
  );
}
 
  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value!)),
        ],
      ),
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
 