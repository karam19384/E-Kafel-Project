// lib/src/screens/supervisors_screen.dart
import 'package:flutter/material.dart';

class SupervisorsScreen extends StatefulWidget {
  const SupervisorsScreen({super.key});

  @override
  State<SupervisorsScreen> createState() => _SupervisorsScreenState();
}

class _SupervisorsScreenState extends State<SupervisorsScreen> {
  // بيانات وهمية مؤقتة. سيتم استبدالها لاحقًا ببيانات الـ Bloc
  final List<Map<String, dynamic>> _supervisors = [
    {
      'id': '1',
      'name': 'علي محمد',
      'role': 'مشرف',
      'is_active': true,
      'image_url': 'https://via.placeholder.com/150', // مثال لـ URL صورة
    },
    {
      'id': '2',
      'name': 'فاطمة أحمد',
      'role': 'مشرفة',
      'is_active': false,
      'image_url': 'https://via.placeholder.com/150',
    },
    {
      'id': '3',
      'name': 'خالد محمود',
      'role': 'مشرف',
      'is_active': true,
      'image_url': 'https://via.placeholder.com/150',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إدارة المشرفين',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6DAF97),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: الانتقال إلى شاشة إضافة مشرف جديد
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('إضافة مشرف جديد')),
          );
        },
        label: const Text('إضافة مشرف', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF4C7F7F),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl, // دعم الواجهة العربية
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            itemCount: _supervisors.length,
            itemBuilder: (context, index) {
              final supervisor = _supervisors[index];
              return _buildSupervisorCard(supervisor);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSupervisorCard(Map<String, dynamic> supervisor) {
    return Dismissible(
      key: Key(supervisor['id']),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 36),
      ),
      onDismissed: (direction) {
        // TODO: تنفيذ منطق الحذف أو الأرشفة هنا
        setState(() {
          _supervisors.remove(supervisor);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${supervisor['name']} تم حذفه/أرشفته'),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(supervisor['image_url']),
            radius: 30,
          ),
          title: Text(
            supervisor['name'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          subtitle: Text(
            supervisor['role'],
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.edit,
              color: Colors.blue[800],
            ),
            onPressed: () {
              // TODO: الانتقال إلى شاشة تعديل المشرف
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تعديل ${supervisor['name']}')),
              );
            },
          ),
        ),
      ),
    );
  }
}