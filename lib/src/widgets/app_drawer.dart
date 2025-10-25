import 'package:e_kafel/src/screens/supervisors/supervisors_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/screens/profile/profile_screen.dart';
import 'package:e_kafel/src/screens/orphans/orphans_list_screen.dart';
import 'package:e_kafel/src/screens/orphans/add_new_orphan_screen.dart';
import 'package:e_kafel/src/screens/sponsorship/sponsorship_management_screen.dart';
import 'package:e_kafel/src/screens/reports/reports_screen.dart';
import 'package:e_kafel/src/screens/settings/settings_screen.dart';
import 'package:e_kafel/src/screens/tasks/tasks_screen.dart';
import 'package:e_kafel/src/screens/visits/field_visits_screen.dart';
import 'package:e_kafel/src/screens/sms/send_sms_screen.dart';
import '../screens/Home/home_screen.dart';
import '../utils/app_colors.dart';
import '../blocs/settings/settings_bloc.dart';

class AppDrawer extends StatelessWidget {
  final String userName;
  final String userRole;
  final String profileImageUrl;
  final int orphanCount;
  final int taskCount;
  final int visitCount;
  final VoidCallback onLogout;
  final String institutionId;
  final String kafalaHeadId;

  const AppDrawer({
    super.key,
    required this.userName,
    required this.userRole,
    required this.profileImageUrl,
    required this.orphanCount,
    required this.taskCount,
    required this.visitCount,
    required this.onLogout,
    required this.institutionId,
    required this.kafalaHeadId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        // الحصول على إعدادات الوضع المظلم من الحالة
        final isDarkMode = _getDarkMode(state);

        final backgroundColor = isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.white;
        final textColor = isDarkMode ? Colors.white : AppColors.textColor;
        final iconColor = isDarkMode
            ? AppColors.accentGreen
            : AppColors.primaryColor;
        final dividerColor = isDarkMode ? Colors.white24 : Colors.grey.shade300;
        final headerColor = isDarkMode
            ? const Color(0xFF2D2D2D)
            : AppColors.primaryColor;
        final statBgColor = isDarkMode
            ? AppColors.accentGreen
            : AppColors.primaryColor;
        final statTextColor = isDarkMode ? AppColors.textColor : Colors.white;

        return Drawer(
          backgroundColor: backgroundColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(
                  userRole == 'kafala_head' ? 'رئيس قسم الكفالة' : 'مشرف',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl.isEmpty
                      ? Icon(Icons.person, color: AppColors.primaryColor)
                      : null,
                ),
                decoration: BoxDecoration(
                  color: headerColor,
                  gradient: isDarkMode
                      ? LinearGradient(
                          colors: [
                            const Color(0xFF2D2D2D),
                            AppColors.accentGreen.withOpacity(0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            AppColors.primaryColor,
                            AppColors.secondaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                ),
              ),

              // الصفحة الشخصية
              _buildDrawerItem(
                icon: Icons.account_circle,
                title: 'الصفحة الشخصية',
                color: iconColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                textColor: textColor,
              ),

              Divider(color: dividerColor, height: 1),

              // الشاشة الرئيسية
              _buildDrawerItem(
                icon: Icons.home,
                title: 'الشاشة الرئيسية',
                color: iconColor,
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const HomeScreen()));
                },
                textColor: textColor,
              ),

              // الإحصائيات
              _buildStatItem(
                'الأيتام',
                orphanCount,
                Icons.people,
                statBgColor,
                statTextColor,
              ),
              _buildStatItem(
                'المهام',
                taskCount,
                Icons.task,
                statBgColor,
                statTextColor,
              ),
              _buildStatItem(
                'الزيارات',
                visitCount,
                Icons.assignment_turned_in,
                statBgColor,
                statTextColor,
              ),

              Divider(color: dividerColor, height: 1),

              // إضافة يتيم
              _buildDrawerItem(
                icon: Icons.person_add,
                title: 'إضافة يتيم',
                color: iconColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddNewOrphanScreen(
                        institutionId: institutionId,
                        kafalaHeadId: kafalaHeadId,
                      ),
                    ),
                  );
                },
                textColor: textColor,
              ),

              // قائمة الأيتام
              _buildDrawerItem(
                icon: Icons.people,
                title: 'قائمة الأيتام',
                color: iconColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OrphansListScreen(),
                    ),
                  );
                },
                textColor: textColor,
              ),

              // قائمة المشرفين
              _buildDrawerItem(
                icon: Icons.supervisor_account,
                title: 'قائمة المشرفين',
                color: iconColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SupervisorsScreen(
                        institutionId: institutionId,
                        kafalaHeadId: kafalaHeadId,
                        isActive: true,
                      ),
                    ),
                  );
                },
                textColor: textColor,
              ),

              // المهام
              _buildDrawerItem(
                icon: Icons.task,
                title: 'المهام',
                color: iconColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TasksScreen()),
                  );
                },
                textColor: textColor,
              ),

              // الزيارات الميدانية
              _buildDrawerItem(
                icon: Icons.assignment,
                title: 'الزيارات الميدانية',
                color: iconColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FieldVisitsScreen(),
                    ),
                  );
                },
                textColor: textColor,
              ),

              // إدارة الكفالات
              _buildDrawerItem(
                icon: Icons.attach_money,
                title: 'إدارة الكفالات',
                color: iconColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SponsorshipManagementScreen(),
                    ),
                  );
                },
                textColor: textColor,
              ),

              // إرسال رسالة
              _buildDrawerItem(
                icon: Icons.message,
                title: 'إرسال رسالة',
                color: iconColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SendSMSScreen(recipientNumber: ''),
                    ),
                  );
                },
                textColor: textColor,
              ),

              // التقارير
              _buildDrawerItem(
                icon: Icons.article,
                title: 'التقارير',
                color: iconColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReportsScreen()),
                  );
                },
                textColor: textColor,
              ),

              Divider(color: dividerColor, height: 1),

              // الإعدادات
              _buildDrawerItem(
                icon: Icons.settings,
                title: 'الإعدادات',
                color: iconColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                textColor: textColor,
              ),

              // تسجيل الخروج
              _buildDrawerItem(
                icon: Icons.logout,
                title: 'تسجيل الخروج',
                color: AppColors.errorColor,
                onTap: onLogout,
                textColor: AppColors.errorColor,
              ),
            ],
          ),
        );
      },
    );
  }

  bool _getDarkMode(SettingsState state) {
    if (state is SettingsLoaded) {
      return state.settings.isDarkMode;
    } else if (state is SettingsUpdated) {
      return state.settings.isDarkMode;
    } else if (state is SettingsUpdating) {
      return state.settings.isDarkMode;
    }
    return false; // القيمة الافتراضية
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildStatItem(
    String title,
    int count,
    IconData icon,
    Color bgColor,
    Color textColor,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryColor),
      title: Text(title, style: TextStyle(color: bgColor, fontSize: 14)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          count.toString(),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
