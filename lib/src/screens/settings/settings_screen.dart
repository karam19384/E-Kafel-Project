import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'package:e_kafel/src/blocs/settings/settings_bloc.dart';
import 'package:e_kafel/src/models/setting_model.dart';
import 'package:e_kafel/src/screens/Auth/login_screen.dart';
import 'package:e_kafel/src/screens/settings/email_verification_screen.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings_screen';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkEmailLinkStatus();
  }

  void _loadSettings() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<SettingsBloc>().add(LoadSettings(authState.userData['uid']));
    }
  }

  void _checkEmailLinkStatus() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<AuthBloc>().add(const CheckEmailLinkStatus());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState is AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات'),
          backgroundColor: const Color(0xFF6DAF97),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                final isLoading = state is SettingsUpdating;
                return IconButton(
                  icon: const Icon(Icons.restore, color: Colors.white),
                  onPressed: isLoading ? null : () => _resetSettings(context),
                  tooltip: 'إعادة التعيين',
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<SettingsBloc, SettingsState>(
          listener: (context, state) {
            if (state is SettingsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is SettingsLoading || state is SettingsInitial) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري تحميل الإعدادات...'),
                  ],
                ),
              );
            }

            if (state is SettingsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6DAF97),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }

            // الحصول على الإعدادات الحالية من أي حالة
            final SettingsModel settings = _getCurrentSettings(state);
            final bool isLoading = state is SettingsUpdating;

            return Stack(
              children: [
                _buildSettingsContent(settings, isLoading, context),
                if (isLoading)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'جاري الحفظ...',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  SettingsModel _getCurrentSettings(SettingsState state) {
    if (state is SettingsLoaded) return state.settings;
    if (state is SettingsUpdated) return state.settings;
    if (state is SettingsUpdating) return state.settings;
    return SettingsModel.defaultSettings;
  }

  Widget _buildSettingsContent(SettingsModel settings, bool isLoading, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // قسم المظهر والواجهة
          _buildSectionHeader('المظهر والواجهة'),
          _buildSettingTile(
            icon: Icons.dark_mode,
            title: 'الوضع الليلي',
            subtitle: 'تفعيل المظهر الداكن',
            trailing: Switch(
              value: settings.isDarkMode,
              onChanged: isLoading ? null : (value) => _toggleSetting(context, 'isDarkMode', value),
            ),
          ),
          _buildSettingTile(
            icon: Icons.language,
            title: 'اللغة',
            subtitle: settings.language,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: isLoading ? null : () => _showLanguageDialog(context, settings),
          ),
          _buildSettingTile(
            icon: Icons.format_size,
            title: 'حجم الخط',
            subtitle: settings.fontSize,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: isLoading ? null : () => _showFontSizeDialog(context, settings),
          ),
          _buildSettingTile(
            icon: Icons.palette,
            title: 'لون الثيم',
            subtitle: settings.themeColor,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: isLoading ? null : () => _showThemeColorDialog(context, settings),
          ),

          const SizedBox(height: 24),

          // قسم الإشعارات والتنبيهات
          _buildSectionHeader('الإشعارات والتنبيهات'),
          _buildSettingTile(
            icon: Icons.notifications,
            title: 'تفعيل الإشعارات',
            subtitle: 'استلام تنبيهات التطبيق',
            trailing: Switch(
              value: settings.notificationsEnabled,
              onChanged: isLoading ? null : (value) => _toggleSetting(context, 'notificationsEnabled', value),
            ),
          ),
          _buildSettingTile(
            icon: Icons.vibration,
            title: 'تفعيل الاهتزاز',
            subtitle: 'الاهتزاز عند التنبيه',
            trailing: Switch(
              value: settings.vibrationEnabled,
              onChanged: isLoading ? null : (value) => _toggleSetting(context, 'vibrationEnabled', value),
            ),
          ),

          const SizedBox(height: 24),

          // قسم المزامنة والبيانات
          _buildSectionHeader('المزامنة والبيانات'),
          _buildSettingTile(
            icon: Icons.sync,
            title: 'المزامنة التلقائية',
            subtitle: 'مزامنة البيانات مع الخادم',
            trailing: Switch(
              value: settings.autoSyncEnabled,
              onChanged: isLoading ? null : (value) => _toggleSetting(context, 'autoSyncEnabled', value),
            ),
          ),
          _buildSettingTile(
            icon: Icons.timer,
            title: 'تكرار المزامنة',
            subtitle: settings.syncFrequency,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: isLoading ? null : () => _showSyncFrequencyDialog(context, settings),
          ),
          _buildSettingTile(
            icon: Icons.signal_wifi_off,
            title: 'وضع عدم الاتصال',
            subtitle: 'استخدام التطبيق بدون اتصال',
            trailing: Switch(
              value: settings.offlineMode,
              onChanged: isLoading ? null : (value) => _toggleSetting(context, 'offlineMode', value),
            ),
          ),
          _buildSettingTile(
            icon: Icons.data_saver_off,
            title: 'توفير البيانات',
            subtitle: 'تقليل استهلاك البيانات',
            trailing: Switch(
              value: settings.dataSaver,
              onChanged: isLoading ? null : (value) => _toggleSetting(context, 'dataSaver', value),
            ),
          ),
          _buildSettingTile(
            icon: Icons.backup,
            title: 'النسخ الاحتياطي',
            subtitle: 'تصدير البيانات كملف Excel',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: isLoading ? null : () => _showExportDataDialog(context),
          ),

          const SizedBox(height: 24),

          // قسم الأمان والخصوصية
          _buildSectionHeader('الأمان والخصوصية'),
          _buildSettingTile(
            icon: Icons.fingerprint,
            title: 'المصادقة البيومترية',
            subtitle: 'استخدام البصمة للمصادقة',
            trailing: Switch(
              value: settings.biometricEnabled,
              onChanged: isLoading ? null : (value) => _toggleSetting(context, 'biometricEnabled', value),
            ),
          ),
          _buildSettingTile(
            icon: Icons.visibility_off,
            title: 'إخفاء البيانات الحساسة',
            subtitle: 'إخفاء المعلومات المهمة',
            trailing: Switch(
              value: settings.hideSensitiveData,
              onChanged: isLoading ? null : (value) => _toggleSetting(context, 'hideSensitiveData', value),
            ),
          ),
          _buildSettingTile(
            icon: Icons.lock,
            title: 'تغيير كلمة المرور',
            subtitle: 'تحديث كلمة المرور الحالية',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: isLoading ? null : () => _changePassword(context),
          ),

          const SizedBox(height: 24),

          // قسم ربط البريد الإلكتروني
          _buildSectionHeader('ربط البريد الإلكتروني'),
          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, authState) {
              if (authState is EmailVerified) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم ربط البريد الإلكتروني بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
                _checkEmailLinkStatus();
              } else if (authState is EmailUnlinked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم فك الربط بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
                _checkEmailLinkStatus();
              } else if (authState is AuthErrorState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(authState.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, authState) {
              final isEmailLinked = authState is EmailLinkStatusChecked && authState.isLinked;
              final email = authState is EmailLinkStatusChecked ? authState.email : null;

              return _buildSettingTile(
                icon: Icons.email,
                title: 'ربط بريد إلكتروني',
                subtitle: isEmailLinked 
                    ? 'مرتبط بـ $email - يمكن استخدامه لاستعادة كلمة المرور' 
                    : 'ربط بريد إلكتروني لاستعادة كلمة المرور بسهولة',
                trailing: isEmailLinked
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.link, color: Colors.grey),
                onTap: isLoading ? null : () => _handleEmailLink(context, isEmailLinked),
              );
            },
          ),

          const SizedBox(height: 24),

          // قسم الحساب
          _buildSectionHeader('الحساب'),
          _buildSettingTile(
            icon: Icons.person,
            title: 'معلومات الحساب',
            subtitle: 'تعديل البيانات الشخصية',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: isLoading ? null : _editProfile,
          ),
          _buildSettingTile(
            icon: Icons.logout,
            title: 'تسجيل الخروج',
            subtitle: 'الخروج من التطبيق',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: isLoading ? null : () => _logout(context),
          ),

          const SizedBox(height: 24),

          // قسم حول التطبيق
          _buildSectionHeader('حول التطبيق'),
          _buildSettingTile(
            icon: Icons.info,
            title: 'إصدار التطبيق',
            subtitle: '1.0.0',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: isLoading ? null : _showAppInfo,
          ),
          _buildSettingTile(
            icon: Icons.help,
            title: 'المساعدة والدعم',
            subtitle: 'دليل الاستخدام',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: isLoading ? null : _showHelp,
          ),
        ],
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
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF6DAF97)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  // دوال التحديث المحسنة
  String _getCurrentUserId() {
    final authState = context.read<AuthBloc>().state;
    return (authState is AuthAuthenticated) ? authState.userData['uid'] : '';
  }

  void _toggleSetting(BuildContext context, String settingKey, dynamic value) {
    context.read<SettingsBloc>().add(
      UpdateSingleSetting(_getCurrentUserId(), settingKey, value),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsModel settings) {
    final languages = ['العربية', 'English', 'Français', 'Español'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختيار اللغة'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(languages[index]),
              trailing: settings.language == languages[index]
                  ? const Icon(Icons.check, color: Color(0xFF6DAF97))
                  : null,
              onTap: () {
                _toggleSetting(context, 'language', languages[index]);
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context, SettingsModel settings) {
    final fontSizes = ['صغير', 'متوسط', 'كبير', 'كبير جداً'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حجم الخط'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: fontSizes.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(fontSizes[index], style: TextStyle(fontSize: _getFontSize(fontSizes[index]))),
              trailing: settings.fontSize == fontSizes[index]
                  ? const Icon(Icons.check, color: Color(0xFF6DAF97))
                  : null,
              onTap: () {
                _toggleSetting(context, 'fontSize', fontSizes[index]);
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    );
  }

  double _getFontSize(String size) {
    switch (size) {
      case 'صغير': return 14.0;
      case 'كبير': return 18.0;
      case 'كبير جداً': return 22.0;
      default: return 16.0;
    }
  }

  void _showThemeColorDialog(BuildContext context, SettingsModel settings) {
    final colors = ['أخضر أساسي', 'أزرق', 'أحمر', 'بنفسجي', 'برتقالي'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('لون الثيم'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: colors.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(colors[index]),
              trailing: settings.themeColor == colors[index]
                  ? const Icon(Icons.check, color: Color(0xFF6DAF97))
                  : null,
              onTap: () {
                _toggleSetting(context, 'themeColor', colors[index]);
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showSyncFrequencyDialog(BuildContext context, SettingsModel settings) {
    final frequencies = ['كل 15 دقيقة', 'كل 30 دقيقة', 'كل ساعة', 'كل 6 ساعات', 'يومياً'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تكرار المزامنة'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: frequencies.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(frequencies[index]),
              trailing: settings.syncFrequency == frequencies[index]
                  ? const Icon(Icons.check, color: Color(0xFF6DAF97))
                  : null,
              onTap: () {
                _toggleSetting(context, 'syncFrequency', frequencies[index]);
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showExportDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصدير البيانات'),
        content: const Text('سيتم تصدير جميع البيانات كملف Excel. هل تريد المتابعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportData();
            },
            child: const Text('تصدير'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري تصدير البيانات...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تعيين الإعدادات'),
        content: const Text('هل أنت متأكد من إعادة تعيين جميع الإعدادات إلى القيم الافتراضية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<SettingsBloc>().add(ResetSettings(_getCurrentUserId()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('إعادة التعيين'),
          ),
        ],
      ),
    );
  }

  void _handleEmailLink(BuildContext context, bool isCurrentlyLinked) {
    if (isCurrentlyLinked) {
      _showUnlinkEmailDialog(context);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
      );
    }
  }

  void _showUnlinkEmailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('فك ربط البريد الإلكتروني'),
        content: const Text('هل أنت متأكد من فك ربط البريد الإلكتروني؟ لن تتمكن من استخدامه لاستعادة كلمة المرور.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(const UnlinkEmailRequested());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('فك الربط'),
          ),
        ],
      ),
    );
  }

  void _changePassword(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isLoading = false;
          
          return AlertDialog(
            title: const Text('تغيير كلمة المرور'),
            content: isLoading 
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: currentPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'كلمة المرور الحالية',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: newPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'كلمة المرور الجديدة',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'تأكيد كلمة المرور الجديدة',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
            actions: isLoading
                ? []
                : [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (newPasswordController.text != confirmPasswordController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('كلمات المرور غير متطابقة')),
                          );
                          return;
                        }

                        if (newPasswordController.text.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل')),
                          );
                          return;
                        }

                        setDialogState(() => isLoading = true);

                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null && user.email != null) {
                            // إعادة المصادقة أولاً
                            final credential = EmailAuthProvider.credential(
                              email: user.email!,
                              password: currentPasswordController.text,
                            );
                            
                            await user.reauthenticateWithCredential(credential);
                            
                            // ثم تغيير كلمة المرور
                            await user.updatePassword(newPasswordController.text);
                            
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم تغيير كلمة المرور بنجاح'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } on FirebaseAuthException catch (e) {
                          setDialogState(() => isLoading = false);
                          String errorMessage;
                          switch (e.code) {
                            case 'wrong-password':
                              errorMessage = 'كلمة المرور الحالية غير صحيحة';
                              break;
                            case 'weak-password':
                              errorMessage = 'كلمة المرور الجديدة ضعيفة جداً';
                              break;
                            case 'requires-recent-login':
                              errorMessage = 'يجب تسجيل الدخول مرة أخرى لتغيير كلمة المرور';
                              break;
                            default:
                              errorMessage = 'حدث خطأ: ${e.message}';
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } catch (e) {
                          setDialogState(() => isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('حدث خطأ غير متوقع: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('تغيير'),
                    ),
                  ],
          );
        },
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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