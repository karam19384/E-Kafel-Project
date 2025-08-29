import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/screens/edit_orphan_details_screen.dart'; // تأكد من المسار الصحيح
import 'package:e_kafel/src/widgets/app_drawer.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'login_screen.dart';

class OrphanDetailsScreen extends StatefulWidget {
  final String orphanId;

  const OrphanDetailsScreen({super.key, required this.orphanId});

  @override
  State<OrphanDetailsScreen> createState() => _OrphanDetailsScreenState();
}

class _OrphanDetailsScreenState extends State<OrphanDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _orphanData;
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
          _orphanData = docSnapshot.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Orphan not found.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading orphan details: $e';
      });
      print('Error fetching orphan details: $e');
    }
  }

  // دالة لتأكيد وحذف اليتيم
  Future<void> _confirmAndDeleteOrphan() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Confirm Deletion',
            style: TextStyle(color: Color(0xFF4C7F7F)),
          ),
          content: const Text(
            'Are you sure you want to delete this orphan? This action cannot be undone.',
            style: TextStyle(color: Colors.black87),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false), // لا تؤكد الحذف
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF6DAF97),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // تؤكد الحذف
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true; // عرض مؤشر تحميل أثناء الحذف
      });
      try {
        await _firestore.collection('orphans').doc(widget.orphanId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Orphan deleted successfully!')),
          );
          Navigator.of(
            context,
          ).pop(true); // العودة إلى الشاشة السابقة وإعلامها بالحذف
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete orphan: $e')),
          );
        }
        print('Error deleting orphan: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // دالة لعرض نافذة إضافة الكفالة المنبثقة
  Future<void> _showAddSponsorshipDialog() async {
    String? sponsorshipType;
    String? sponsorshipAmount;
    final GlobalKey<FormState> _sponsorshipFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // استخدام dialogContext هنا
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Add Sponsorship',
            style: TextStyle(color: Color(0xFF4C7F7F)),
          ),
          content: Form(
            key: _sponsorshipFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Sponsorship Type',
                    prefixIcon: const Icon(
                      Icons.category,
                      color: Color(0xFF4C7F7F),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF6DAF97)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF4C7F7F),
                        width: 2,
                      ),
                    ),
                  ),
                  value: sponsorshipType,
                  hint: const Text('Select Type'),
                  items: <String>['Monthly', 'One-time', 'Education', 'Health']
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      })
                      .toList(),
                  onChanged: (String? newValue) {
                    sponsorshipType = newValue;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a sponsorship type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Amount (\$)',
                    hintText: 'Enter amount',
                    prefixIcon: const Icon(
                      Icons.attach_money,
                      color: Color(0xFF4C7F7F),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF6DAF97)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF4C7F7F),
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    sponsorshipAmount = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF6DAF97)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_sponsorshipFormKey.currentState!.validate()) {
                  // هنا يمكنك حفظ بيانات الكفالة الجديدة إلى Firestore
                  // مثلاً، في مجموعة فرعية داخل مستند اليتيم، أو في مجموعة منفصلة
                  try {
                    await _firestore
                        .collection('orphans')
                        .doc(widget.orphanId)
                        .collection('sponsorships')
                        .add({
                          'type': sponsorshipType,
                          'amount': double.parse(sponsorshipAmount!),
                          'dateAdded': Timestamp.now(),
                          // يمكنك إضافة المزيد من الحقول هنا مثل اسم الكفيل إن وجد
                        });
                    // تحديث حقل Total Support لليتيم
                    final double currentTotalSupport =
                        _orphanData?['totalSupport'] ?? 0.0;
                    await _firestore
                        .collection('orphans')
                        .doc(widget.orphanId)
                        .update({
                          'totalSupport':
                              currentTotalSupport +
                              double.parse(sponsorshipAmount!),
                          'latestSupportDate':
                              Timestamp.now(), // تحديث تاريخ آخر دعم
                        });

                    if (mounted) {
                      // تحقق من mounted قبل استخدام السياق
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sponsorship added successfully!'),
                        ),
                      );
                      Navigator.of(
                        dialogContext,
                      ).pop(); // إغلاق النافذة المنبثقة
                      _fetchOrphanDetails(); // إعادة جلب التفاصيل لتحديث العرض
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add sponsorship: $e'),
                        ),
                      );
                    }
                    print('Error adding sponsorship: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6DAF97),
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String orphanFullName =
        _orphanData?['name'] ?? 'N/A'; // استخدم 'name' من Firestore
    String orphanNo = _orphanData?['orphanNo'] ?? 'N/A';
    String sponsorshipStatus = _orphanData?['sponsorshipStatus'] ?? 'N/A';
    String totalSupport = (_orphanData?['totalSupport'] ?? 0.0).toStringAsFixed(
      2,
    );
    String lastSupportDate = 'N/A';

    if (_orphanData?['latestSupportDate'] is Timestamp) {
      lastSupportDate = DateFormat(
        'dd/MM/yyyy',
      ).format((_orphanData!['latestSupportDate'] as Timestamp).toDate());
    } else if (_orphanData?['latestSupportDate'] is String) {
      try {
        lastSupportDate = DateFormat(
          'dd/MM/yyyy',
        ).format(DateTime.parse(_orphanData!['latestSupportDate']));
      } catch (e) {
        print('Error parsing lastSupportDate: $e');
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0E8EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6DAF97),
        elevation: 0,
        title: const Text(
          'Orphan Details',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      drawer: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoaded) {
            return AppDrawer(
              userName: state.userName,
              userRole: state.userRole,
              profileImageUrl: state.profileImageUrl,
              orphanCount: state.orphanSponsored,
              taskCount:
                  state.completedTasksPercentage, // عدلها حسب المتغير المناسب
              visitCount:
                  state.completedFieldVisits, // عدلها حسب المتغير المناسب
              onLogout: () {
                context.read<AuthBloc>().add(LogoutButtonPressed());
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            );
          }
          return AppDrawer(
            userName: '',
            userRole: '',
            orphanCount: 0,
            taskCount: 0,
            visitCount: 0,
            onLogout: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          );
        },
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: const Color(0xFF6DAF97),
                      backgroundImage:
                          _orphanData?['profileImageUrl'] != null &&
                              _orphanData!['profileImageUrl'].isNotEmpty
                          ? NetworkImage(_orphanData!['profileImageUrl'])
                          : null,
                      child:
                          _orphanData?['profileImageUrl'] == null ||
                              _orphanData!['profileImageUrl'].isEmpty
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 80,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        icon: Icons.delete,
                        label: 'Remove',
                        color: const Color(
                          0xFFE0BBE4,
                        ), // لون مشابه للوردي في الصورة
                        onPressed: _confirmAndDeleteOrphan,
                      ),
                      _buildActionButton(
                        icon: Icons.edit,
                        label: 'Edit Data',
                        color: const Color(
                          0xFFC8A2C8,
                        ), // لون مشابه للأخضر في الصورة
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditOrphanDetailsScreen(
                                orphanId: widget.orphanId,
                              ),
                            ),
                          );
                          if (result == true) {
                            _fetchOrphanDetails(); // تحديث البيانات بعد العودة من شاشة التعديل
                          }
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.add,
                        label: 'Add Sponsorship',
                        color: const Color(
                          0xFFAFD8D2,
                        ), // لون مشابه للأزرق في الصورة
                        onPressed: _showAddSponsorshipDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  _buildDetailRow(
                    label: 'Orphan Full Name',
                    value: orphanFullName,
                  ),
                  _buildDetailRow(label: 'Orphan No.', value: orphanNo),
                  _buildDetailRow(
                    label: 'ID Number',
                    value: _orphanData?['idNumber'] ?? 'N/A',
                  ),
                  _buildDetailRow(
                    label: 'Phone',
                    value: _orphanData?['phone'] ?? 'N/A',
                  ),
                  _buildDetailRow(
                    label: 'Sponsorship Status',
                    value: sponsorshipStatus,
                  ),
                  _buildDetailRow(
                    label: 'Last Support',
                    value: lastSupportDate,
                  ),
                  _buildDetailRow(
                    label: 'Total Support This Year',
                    value: '\$$totalSupport',
                  ),
                  _buildDetailRow(
                    label: 'Total Family Members',
                    value: _orphanData?['familyMembers']?.toString() ?? 'N/A',
                  ),
                  _buildDetailRow(
                    label: 'Age',
                    value: _orphanData?['age']?.toString() ?? 'N/A',
                  ),
                  _buildDetailRow(
                    label: 'Governorate',
                    value: _orphanData?['governorate'] ?? 'N/A',
                  ),
                  _buildDetailRow(
                    label: 'Relationship to deceased',
                    value: _orphanData?['relationshipToDeceased'] ?? 'N/A',
                  ),
                  _buildDetailRow(
                    label: 'Gender',
                    value: _orphanData?['gender'] ?? 'N/A',
                  ),
                  _buildDetailRow(
                    label: 'Cause of Death',
                    value: _orphanData?['causeOfDeath'] ?? 'N/A',
                  ),
                ],
              ),
            ),
    );
  }

  // Helper widget for action buttons
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

  // Helper widget for displaying detail rows
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
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
