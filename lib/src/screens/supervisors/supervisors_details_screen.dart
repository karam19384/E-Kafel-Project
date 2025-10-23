import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import 'edit_supervisors_details_screen.dart';

class SupervisorsDetailsScreen extends StatefulWidget {
  final UserModel user;
  const SupervisorsDetailsScreen({super.key, required this.user, required bool isHeadOfKafala});

  @override
  State<SupervisorsDetailsScreen> createState() =>
      _SupervisorsDetailsScreenState();
}

class _SupervisorsDetailsScreenState extends State<SupervisorsDetailsScreen> {
  String _headName = '—';
  final _fs = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadHeadName();
  }

  Future<void> _loadHeadName() async {
    if (widget.user.kafalaHeadId != null &&
        widget.user.kafalaHeadId!.trim().isNotEmpty) {
      final name = await _fs.getHeadNameById(widget.user.kafalaHeadId!);
      if (!mounted) return;
      setState(() => _headName = name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final isHead =
        auth is AuthAuthenticated && auth.userRole == 'kafala_head';

    final u = widget.user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('بيانات المشرف'),
        actions: [
          if (isHead)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'تعديل بيانات المشرف',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditSupervisorsDetailsScreen(user: u),
                  ),
                );
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundImage: (u.profileImageUrl ?? '').isNotEmpty
                  ? NetworkImage(u.profileImageUrl!)
                  : null,
              child: (u.profileImageUrl ?? '').isEmpty
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              u.fullName,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 32),
          _row('البريد', u.email),
          _row('الجوال', (u.mobileNumber).toString()),
          _row('العنوان', u.address ?? '—'),
          _row('المسمى/المهام', u.functionalLodgment ?? '—'),
          _row('المنطقة المسؤولة', u.areaResponsibleFor ?? '—'),
          _row('رئيس قسم الكفالة', _headName),
          _row('الحالة', (u.isActive) ? 'فعال' : 'غير فعال'),
        ],
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              title,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
