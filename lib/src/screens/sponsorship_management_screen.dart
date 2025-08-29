import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/themes/app_colors.dart';
import 'package:e_kafel/src/widgets/app_drawer.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';

import 'login_screen.dart';

class SponsorshipManagementScreen extends StatefulWidget {
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

  final List<String> _projectTypes = [
    'مشروع كفالة',
    'مشروع تعليمي',
    'مشروع صحي',
    'مشروع سكني',
    'مشروع تدريبي',
    'مشروع ترفيهي',
  ];

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
        title: const Text('إدارة الكفالة'),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showAnalytics,
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
            return _buildSponsorshipContent(context, state);
          }

          return const Center(child: Text('لا توجد بيانات متاحة'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateProjectDialog,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSponsorshipContent(BuildContext context, HomeState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // إحصائيات الكفالة
          _buildSponsorshipStats(state),
          const SizedBox(height: 24),

          // أزرار الإجراءات السريعة
          _buildQuickActions(),
          const SizedBox(height: 24),

          // قائمة المشاريع
          _buildProjectsList(),
        ],
      ),
    );
  }

  Widget _buildSponsorshipStats(HomeState state) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إحصائيات الكفالة',
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
                    '25',
                    Icons.work,
                    AppColors.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'مشاريع نشطة',
                    '18',
                    Icons.play_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'مشاريع مكتملة',
                    '7',
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
                    'إجمالي الميزانية',
                    '150,000 ريال',
                    Icons.account_balance_wallet,
                    AppColors.secondaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'مصروفات',
                    '120,000 ريال',
                    Icons.payments,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'متاح',
                    '30,000 ريال',
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
            fontSize: 16,
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

  Widget _buildQuickActions() {
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
                    onPressed: _showCreateProjectDialog,
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
                    onPressed: _showManageCareTypes,
                    icon: const Icon(Icons.category),
                    label: const Text('أنواع الرعاية'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showChangeStatus,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('تغيير الحالة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAuditTrail,
                    icon: const Icon(Icons.history),
                    label: const Text('سجل التغييرات'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
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

  Widget _buildProjectsList() {
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
                  'المشاريع الحالية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // حقل البحث
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'البحث في المشاريع',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                // تطبيق البحث
              },
            ),
            const SizedBox(height: 16),

            // قائمة المشاريع
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5, // عدد المشاريع
              itemBuilder: (context, index) {
                return _buildProjectCard(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(int index) {
    final projectNames = [
      'مشروع كفالة الأيتام 2025',
      'مشروع التعليم المستمر',
      'مشروع الرعاية الصحية',
      'مشروع السكن الآمن',
      'مشروع التدريب المهني',
    ];

    final projectStatuses = [
      'نشط',
      'معلق',
      'مكتمل',
      'في انتظار الموافقة',
      'نشط',
    ];
    final projectBudgets = ['50,000', '30,000', '25,000', '20,000', '15,000'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(projectStatuses[index]),
          child: Icon(_getProjectIcon(index), color: Colors.white),
        ),
        title: Text(projectNames[index]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الميزانية: ${projectBudgets[index]} ريال'),
            Text('الحالة: ${projectStatuses[index]}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleProjectAction(value, index),
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
                  Text('عرض'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(Icons.archive),
                  SizedBox(width: 8),
                  Text('أرشفة'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'نشط':
        return Colors.green;
      case 'معلق':
        return Colors.orange;
      case 'مكتمل':
        return Colors.blue;
      case 'في انتظار الموافقة':
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
    }
  }

  IconData _getProjectIcon(int index) {
    switch (index) {
      case 0:
        return Icons.child_care;
      case 1:
        return Icons.school;
      case 2:
        return Icons.medical_services;
      case 3:
        return Icons.home;
      case 4:
        return Icons.work;
      default:
        return Icons.work;
    }
  }

  void _handleProjectAction(String action, int index) {
    switch (action) {
      case 'edit':
        _showEditProjectDialog(index);
        break;
      case 'view':
        _showProjectDetails(index);
        break;
      case 'archive':
        _archiveProject(index);
        break;
    }
  }

  void _showCreateProjectDialog() {
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال اسم المشروع';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedProjectType,
                  decoration: const InputDecoration(
                    labelText: 'نوع المشروع',
                    border: OutlineInputBorder(),
                  ),
                  items: _projectTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedProjectType = newValue!;
                    });
                  },
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
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // إنشاء المشروع
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إنشاء المشروع بنجاح!'),
                    backgroundColor: Colors.green,
                  ),
                );
                _projectNameController.clear();
                _descriptionController.clear();
                _budgetController.clear();
              }
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }

  void _showEditProjectDialog(int index) {
    // عرض نافذة تعديل المشروع
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('تعديل المشروع رقم ${index + 1}')));
  }

  void _showProjectDetails(int index) {
    // عرض تفاصيل المشروع
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('عرض تفاصيل المشروع رقم ${index + 1}')),
    );
  }

  void _archiveProject(int index) {
    // أرشفة المشروع
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('أرشفة المشروع'),
        content: Text('هل أنت متأكد من أرشفة المشروع رقم ${index + 1}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم أرشفة المشروع رقم ${index + 1}')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('أرشفة'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفية المشاريع'),
        content: const Text('هنا يمكنك إضافة خيارات التصفية'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحليلات الكفالة'),
        content: const SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              Text('هنا سيتم عرض التحليلات والإحصائيات'),
              SizedBox(height: 16),
              Text('يمكن إضافة:'),
              Text('• رسوم بيانية للمشاريع'),
              Text('• توزيع الميزانيات'),
              Text('• معدلات الإنجاز'),
              Text('• مؤشرات الأداء'),
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

  void _showManageCareTypes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إدارة أنواع الرعاية'),
        content: const Text('هنا يمكنك إضافة وتعديل وحذف أنواع الرعاية'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showChangeStatus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير حالة الكفالة'),
        content: const Text('هنا يمكنك تغيير حالة كفالة الأيتام'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showAuditTrail() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سجل التغييرات'),
        content: const Text('هنا سيتم عرض سجل جميع التغييرات في المشاريع'),
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
