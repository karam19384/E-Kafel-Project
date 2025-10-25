import 'package:e_kafel/src/models/orphan_model.dart';
import 'package:e_kafel/src/screens/sms/send_sms_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/widgets/app_drawer.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import '../../blocs/orphans/orphans_bloc.dart';
import '../Auth/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'edit_orphan_details_screen.dart';
import 'package:e_kafel/src/utils/app_colors.dart';

class OrphanDetailsScreen extends StatefulWidget {
  static const routeName = '/orphan_details_screen';
  final String orphanId;
  final String institutionId;
  const OrphanDetailsScreen({
    super.key,
    required this.orphanId,
    required this.institutionId,
  });

  @override
  State<OrphanDetailsScreen> createState() => _OrphanDetailsScreenState();
}

class _OrphanDetailsScreenState extends State<OrphanDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? orphanData;
  bool _isLoading = true;
  String? _errorMessage;
  String? _orphanPhotoUrl;

  @override
  void initState() {
    super.initState();
    _fetchOrphanDetails();
  }

  Future<void> _fetchOrphanDetails() async {
    try {
      final docSnapshot = await _firestore
          .collection('orphans')
          .doc(widget.orphanId)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          orphanData = docSnapshot.data();
          orphanData!['id'] = docSnapshot.id;
          _orphanPhotoUrl = orphanData!['orphanPhotoUrl'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'بيانات اليتيم غير موجودة.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في تحميل البيانات: $e';
        _isLoading = false;
      });
    }
  }

  void _sendSMS() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SendSMSScreen(
          recipientNumber: _safeString(orphanData!['mobileNumber']),
        ),
      ),
    );
  }

  void _archiveOrphan() async {
    final bool? shouldArchive = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'تأكيد الأرشفة',
          style: TextStyle(color: AppColors.primaryColor),
        ),
        content: Text('هل أنت متأكد من أرشفة هذا اليتيم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'إلغاء',
              style: TextStyle(color: AppColors.secondaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            child: Text('أرشفة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldArchive == true) {
      context.read<OrphansBloc>().add(
        ArchiveOrphan(
          orphanId: widget.orphanId,
          institutionId: widget.institutionId,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم أرشفة اليتيم بنجاح!'),
          backgroundColor: AppColors.successColor,
        ),
      );

      Navigator.of(context).pop();
    }
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // زيادة المسافة بدلاً من الديفايدر
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // زيادة المسافة بين العناصر
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: AppColors.secondaryColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  '$label:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8), // تقليل المسافة بين العمودين
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: AppColors.textColor),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrphanHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // صورة اليتيم
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: _orphanPhotoUrl != null && _orphanPhotoUrl!.isNotEmpty
                    ? Image.network(
                        _orphanPhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // اسم اليتيم ورقمه
            Text(
              _safeString(orphanData!['orphanName'], defaultValue: 'غير معروف'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'رقم اليتيم: ${_safeString(orphanData!['orphanNo'])}',
              style: TextStyle(fontSize: 14, color: AppColors.secondaryColor),
            ),
            const SizedBox(height: 16),

            // الأزرار الثلاثة
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.edit,
          label: 'تعديل',
          color: AppColors.primaryColor,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EditOrphanDetailsScreen(
                  orphanId: widget.orphanId,
                  orphanData: orphanData as Orphan,
                  institutionId: orphanData!['institutionId'] ?? '',
                ),
              ),
            );
          },
        ),
        _buildActionButton(
          icon: Icons.sms,
          label: 'رسالة',
          color: AppColors.accentColor,
          onPressed: _sendSMS,
        ),
        _buildActionButton(
          icon: Icons.archive,
          label: 'أرشفة',
          color: AppColors.errorColor,
          onPressed: _archiveOrphan,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: color, size: 24),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل اليتيم', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchOrphanDetails,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'جاري تحميل البيانات...',
                    style: TextStyle(color: AppColors.secondaryColor),
                  ),
                ],
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: AppColors.errorColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _fetchOrphanDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    child: Text(
                      'إعادة المحاولة',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // رأس الصفحة - الصورة والأزرار
                  _buildOrphanHeader(),

                  // بطاقة المعلومات الأساسية
                  _buildInfoCard('المعلومات الأساسية', [
                    _buildDetailItem(
                      'إسم اليتيم',
                      _formatDate(_safeString(orphanData!['orphanFullName'])),
                      icon: Icons.person,
                    ),
                     _buildDetailItem(
                      'معرف اليتيم',
                      _formatDate(_safeString(orphanData!['orphanNo'])),
                      icon: Icons.numbers,
                    ),
                    _buildDetailItem(
                      'الرقم الوطني',
                      _safeString(orphanData!['orphanIdNumber']),
                      icon: Icons.badge,
                    ),
                    _buildDetailItem(
                      'تاريخ الميلاد',
                      _formatDate(orphanData!['dateOfBirth']),
                      icon: Icons.cake,
                    ),
                    _buildDetailItem(
                      'الجنس',
                      _safeString(orphanData!['gender']),
                      icon: Icons.people,
                    ),
                    _buildDetailItem(
                      'العمر',
                      _calculateAge(orphanData!['dateOfBirth']),
                      icon: Icons.calendar_today,
                    ),
                  ]),

                  // بطاقة معلومات الأم
                  _buildInfoCard('معلومات الأم', [
                    _buildDetailItem(
                      'اسم الأم',
                      _safeString(orphanData!['motherFullName']),
                      icon: Icons.woman,
                    ),
                    _buildDetailItem(
                      'الرقم الوطني للأم',
                      _safeString(orphanData!['motherIdNumber']),
                      icon: Icons.badge,
                    ),
                    _buildDetailItem(
                      ' عمر الأم',
                      _safeString(orphanData!['motherAge']),
                      icon: Icons.phone,
                    ),
                    
                  ]),

                  // بطاقة معلومات المعيل
                  _buildInfoCard('معلومات المعيل', [
                    _buildDetailItem(
                      'اسم المعيل',
                      _safeString(orphanData!['deceasedFullName']),
                      icon: Icons.person,
                    ),
                    _buildDetailItem(
                      'الرقم الوطني للمعيل',
                      _safeString(orphanData!['breadwinnerIdNumber']),
                      icon: Icons.badge,
                    ),
                    _buildDetailItem(
                      'حالة المعيل الاجتماعية',
                      _safeString(orphanData!['breadwinnerMaritalStatus']),
                      icon: Icons.family_restroom,
                    ),
                    _buildDetailItem(
                      'صلة القرابة بالمعيل',
                      _safeString(orphanData!['breadwinnerKinship']),
                      icon: Icons.people_alt,
                    ),
                  ]),

                  // بطاقة معلومات المتوفى
                  _buildInfoCard('معلومات المتوفى', [
                    _buildDetailItem(
                      'اسم المتوفى',
                      _safeString(orphanData!['deceasedFullName']),
                      icon: Icons.person_off,
                    ),
                    _buildDetailItem(
                      'الرقم الوطني للمتوفى',
                      _safeString(orphanData!['deceasedIdNumber']),
                      icon: Icons.badge,
                    ),
                    _buildDetailItem(
                      'تاريخ الوفاة',
                      _formatDate(orphanData!['dateOfDeath']),
                      icon: Icons.event,
                    ),
                    _buildDetailItem(
                      'سبب الوفاة',
                      _safeString(orphanData!['causeOfDeath']),
                      icon: Icons.medical_services,
                    ),
                  ]),

                  // بطاقة المعلومات الجغرافية
                  _buildInfoCard('المعلومات الجغرافية', [
                    _buildDetailItem(
                      'المحافظة',
                      _safeString(orphanData!['governorate']),
                      icon: Icons.location_city,
                    ),
                    _buildDetailItem(
                      'المدينة',
                      _safeString(orphanData!['city']),
                      icon: Icons.location_on,
                    ),
                    _buildDetailItem(
                      'الحي',
                      _safeString(orphanData!['neighborhood']),
                      icon: Icons.home,
                    ),
                    _buildDetailItem(
                      'رقم الهاتف',
                      _safeString(orphanData!['mobileNumber']),
                      icon: Icons.phone,
                    ),
                  ]),

                  // بطاقة المعلومات الأسرية
                  _buildInfoCard('المعلومات الأسرية', [
                    _buildDetailItem(
                      'عدد الذكور',
                      _safeString(
                        orphanData!['numberOfMales'],
                        defaultValue: '0',
                      ),
                      icon: Icons.man,
                    ),
                    _buildDetailItem(
                      'عدد الإناث',
                      _safeString(
                        orphanData!['numberOfFemales'],
                        defaultValue: '0',
                      ),
                      icon: Icons.woman,
                    ),
                    _buildDetailItem(
                      'إجمالي أفراد العائلة',
                      _safeString(
                        orphanData!['totalFamilyMembers'],
                        defaultValue: '0',
                      ),
                      icon: Icons.people,
                    ),
                    _buildDetailItem(
                      'ملكية السكن',
                      _safeString(orphanData!['housingOwnership']),
                      icon: Icons.house,
                    ),
                  ]),

                  // بطاقة المعلومات التعليمية
                  _buildInfoCard('المعلومات التعليمية', [
                    _buildDetailItem(
                      'اسم المدرسة',
                      _safeString(orphanData!['schoolName']),
                      icon: Icons.school,
                    ),
                    _buildDetailItem(
                      'الصف',
                      _safeString(orphanData!['grade']),
                      icon: Icons.grade,
                    ),
                    _buildDetailItem(
                      'المستوى التعليمي',
                      _safeString(orphanData!['educationLevel']),
                      icon: Icons.school,
                    ),
                    _buildDetailItem(
                      'الحالة التعليمية',
                      _safeString(orphanData!['educationStatus']),
                      icon: Icons.book,
                    ),
                  ]),

                  // بطاقة المعلومات الصحية
                  _buildInfoCard('المعلومات الصحية', [
                    _buildDetailItem(
                      'الحالة الصحية',
                      _safeString(orphanData!['healthCondition']),
                      icon: Icons.health_and_safety,
                    ),
                    _buildDetailItem(
                      'الأمراض المزمنة',
                      _safeString(orphanData!['chronicDiseases']),
                      icon: Icons.medical_services,
                    ),
                    _buildDetailItem(
                      'الإعاقات',
                      _safeString(orphanData!['disabilities']),
                      icon: Icons.accessible,
                    ),
                  ]),

                  // بطاقة معلومات الكفالة
                  _buildInfoCard('معلومات الكفالة', [
                    _buildDetailItem(
                      'حالة الكفالة',
                      _safeString(orphanData!['sponsorshipStatus']),
                      icon: Icons.attach_money,
                    ),
                    _buildDetailItem(
                      'اسم الكافل',
                      _safeString(orphanData!['sponsorName']),
                      icon: Icons.person,
                    ),
                    _buildDetailItem(
                      'قيمة الكفالة',
                      _safeString(orphanData!['sponsorshipAmount']),
                      icon: Icons.money,
                    ),
                  ]),

                  // بطاقة الملفات المرفقة
                  _buildInfoCard('الملفات المرفقة', [
                    _buildFileItem(
                      'صورة الهوية',
                      orphanData!['idCardUrl'],
                      icon: Icons.credit_card,
                    ),
                    _buildFileItem(
                      'شهادة الوفاة',
                      orphanData!['deathCertificateUrl'],
                      icon: Icons.description,
                    ),
                    _buildFileItem(
                      'شهادة ميلاد',
                      orphanData!['birthCertificateUrl'],
                      icon: Icons.cake,
                    ),
                  ]),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildFileItem(String label, String? url, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: AppColors.secondaryColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  '$label:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: url != null && url.isNotEmpty
                ? InkWell(
                    onTap: () async {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primaryColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 14,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'عرض',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Text(
                    'لا يوجد',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp)
      return DateFormat('dd/MM/yyyy').format(date.toDate());
    if (date is DateTime) return DateFormat('dd/MM/yyyy').format(date);
    return 'غير متوفر';
  }

  String _calculateAge(dynamic date) {
    try {
      DateTime birthDate;
      if (date is Timestamp) {
        birthDate = date.toDate();
      } else if (date is DateTime) {
        birthDate = date;
      } else {
        return 'غير معروف';
      }

      DateTime now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return '$age سنة';
    } catch (e) {
      return 'غير معروف';
    }
  }

  String _safeString(dynamic value, {String defaultValue = 'غير متوفر'}) {
    if (value == null) return defaultValue;
    if (value.toString().isEmpty) return defaultValue;
    return value.toString();
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
