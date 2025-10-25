// lib/src/screens/supervisors/supervisors_details_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/user_model.dart';
import 'edit_supervisors_details_screen.dart';
import '../../blocs/supervisors/supervisors_bloc.dart';

class SupervisorsDetailsScreen extends StatelessWidget {
  final UserModel user;
  final bool isHeadOfKafala; // لتحديد صلاحية رئيس القسم

  const SupervisorsDetailsScreen({
    super.key,
    required this.user,
    required this.isHeadOfKafala,
  });

  Future<String> _getKafalaHeadName(String? kafalaHeadId) async {
    if (kafalaHeadId == null || kafalaHeadId.isEmpty) return '—';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(kafalaHeadId)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['fullName'] ?? '—';
      } else {
        return '—';
      }
    } catch (_) {
      return '—';
    }
  }

  void _openEdit(BuildContext context) async {
    // يفتح شاشة تعديل المشرف
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditSupervisorsDetailsScreen(user: user ),
      ),
    );

    if (result == true) {
      // لو تم التعديل بنجاح، نعيد تحميل البيانات من البلوك
      context.read<SupervisorsBloc>().add(
            LoadSupervisorsByHead(
              institutionId: user.institutionId,
              kafalaHeadId: user.kafalaHeadId ?? '',
              isActive: user.isActive,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = user.fullName.trim().isNotEmpty == true
        ? user.fullName.trim()
        : 'بدون اسم';
    final String email = user.email.trim().isNotEmpty == true
        ? user.email.trim()
        : '—';
    final String mobile = user.mobileNumber.toString().trim().isNotEmpty == true
        ? user.mobileNumber.toString().trim()
        : '—';
    final String address = user.address?.trim().isNotEmpty == true
        ? user.address!.trim()
        : '—';
    final String area = user.areaResponsibleFor?.trim().isNotEmpty == true
        ? user.areaResponsibleFor!.trim()
        : '—';
    final bool isActive = user.isActive;
    final String? photo = user.profileImageUrl?.isNotEmpty == true
        ? user.profileImageUrl
        : null;
    final String customId = user.customId.trim().isNotEmpty == true
        ? user.customId.trim()
        : '—';
    final String functionalLodgment = user.functionalLodgment!.trim().isNotEmpty == true
        ? user.functionalLodgment!.trim()
        : '—';
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: const Color(0xFF6DAF97),
        actions: [
          // ✏️ زر تعديل فقط لرئيس القسم
          if (isHeadOfKafala)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'تعديل بيانات المشرف',
              onPressed: () => _openEdit(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: const Color(0xFF6DAF97).withOpacity(0.1),
              backgroundImage: photo != null ? NetworkImage(photo) : null,
              child: photo == null
                  ? const Icon(Icons.person, size: 48, color: Color(0xFF6DAF97))
                  : null,
            ),
            const SizedBox(height: 16),
            _row('الاسم الكامل', name),
            _row('الرقم الوظيفي', customId),
            _row('البريد الإلكتروني', email),
            _row('رقم الجوال', mobile),
            _row('العنوان', address),
            _row('المنطقة الوظيفية', area),
            _row('المهام الوظيفية', functionalLodgment),
            FutureBuilder<String>(
              future: _getKafalaHeadName(user.kafalaHeadId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return _row('رئيس قسم الكفالة', 'جاري التحميل...');
                }
                return _row('رئيس قسم الكفالة', snap.data ?? '—');
              },
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('الحالة: ',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  isActive ? 'نشط' : 'غير نشط',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(value, style: const TextStyle(fontSize: 15)),
      ),
    );
  }
}
