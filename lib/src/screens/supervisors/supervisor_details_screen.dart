// lib/src/screens/supervisors/supervisor_details_screen.dart
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'edit_supervisor_screen.dart';

class SupervisorDetailsScreen extends StatefulWidget {
  final UserModel user;
  const SupervisorDetailsScreen({super.key, required this.user});

  @override
  State<SupervisorDetailsScreen> createState() =>
      _SupervisorDetailsScreenState();
}

class _SupervisorDetailsScreenState extends State<SupervisorDetailsScreen> {
  late UserModel _user;
  final _service = FirestoreService();

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _reload();
  }

  Future<void> _reload() async {
    final fresh = await _service.getSupervisorById(_user.uid);
    if (fresh != null && mounted) {
      setState(() => _user = fresh);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف ${_user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _service.removeSupervisor(_user.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف المشرف')));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final styleL = const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.teal,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المشرف')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 28,
              child: Text(_user.fullName.isNotEmpty ? _user.fullName[0] : '?'),
            ),
            title: Text(_user.fullName),
            subtitle: Text(_user.email),
            trailing: Icon(
              _user.isActive ? Icons.check_circle : Icons.cancel,
              color: _user.isActive ? Colors.green : Colors.red,
            ),
          ),
          const Divider(),
          _row('المؤسسة', _user.institutionName, styleL),
          _row('الرقم المخصص', _user.customId, styleL),
          _row('الجوال', _user.mobileNumber, styleL),
          _row('الدور', _user.userRole, styleL),
          _row('المرفق الوظيفي', _user.functionalLodgment ?? '-', styleL),
          _row('المنطقة المسؤولة', _user.areaResponsibleFor ?? '-', styleL),
          _row('العنوان', _user.address ?? '-', styleL),
          _row('الحالة', _user.isActive ? 'مفعل' : 'غير مفعل', styleL),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final changed = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditSupervisorScreen(user: _user),
                      ),
                    );
                    if (changed == true) await _reload();
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('تعديل'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _delete,
                  icon: const Icon(Icons.delete),
                  label: const Text('حذف'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, TextStyle labStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: labStyle)),
          const SizedBox(width: 10),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
