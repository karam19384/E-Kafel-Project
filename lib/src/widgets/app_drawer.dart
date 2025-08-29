import 'package:flutter/material.dart';
import 'package:e_kafel/src/screens/profile_screen.dart';
import 'package:e_kafel/src/screens/orphans_list_screen.dart';
import 'package:e_kafel/src/screens/add_new_orphan_screen.dart';
import 'package:e_kafel/src/screens/sponsorship_management_screen.dart';
import 'package:e_kafel/src/screens/reports_screen.dart';
import 'package:e_kafel/src/screens/settings_screen.dart';
import 'package:e_kafel/src/screens/tasks_screen.dart';
import 'package:e_kafel/src/screens/field_visits_screen.dart';
import 'package:e_kafel/src/screens/send_sms_screen.dart';
import '../screens/home_screen.dart';

class AppDrawer extends StatelessWidget {
  final String userName;
  final String userRole;
  final String? profileImageUrl;
  final int orphanCount;
  final int taskCount;
  final int visitCount;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.userName,
    required this.userRole,
    this.profileImageUrl,
    required this.orphanCount,
    required this.taskCount,
    required this.visitCount,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _buildDrawerHeader(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          _buildDrawerItem(
            icon: Icons.person_outline,
            text: 'My Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          _buildDrawerItem(
            icon: Icons.home,
            text: 'Home',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.groups,
            text: 'Sponsorship Managment',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const SponsorshipManagementScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.sms,
            text: 'Send SMS',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SendSMSScreen()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.list_alt,
            text: 'Orphans List',
            trailingWidget: _buildBadge(orphanCount),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrphansListScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.person_add_alt_1,
            text: 'Add new Orphan',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddNewOrphanScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.person_add,
            text: 'Add new Supervisor',
            onTap: () {}, // أضف التنقل لاحقًا
          ),
          _buildDrawerItem(
            icon: Icons.assignment,
            text: 'Tasks',
            trailingWidget: _buildBadge(taskCount),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const TasksScreen()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.map,
            text: 'Field Visits',
            trailingWidget: _buildBadge(visitCount),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const FieldVisitsScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.menu_book,
            text: 'Reports',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ReportsScreen()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            text: 'Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          _buildDrawerItem(
            icon: Icons.logout,
            text: 'Logout',
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
            textColor: Colors.red,
            iconColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      color: const Color(0xBFD0DFDF),
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFFF8BBD0), width: 4),
            ),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              backgroundImage:
                  profileImageUrl != null && profileImageUrl!.isNotEmpty
                  ? NetworkImage(profileImageUrl!)
                  : null,
              child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 54, color: Colors.black54)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            userName,
            style: const TextStyle(
              color: Color(0xFF4C7F7F),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Arial',
            ),
          ),
        ],
      ),
    );
  }

  // تم حذف التكرار: تعريف واحد فقط لكل من _buildDrawerItem و _buildBadge موجود أعلاه

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Widget? trailingWidget,
    Color textColor = Colors.black,
    Color iconColor = Colors.black,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        text,
        style: TextStyle(fontSize: 16, color: textColor, fontFamily: 'Arial'),
      ),
      trailing: trailingWidget,
      onTap: onTap,
      dense: true,
      horizontalTitleGap: 0,
      minLeadingWidth: 32,
    );
  }

  // تم حذف التكرار: تعريف واحد فقط لدالة _buildBadge موجود أعلاه

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
