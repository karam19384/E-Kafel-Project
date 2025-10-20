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
  final String _selectedPriority = 'متوسط';
  final String _selectedStatus = 'pending';
  final DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  Map<String, dynamic>? _currentUserData;

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

    // 🔹 أرسل حدث تحميل المهام بعد جلب بيانات المستخدم
    context.read<TasksBloc>().add(
      LoadTasksEvent(_currentUserData?['institutionId'] ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المهام'),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      drawer: _buildDrawer(),
      body: BlocBuilder<TasksBloc, TasksState>(
        builder: (context, state) {
          if (state is TasksLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TasksLoaded) {
            return _buildTasksContent(state.tasks);
          } else if (state is TasksError) {
            return Center(child: Text('خطأ: ${state.message}'));
          }
          return const Center(child: Text('لا توجد بيانات متاحة'));
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTasksContent(List<TaskModel> tasks) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTaskStats(tasks),
          const SizedBox(height: 24),
          _buildTasksList(tasks),
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

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إحصائيات المهام',
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

  Widget _buildTasksList(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return const Center(child: Text('لا توجد مهام حالياً'));
    }
    return Card(
      elevation: 4,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _buildTaskItem(task);
        },
      ),
    );
  }

  Widget _buildTaskItem(TaskModel task) {
    String displayStatus = task.status == 'completed'
        ? 'مكتملة'
        : task.status == 'pending'
        ? 'معلقة'
        : task.status;

    return ListTile(
      leading: Icon(
        Icons.task_alt,
        color: _getPriorityColor(task.priority),
        size: 30,
      ),
      title: Text(task.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((task.taskLocation ?? '').isNotEmpty)
            Text('المكان: ${task.taskLocation}'),
          Text(
            'تاريخ الاستحقاق: ${task.dueDate.toLocal().toString().split(' ')[0]}',
          ),
          Text('مكان المهمة: ${task.taskLocation}'),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChip(task.priority, _getPriorityColor(task.priority)),
          const SizedBox(width: 8),
          _buildChip(
            displayStatus,
            displayStatus == 'مكتملة' ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showEditTaskDialog(task);
                  break;
                case 'delete':
                  context.read<TasksBloc>().add(
                    DeleteTaskEvent(
                      task.id,
                      _currentUserData?['institutionId'] ?? '',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف المهمة')),
                  );
                  break;
                case 'complete':
                  final updatedTask = task.copyWith(status: 'completed');
                  context.read<TasksBloc>().add(
                    UpdateTaskEvent(
                      updatedTask,
                      _currentUserData?['institutionId'] ?? '',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم وضع المهمة كمكتملة')),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('تعديل')),
              const PopupMenuItem(value: 'delete', child: Text('حذف')),
              if (task.status != 'completed')
                const PopupMenuItem(
                  value: 'complete',
                  child: Text('وضع كمكتملة'),
                ),
            ],
          ),
        ],
      ),
      onTap: () => _showTaskDetails(task),
    );
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الوصف: ${task.description}'),
            Text('الأولوية: ${task.priority}'),
            Text('الحالة: ${task.status}'),
            Text('تاريخ الاستحقاق: ${task.dueDate.toLocal()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
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
