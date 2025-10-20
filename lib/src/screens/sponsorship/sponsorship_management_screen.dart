import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/home/home_bloc.dart';
import '../../blocs/sponsership/sponsership_bloc.dart';
import '../../models/sponsorship_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../Auth/login_screen.dart';
import '../../blocs/auth/auth_bloc.dart';

class SponsorshipManagementScreen extends StatefulWidget {
  static const routeName = '/sponsorship_management_screen';
  const SponsorshipManagementScreen({super.key});

  @override
  State<SponsorshipManagementScreen> createState() =>
      _SponsorshipManagementScreenState();
}

class _SponsorshipManagementScreenState
    extends State<SponsorshipManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _searchController = TextEditingController();

  String _selectedProjectType = 'مشروع كفالة';
  String? _filterStatus; // فلتر الحالة
  String? _filterType; // فلتر النوع

  final List<String> _projectTypes = const [
    'مشروع كفالة',
    'مشروع تعليمي',
    'مشروع صحي',
    'مشروع سكني',
    'مشروع تدريبي',
    'مشروع ترفيهي',
  ];

  @override
  void initState() {
    super.initState();
    // تحميل البيانات الأولية عند فتح الشاشة
    _loadInitialData();
  }

  void _loadInitialData() {
    final homeState = context.read<HomeBloc>().state;
    if (homeState is HomeLoaded) {
      _reload(homeState.institutionId);
    }
  }

  void _reload(String institutionId) {
    context.read<SponsorshipBloc>().add(
      LoadSponsorshipProjects(
        institutionId: institutionId,
        status: _filterStatus,
        type: _filterType,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة مشاريع الكفالة'),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showAnalytics,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, homeState) {
          if (homeState is HomeLoading || homeState is HomeInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (homeState is! HomeLoaded) {
            return const Center(child: Text('لا توجد بيانات متاحة'));
          }

          return BlocConsumer<SponsorshipBloc, SponsorshipState>(
            listener: (context, state) {
              if (state is SponsorshipError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
                print(state.message);
              }
              if (state is SponsorshipProjectCreated ||
                  state is SponsorshipProjectUpdated ||
                  state is SponsorshipProjectStatusChanged) {
                // إعادة تحميل البيانات بعد أي عملية ناجحة
                _reload(homeState.institutionId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت العملية بنجاح')),
                );
              }
            },
            builder: (context, state) {
              if (state is SponsorshipInitial || state is SponsorshipLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is SponsorshipError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _reload(homeState.institutionId),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }

              if (state is SponsorshipLoaded) {
                return _buildContent(homeState, state, homeState.institutionId);
              }

              return const Center(child: Text('حالة غير معروفة'));
            },
          );
        },
      ),
      floatingActionButton: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, homeState) {
          if (homeState is! HomeLoaded) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => _showCreateProjectDialog(homeState.institutionId),
            backgroundColor: AppColors.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    HomeLoaded home,
    SponsorshipLoaded state,
    String institutionId,
  ) {
    // حساب الإحصائيات من البيانات الفعلية
    final totalProjects = state.projects.length;
    final activeCount = state.projects
        .where((p) => p.status == 'active')
        .length;
    final completedCount = state.projects
        .where((p) => p.status == 'completed')
        .length;
    final totalBudget = state.projects.fold<double>(
      0,
      (sum, p) => sum + p.budget,
    );
    final totalSpent = state.projects.fold<double>(
      0,
      (sum, p) => sum + p.spent,
    );
    final totalAvailable = state.projects.fold<double>(
      0,
      (sum, p) => sum + p.available,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSponsorshipStats(
            totalProjects: totalProjects,
            activeCount: activeCount,
            completedCount: completedCount,
            totalBudget: totalBudget,
            totalSpent: totalSpent,
            totalAvailable: totalAvailable,
          ),
          const SizedBox(height: 24),
          _buildQuickActions(institutionId),
          const SizedBox(height: 24),
          _buildProjectsList(state, institutionId),
        ],
      ),
    );
  }

  Widget _buildSponsorshipStats({
    required int totalProjects,
    required int activeCount,
    required int completedCount,
    required double totalBudget,
    required double totalSpent,
    required double totalAvailable,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إحصائيات مشاريع الكفالة',
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
                    'إجمالي المشاريع',
                    '$totalProjects',
                    Icons.work,
                    AppColors.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'نشطة',
                    '$activeCount',
                    Icons.play_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'مكتملة',
                    '$completedCount',
                    Icons.check_circle,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'الميزانية',
                    '${totalBudget.toStringAsFixed(0)} شيكل',
                    Icons.account_balance_wallet,
                    AppColors.secondaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'المصروفات',
                    '${totalSpent.toStringAsFixed(0)} شيكل',
                    Icons.payments,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'المتاح',
                    '${totalAvailable.toStringAsFixed(0)} شيكل',
                    Icons.savings,
                    Colors.green,
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildQuickActions(String institutionId) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إجراءات سريعة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCreateProjectDialog(institutionId),
                    icon: const Icon(Icons.add),
                    label: const Text('مشروع جديد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showFilterDialog(institutionId),
                    icon: const Icon(Icons.filter_alt),
                    label: const Text('تصفية المشاريع'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsList(SponsorshipLoaded state, String institutionId) {
    final projects = state.projects;

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
                  'المشاريع الحالية (${projects.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _showFilterDialog(institutionId),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'البحث في المشاريع',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.clear),
              ),
              onChanged: (_) => _reload(institutionId),
            ),
            const SizedBox(height: 16),
            if (projects.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.work_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد مشاريع كفالة',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      'انقر على زر + لإنشاء مشروع جديد',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            if (projects.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return _buildProjectCard(project);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(SponsorshipProject project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(project.status),
          child: const Icon(Icons.work, color: Colors.white),
        ),
        title: Text(
          project.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('النوع: ${project.type}'),
            Text('الحالة: ${_statusLabel(project.status)}'),
            Text('الميزانية: ${project.budget.toStringAsFixed(0)} شيكل'),
            Text('المصروف: ${project.spent.toStringAsFixed(0)} شيكل'),
            Text('المتاح: ${project.available.toStringAsFixed(0)} شيكل'),
            const SizedBox(height: 4),
            Text(
              'أنشئ في: ${_formatDate(project.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleProjectAction(value, project),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [Icon(Icons.edit), SizedBox(width: 8), Text('تعديل')],
              ),
            ),
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('عرض التفاصيل'),
                ],
              ),
            ),
            PopupMenuItem(
              value: project.status == 'archived' ? 'activate' : 'archive',
              child: Row(
                children: [
                  Icon(
                    project.status == 'archived'
                        ? Icons.unarchive
                        : Icons.archive,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    project.status == 'archived' ? 'إلغاء الأرشفة' : 'أرشفة',
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showProjectDetails(project),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'pending':
        return 'معلق';
      case 'completed':
        return 'مكتمل';
      case 'archived':
        return 'مؤرشف';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleProjectAction(String action, SponsorshipProject project) {
    switch (action) {
      case 'edit':
        _showEditProjectDialog(project);
        break;
      case 'view':
        _showProjectDetails(project);
        break;
      case 'archive':
        _changeProjectStatus(project.id, 'archived');
        break;
      case 'activate':
        _changeProjectStatus(project.id, 'active');
        break;
    }
  }

  void _changeProjectStatus(String projectId, String status) {
    context.read<SponsorshipBloc>().add(
      ChangeProjectStatusEvent(projectId: projectId, status: status),
    );
  }

  // ===== Dialogs =====

  void _showCreateProjectDialog(String institutionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنشاء مشروع كفالة جديد'),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _projectNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المشروع',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'يرجى إدخال اسم المشروع'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedProjectType,
                  decoration: const InputDecoration(
                    labelText: 'نوع المشروع',
                    border: OutlineInputBorder(),
                  ),
                  items: _projectTypes
                      .map(
                        (t) =>
                            DropdownMenuItem<String>(value: t, child: Text(t)),
                      )
                      .toList(),
                  onChanged: (val) => setState(
                    () => _selectedProjectType = val ?? _selectedProjectType,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'وصف المشروع',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _budgetController,
                  decoration: const InputDecoration(
                    labelText: 'الميزانية (ريال)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'أدخل الميزانية';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return 'أدخل رقمًا صحيحًا';
                    return null;
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
              if (!_formKey.currentState!.validate()) return;

              final project = SponsorshipProject(
                id: '', // يتم توليده في الخدمة
                institutionId: institutionId,
                name: _projectNameController.text.trim(),
                type: _selectedProjectType,
                description: _descriptionController.text.trim(),
                budget: double.parse(_budgetController.text.trim()),
                spent: 0,
                status: 'active',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              context.read<SponsorshipBloc>().add(
                CreateSponsorshipProjectEvent(project),
              );
              Navigator.pop(context);
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }

  void _showEditProjectDialog(SponsorshipProject project) {
    final nameController = TextEditingController(text: project.name);
    final descController = TextEditingController(text: project.description);
    final budgetController = TextEditingController(
      text: project.budget.toStringAsFixed(0),
    );
    String selectedType = project.type;
    String selectedStatus = project.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل المشروع'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المشروع',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                items: _projectTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => selectedType = v ?? selectedType,
                decoration: const InputDecoration(
                  labelText: 'نوع المشروع',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'الوصف',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الميزانية',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('نشط')),
                  DropdownMenuItem(value: 'pending', child: Text('معلق')),
                  DropdownMenuItem(value: 'completed', child: Text('مكتمل')),
                  DropdownMenuItem(value: 'archived', child: Text('مؤرشف')),
                ],
                onChanged: (v) => selectedStatus = v ?? selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'الحالة',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedProject = project.copyWith(
                name: nameController.text.trim(),
                type: selectedType,
                description: descController.text.trim(),
                budget:
                    double.tryParse(budgetController.text.trim()) ??
                    project.budget,
                status: selectedStatus,
                updatedAt: DateTime.now(),
              );
              context.read<SponsorshipBloc>().add(
                UpdateSponsorshipProjectEvent(updatedProject),
              );
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showProjectDetails(SponsorshipProject project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(project.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('النوع', project.type),
              _buildDetailRow('الوصف', project.description),
              _buildDetailRow('الحالة', _statusLabel(project.status)),
              _buildDetailRow(
                'الميزانية',
                '${project.budget.toStringAsFixed(0)} شيكل',
              ),
              _buildDetailRow(
                'المصروف',
                '${project.spent.toStringAsFixed(0)} شيكل',
              ),
              _buildDetailRow(
                'المتاح',
                '${project.available.toStringAsFixed(0)} شيكل',
              ),
              _buildDetailRow('تاريخ الإنشاء', _formatDate(project.createdAt)),
              _buildDetailRow('آخر تحديث', _formatDate(project.updatedAt)),
              const SizedBox(height: 16),
              const Text(
                'لإضافة الأحداث والسجلات، سيتم تطويره لاحقًا',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showFilterDialog(String institutionId) {
    String? selectedStatus = _filterStatus;
    String? selectedType = _filterType;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفية المشاريع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedStatus,
              items: const [
                DropdownMenuItem(value: null, child: Text('جميع الحالات')),
                DropdownMenuItem(value: 'active', child: Text('نشط')),
                DropdownMenuItem(value: 'pending', child: Text('معلق')),
                DropdownMenuItem(value: 'completed', child: Text('مكتمل')),
                DropdownMenuItem(value: 'archived', child: Text('مؤرشف')),
              ],
              onChanged: (v) => selectedStatus = v,
              decoration: const InputDecoration(
                labelText: 'الحالة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedType,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('جميع الأنواع'),
                ),
                ..._projectTypes.map(
                  (t) => DropdownMenuItem(value: t, child: Text(t)),
                ),
              ],
              onChanged: (v) => selectedType = v,
              decoration: const InputDecoration(
                labelText: 'النوع',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterStatus = null;
                _filterType = null;
              });
              Navigator.pop(context);
              _reload(institutionId);
            },
            child: const Text('إعادة التعيين'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _filterStatus = selectedStatus;
                _filterType = selectedType;
              });
              Navigator.pop(context);
              _reload(institutionId);
            },
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  void _showAnalytics() {
    // هذا سيتطلب تطويرًا إضافيًا لربطها بتحليلات حقيقية
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحليلات مشاريع الكفالة'),
        content: const SizedBox(
          width: double.maxFinite,
          height: 200,
          child: Column(
            children: [
              Icon(Icons.analytics, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'سيتم تطوير لوحة التحليلات في المرحلة القادمة',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'ستعرض رسوم بيانية للإحصائيات والأداء',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
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
