import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/themes/app_colors.dart';
import 'package:e_kafel/src/widgets/app_drawer.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'login_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير والإحصائيات'),
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
            return _buildReportsContent(context, state);
          }

          return const Center(child: Text('لا توجد بيانات متاحة'));
        },
      ),
    );
  }

  Widget _buildReportsContent(BuildContext context, HomeLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // إحصائيات سريعة
          _buildQuickStats(state),
          const SizedBox(height: 24),

          // تقارير مفصلة
          _buildDetailedReports(),
          const SizedBox(height: 24),

          // تقارير مخصصة
          _buildCustomReports(),
        ],
      ),
    );
  }

  Widget _buildQuickStats(HomeLoaded state) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إحصائيات سريعة',
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
                    'إجمالي الأيتام',
                    state.orphanSponsored.toString(),
                    Icons.child_care,
                    AppColors.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'المكفولين',
                    '${(state.orphanSponsored * 0.8).round()}',
                    Icons.verified_user,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'في انتظار الكفالة',
                    '${(state.orphanSponsored * 0.2).round()}',
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

  Widget _buildDetailedReports() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تقارير مفصلة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildReportItem(
              'تقرير توزيع الأيتام حسب المحافظة',
              Icons.location_on,
              () => _showGovernorateReport(),
            ),
            _buildReportItem(
              'تقرير الكفالة المالية',
              Icons.attach_money,
              () => _showFinancialReport(),
            ),
            _buildReportItem(
              'تقرير الكفالة العينية',
              Icons.inventory,
              () => _showInKindReport(),
            ),
            _buildReportItem(
              'تقرير الزيارات الميدانية',
              Icons.visibility,
              () => _showFieldVisitsReport(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  Widget _buildCustomReports() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تقارير مخصصة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createCustomReport,
              icon: const Icon(Icons.add),
              label: const Text('إنشاء تقرير مخصص'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGovernorateReport() {
    // عرض تقرير توزيع الأيتام حسب المحافظة
  }

  void _showFinancialReport() {
    // عرض تقرير الكفالة المالية
  }

  void _showInKindReport() {
    // عرض تقرير الكفالة العينية
  }

  void _showFieldVisitsReport() {
    // عرض تقرير الزيارات الميدانية
  }

  void _createCustomReport() {
    // إنشاء تقرير مخصص
  }
}
