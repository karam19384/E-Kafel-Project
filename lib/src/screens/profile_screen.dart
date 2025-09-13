import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// تأكد من استيراد شاشة تعديل الملف الشخصي إذا كانت موجودة
// import 'package:e_kafel/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User not logged in.';
      });
      return;
    }

    try {
      final userDoc = await _firestore
          .collection('kafala_heads')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User profile data not found.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading user data: $e';
      });
      print('Error fetching user data: $e');
    }
  }

  // دالة للانتقال إلى شاشة التعديل
  void _navigateToEditProfile() async {
    // يمكنك هنا إما:
    // 1. الانتقال إلى شاشة تعديل منفصلة (EditProfileScreen)
    // 2. أو تحويل هذه الشاشة نفسها إلى وضع التعديل (إذا كانت بسيطة)
    // للمثال، سنفترض الانتقال إلى شاشة EditProfileScreen

    // final result = await Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => EditProfileScreen(userData: _userData)), // تمرير البيانات الحالية
    // );
    // if (result == true) { // إذا تم التعديل بنجاح وتم إرجاع true
    //   _fetchUserData(); // إعادة جلب البيانات لتحديث العرض
    // }

    // Placeholder: في حال عدم وجود شاشة تعديل منفصلة بعد
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit Profile functionality to be implemented.'),
      ),
    );
    print('Navigate to Edit Profile Screen');
  }

  @override
  Widget build(BuildContext context) {
    String profileImageUrl = _userData?['profileImageUrl'] ?? '';
    String name = _userData?['name'] ?? 'N/A'; //
    String email = _userData?['email'] ?? 'N/A'; //
    String phone = _userData?['phone'] ?? 'N/A'; //
    String institutionName =
        _userData?['institutionName'] ?? 'N/A'; // (اسم المؤسسة)
    String address = _userData?['address'] ?? 'N/A';
    String website = _userData?['website'] ?? 'N/A'; // (موقع المؤسسة)
    String functionalLodgment =
        _userData?['functionalLodgment'] ?? 'N/A'; // (Functional lodgment)
    String areaResponsibleFor =
        _userData?['areaResponsibleFor'] ?? 'N/A'; // (Area responsible for)

    return Scaffold(
      backgroundColor: const Color(0xFFF0E8EB), // لون الخلفية
      appBar: AppBar(
        backgroundColor: const Color(0xFF6DAF97), // لون الـ AppBar
        elevation: 0,
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // توسيط الصورة والأزرار
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: const Color(
                        0xFFE0BBE4,
                      ), // لون مشابه للوردي في الصور
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: profileImageUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 80,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Display Fields
                  _buildInfoField(
                    label: 'Name of the Kafala Head', //
                    value: name,
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 15),
                  _buildInfoField(
                    label: 'Enter your email (for login)', //
                    value: email,
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 15),
                  _buildInfoField(
                    label: 'Enter mobile number', //
                    value: phone,
                    icon: Icons.phone,
                  ),
                  const SizedBox(height: 15),
                  _buildInfoField(
                    label: 'Password', //
                    value: '********', // لا تعرض كلمة المرور الحقيقية
                    icon: Icons.lock,
                    obscureText: true,
                  ),
                  const SizedBox(height: 15),
                  _buildInfoField(
                    label: 'Name of the institution', //
                    value: institutionName,
                    icon: Icons.business,
                  ),
                  const SizedBox(height: 15),
                  _buildInfoField(
                    label: 'Institution Address',
                    value: address,
                    icon: Icons.location_on,
                  ),
                  const SizedBox(height: 15),
                  _buildInfoField(
                    label: 'Institution Website (Optional)', //
                    value: website,
                    icon: Icons.language,
                  ),
                  const SizedBox(height: 15),
                  _buildInfoField(
                    label: 'Functional Lodgment', //
                    value: functionalLodgment,
                    icon: Icons.work,
                  ),
                  const SizedBox(height: 15),
                  _buildInfoField(
                    label: 'Area Responsible for', //
                    value: areaResponsibleFor,
                    icon: Icons.map,
                  ),
                  const SizedBox(height: 30),

                  // Edit Button
                  Center(
                    child: ElevatedButton(
                      onPressed: _navigateToEditProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFC8A2C8,
                        ), // لون زر "Edit" في شاشة الكفيل
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // Helper widget for displaying info fields (read-only)
  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10.0, bottom: 5.0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4C7F7F),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF6DAF97)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF4C7F7F)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  obscureText ? '********' : value, // لإخفاء كلمة المرور
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
