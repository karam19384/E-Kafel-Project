import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'package:e_kafel/src/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _autoSyncEnabled = true;
  bool _biometricEnabled = false;
  String _language = 'العربية';
  String _syncFrequency = 'كل 15 دقيقة';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: const Color(0xFF6DAF97),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // قسم المظهر
            _buildSectionHeader('المظهر والواجهة'),
            _buildSettingTile(
              icon: Icons.dark_mode,
              title: 'الوضع الليلي',
              subtitle: 'تفعيل المظهر الداكن',
              trailing: Switch(
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.language,
              title: 'اللغة',
              subtitle: _language,
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showLanguageDialog(),
            ),

            const SizedBox(height: 24),

            // قسم الإشعارات
            _buildSectionHeader('الإشعارات والتنبيهات'),
            _buildSettingTile(
              icon: Icons.notifications,
              title: 'تفعيل الإشعارات',
              subtitle: 'استلام تنبيهات التطبيق',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.schedule,
              title: 'توقيت الإشعارات',
              subtitle: 'من 8:00 ص إلى 8:00 م',
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showNotificationTimeDialog(),
            ),

            const SizedBox(height: 24),

            // قسم المزامنة
            _buildSectionHeader('المزامنة والبيانات'),
            _buildSettingTile(
              icon: Icons.sync,
              title: 'المزامنة التلقائية',
              subtitle: 'مزامنة البيانات مع الخادم',
              trailing: Switch(
                value: _autoSyncEnabled,
                onChanged: (value) {
                  setState(() {
                    _autoSyncEnabled = value;
                  });
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.timer,
              title: 'تكرار المزامنة',
              subtitle: _syncFrequency,
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showSyncFrequencyDialog(),
            ),
            _buildSettingTile(
              icon: Icons.backup,
              title: 'النسخ الاحتياطي',
              subtitle: 'تصدير البيانات كملف Excel',
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _exportData(),
            ),

            const SizedBox(height: 24),

            // قسم الأمان
            _buildSectionHeader('الأمان والخصوصية'),
            _buildSettingTile(
              icon: Icons.fingerprint,
              title: 'تسجيل الدخول بالبصمة',
              subtitle: 'استخدام البصمة للمصادقة',
              trailing: Switch(
                value: _biometricEnabled,
                onChanged: (value) {
                  setState(() {
                    _biometricEnabled = value;
                  });
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.lock,
              title: 'تغيير كلمة المرور',
              subtitle: 'تحديث كلمة المرور الحالية',
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _changePassword(),
            ),

            const SizedBox(height: 24),

            // قسم الحساب
            _buildSectionHeader('الحساب'),
            _buildSettingTile(
              icon: Icons.person,
              title: 'معلومات الحساب',
              subtitle: 'تعديل البيانات الشخصية',
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _editProfile(),
            ),
            _buildSettingTile(
              icon: Icons.logout,
              title: 'تسجيل الخروج',
              subtitle: 'الخروج من التطبيق',
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _logout(context),
            ),

            const SizedBox(height: 24),

            // قسم حول التطبيق
            _buildSectionHeader('حول التطبيق'),
            _buildSettingTile(
              icon: Icons.info,
              title: 'إصدار التطبيق',
              subtitle: '1.0.0',
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showAppInfo(),
            ),
            _buildSettingTile(
              icon: Icons.help,
              title: 'المساعدة والدعم',
              subtitle: 'دليل الاستخدام',
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showHelp(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6DAF97),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF6DAF97)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  // دوال الإعدادات
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختيار اللغة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('العربية'),
              onTap: () {
                setState(() {
                  _language = 'العربية';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('English'),
              onTap: () {
                setState(() {
                  _language = 'English';
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationTimeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('توقيت الإشعارات'),
        content: const Text('يمكنك تحديد توقيت الإشعارات من هنا'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showSyncFrequencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تكرار المزامنة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('كل 15 دقيقة'),
              onTap: () {
                setState(() {
                  _syncFrequency = 'كل 15 دقيقة';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('كل ساعة'),
              onTap: () {
                setState(() {
                  _syncFrequency = 'كل ساعة';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('يومياً'),
              onTap: () {
                setState(() {
                  _syncFrequency = 'يومياً';
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('جاري تصدير البيانات...')));
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: const Text(
          'سيتم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إرسال رابط إعادة التعيين')),
              );
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم فتح صفحة تعديل الملف الشخصي')),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(LogoutButtonPressed());
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('معلومات التطبيق'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اسم التطبيق: e-Kafel'),
            Text('الإصدار: 1.0.0'),
            Text('المطور: فريق التطوير'),
            Text('السنة: 2025'),
          ],
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

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('المساعدة والدعم'),
        content: const Text('يمكنك التواصل مع فريق الدعم للحصول على المساعدة'),
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
