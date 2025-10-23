import 'package:e_kafel/src/screens/supervisors/supervisors_screen.dart';
import 'package:flutter/material.dart';
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

// في app_drawer.dart - النسخة النهائية
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
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userName),
            accountEmail: Text(
              userRole == 'kafala_head' ? 'رئيس قسم الكفالة' : 'مشرف',
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl)
                  : null,
              child: profileImageUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            decoration: const BoxDecoration(color: Color(0xFF6DAF97)),
          ),

          ListTile(
            leading: const Icon(Icons.account_circle, color: Color(0xFF6DAF97)),
            title: const Text('الصفحة الشخصية'),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.home, color: Color(0xFF6DAF97)),
            title: const Text('الشاشة الرئيسية'),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const HomeScreen()));
            },
          ),
          // إحصائيات سريعة
          _buildStatItem('الأيتام', orphanCount, Icons.people),
          _buildStatItem('المهام', taskCount, Icons.task),
          _buildStatItem('الزيارات', visitCount, Icons.assignment_turned_in),

          const Divider(),

          // إضافة يتيم
          ListTile(
            leading: const Icon(Icons.person_add, color: Color(0xFF6DAF97)),
            title: const Text('إضافة يتيم'),
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
          ),

          // قائمة الأيتام
          ListTile(
            leading: const Icon(Icons.people, color: Color(0xFF6DAF97)),
            title: const Text('قائمة الأيتام'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrphansListScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.task, color: Color(0xFF6DAF97)),
            title: const Text('قائمة المشرفين'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SupervisorsScreen(
                    institutionId: '',
                    kafalaHeadId: '',
                    isActive: true,
                  ),
                ),
              );
            },
          ),

          // المهام
          ListTile(
            leading: const Icon(Icons.task, color: Color(0xFF6DAF97)),
            title: const Text('المهام'),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const TasksScreen()));
            },
          ),

          // الزيارات الميدانية
          ListTile(
            leading: const Icon(Icons.assignment, color: Color(0xFF6DAF97)),
            title: const Text('الزيارات الميدانية'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FieldVisitsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.task, color: Color(0xFF6DAF97)),
            title: const Text('إدارة الكفالات'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SponsorshipManagementScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.task, color: Color(0xFF6DAF97)),
            title: const Text('إرسال رسالة'),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SendSMSScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.article, color: Color(0xFF6DAF97)),
            title: const Text('التقارير'),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
            },
          ),

          const Divider(),

          // الإعدادات
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text('الإعدادات'),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),

          // تسجيل الخروج
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('تسجيل الخروج'),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, int count, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6DAF97)),
      title: Text(title),
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6DAF97),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
