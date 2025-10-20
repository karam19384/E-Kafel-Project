import 'package:e_kafel/src/models/orphan_model.dart';
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

class OrphanDetailsScreen extends StatefulWidget {
  static const routeName = '/orphan_details_screen';

  final String orphanId; // docId
  final String institutionId;
  const OrphanDetailsScreen({super.key, required this.orphanId, required this.institutionId});

  @override
  State<OrphanDetailsScreen> createState() => _OrphanDetailsScreenState();
}

class _OrphanDetailsScreenState extends State<OrphanDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? orphanData;
  bool _isLoading = true;
  String? _errorMessage;

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
          orphanData!['id'] = docSnapshot.id; // نخزن docId مع البيانات
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم إرسال رسالة نصية قريباً.')),
    );
  }

  void _archiveOrphan() async {
    final bool? shouldArchive = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الأرشفة'),
        content: const Text('هل أنت متأكد من أرشفة هذا اليتيم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('أرشفة'),
          ),
        ],
      ),
    );

    if (shouldArchive == true) {
      context.read<OrphansBloc>().add(
        ArchiveOrphan(orphanId: widget.orphanId, institutionId: widget.institutionId),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم أرشفة اليتيم بنجاح!')));

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل اليتيم'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4C7F7F),
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                  _buildDetailsCard(),
                  const SizedBox(height: 20),
                  _buildFilesCard(),
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
          color: Colors.blue,
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
          color: const Color(0xFFE0BBE4),
          onPressed: _sendSMS,
        ),
        _buildActionButton(
          icon: Icons.archive,
          label: 'أرشفة',
          color: Colors.red,
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
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(15),
            elevation: 3,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4C7F7F),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'بيانات اليتيم',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4C7F7F),
              ),
            ),
            const Divider(),
            _buildDetailRow(
              label: 'رقم اليتيم',
              value: _safeString(orphanData!['orphanNo']),
            ),
            _buildDetailRow(
              label: 'الاسم الكامل',
              value: _safeString(orphanData!['name']),
            ),
            _buildDetailRow(
              label: 'الرقم الوطني',
              value: _safeString(orphanData!['orphanIdNumber']),
            ),
            _buildDetailRow(
              label: 'تاريخ الميلاد',
              value: _formatDate(orphanData!['dateOfBirth']),
            ),
            _buildDetailRow(
              label: 'الجنس',
              value: _safeString(orphanData!['gender']),
            ),
            _buildDetailRow(
              label: 'اسم الأم',
              value: _safeString(orphanData!['motherName']),
            ),
            _buildDetailRow(
              label: 'الرقم الوطني للأم',
              value: _safeString(orphanData!['motherIdNumber']),
            ),
            _buildDetailRow(
              label: 'اسم المعيل',
              value: _safeString(orphanData!['breadwinnerName']),
            ),
            _buildDetailRow(
              label: 'الرقم الوطني للمعيل',
              value: _safeString(orphanData!['breadwinnerIdNumber']),
            ),
            _buildDetailRow(
              label: 'حالة المعيل الاجتماعية',
              value: _safeString(orphanData!['breadwinnerMaritalStatus']),
            ),
            _buildDetailRow(
              label: 'صلة القرابة بالمعيل',
              value: _safeString(orphanData!['breadwinnerKinship']),
            ),
            _buildDetailRow(
              label: 'اسم المتوفى',
              value: _safeString(orphanData!['deceasedName']),
            ),
            _buildDetailRow(
              label: 'الرقم الوطني للمتوفى',
              value: _safeString(orphanData!['deceasedIdNumber']),
            ),
            _buildDetailRow(
              label: 'تاريخ الوفاة',
              value: _formatDate(orphanData!['dateOfDeath']),
            ),
            _buildDetailRow(
              label: 'سبب الوفاة',
              value: _safeString(orphanData!['causeOfDeath']),
            ),
            _buildDetailRow(
              label: 'المحافظة',
              value: _safeString(orphanData!['governorate']),
            ),
            _buildDetailRow(
              label: 'المدينة',
              value: _safeString(orphanData!['city']),
            ),
            _buildDetailRow(
              label: 'الحي',
              value: _safeString(orphanData!['neighborhood']),
            ),
            _buildDetailRow(
              label: 'رقم الهاتف',
              value: _safeString(orphanData!['mobileNumber']),
            ),
            _buildDetailRow(
              label: 'رقم الأرضي',
              value: _safeString(orphanData!['mobileNumber']),
            ),
            _buildDetailRow(
              label: 'عدد الذكور',
              value: _safeString(
                orphanData!['numberOfMales'],
                defaultValue: '0',
              ),
            ),
            _buildDetailRow(
              label: 'عدد الإناث',
              value: _safeString(
                orphanData!['numberOfFemales'],
                defaultValue: '0',
              ),
            ),
            _buildDetailRow(
              label: 'إجمالي أفراد العائلة',
              value: _safeString(
                orphanData!['totalFamilyMembers'],
                defaultValue: '0',
              ),
            ),
            _buildDetailRow(
              label: 'اسم المدرسة',
              value: _safeString(orphanData!['schoolName']),
            ),
            _buildDetailRow(
              label: 'الصف',
              value: _safeString(orphanData!['grade']),
            ),
            _buildDetailRow(
              label: 'المستوى التعليمي',
              value: _safeString(orphanData!['educationLevel']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الملفات المرفقة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4C7F7F),
              ),
            ),
            const Divider(),
            _buildFileRow(label: 'صورة الهوية', url: orphanData!['idCardUrl']),
            _buildFileRow(
              label: 'شهادة الوفاة',
              url: orphanData!['deathCertificateUrl'],
            ),
            _buildFileRow(
              label: 'صورة شخصية',
              url: orphanData!['orphanPhotoUrl'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF4C7F7F),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Color(0xFF4C7F7F)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileRow({required String label, required String? url}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF4C7F7F),
              ),
            ),
          ),
          const SizedBox(width: 10),
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
                    child: const Text(
                      'عرض الملف',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : const Text(
                    'لا يوجد',
                    style: TextStyle(fontSize: 16, color: Color(0xFF4C7F7F)),
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

  String _safeString(dynamic value, {String defaultValue = 'غير متوفر'}) {
    if (value == null) return defaultValue;
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
          userName: 'Loading...',
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
