import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // لإدارة تنسيق التاريخ

class EditOrphanDetailsScreen extends StatefulWidget {
  final String orphanId;

  const EditOrphanDetailsScreen({super.key, required this.orphanId});

  @override
  State<EditOrphanDetailsScreen> createState() =>
      _EditOrphanDetailsScreenState();
}

class _EditOrphanDetailsScreenState extends State<EditOrphanDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for text input fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _orphanNoController = TextEditingController();
  final TextEditingController _profileImageUrlController =
      TextEditingController();
  final TextEditingController _totalSupportController =
      TextEditingController(); // For range slider display or single input

  // Variables for dropdowns and date picker
  DateTime? _latestSupportDate;
  String? _selectedFamilyMembers;
  String? _selectedAge;
  String? _selectedGovernorate;
  String? _selectedRelationship;
  String? _selectedGender;
  String? _selectedCauseOfDeath;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrphanDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _idNumberController.dispose();
    _orphanNoController.dispose();
    _profileImageUrlController.dispose();
    _totalSupportController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrphanDetails() async {
    try {
      final docSnapshot = await _firestore
          .collection('orphans')
          .doc(widget.orphanId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;

        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _idNumberController.text = data['idNumber'] ?? '';
          _orphanNoController.text = data['orphanNo'] ?? '';
          _profileImageUrlController.text = data['profileImageUrl'] ?? '';
          _totalSupportController.text = (data['totalSupport'] ?? 0)
              .toString(); // Assuming a single value for display

          if (data['latestSupportDate'] is Timestamp) {
            _latestSupportDate = (data['latestSupportDate'] as Timestamp)
                .toDate();
          } else if (data['latestSupportDate'] is String) {
            try {
              _latestSupportDate = DateTime.parse(data['latestSupportDate']);
            } catch (e) {
              if (kDebugMode) {
                
                  print(
                'Error parsing date string: ${data['latestSupportDate']} - $e',
              );
                
              }
              _latestSupportDate = null;
            }
          }

          _selectedFamilyMembers = data['familyMembers']?.toString();
          _selectedAge = data['age']
              ?.toString(); // Assuming age is stored as a string or can be converted
          _selectedGovernorate = data['governorate'];
          _selectedRelationship = data['relationshipToDeceased'];
          _selectedGender = data['gender'];
          _selectedCauseOfDeath = data['causeOfDeath'];

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
      if (kDebugMode) {
        print('Error fetching orphan details: $e');
      }
    }
  }

  Future<void> _updateOrphanDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('orphans').doc(widget.orphanId).update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'idNumber': _idNumberController.text,
        'orphanNo': _orphanNoController.text,
        'profileImageUrl': _profileImageUrlController.text,
        'totalSupport': double.tryParse(_totalSupportController.text) ?? 0.0,
        'latestSupportDate': _latestSupportDate != null
            ? Timestamp.fromDate(_latestSupportDate!)
            : null,
        'familyMembers': _selectedFamilyMembers != null
            ? int.tryParse(_selectedFamilyMembers!)
            : null,
        'age': _selectedAge != null
            ? int.tryParse(_selectedAge!)
            : null, // Store as int if possible
        'governorate': _selectedGovernorate,
        'relationshipToDeceased': _selectedRelationship,
        'gender': _selectedGender,
        'causeOfDeath': _selectedCauseOfDeath,
        // institutionId should not be changed here, it's assigned on creation
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orphan details updated successfully!')),
        );
        Navigator.pop(context, true); // Pop with true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update orphan details: $e')),
        );
      }
      if (kDebugMode) {
        print('Error updating orphan details: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0E8EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6DAF97),
        elevation: 0,
        title: const Text(
          'Edit Orphan Details',
          style: TextStyle(color: Colors.white),
        ),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image URL (optional, consider image picker for real app)
                    _buildTextField(
                      controller: _profileImageUrlController,
                      label: 'Profile Image URL',
                      hintText: 'Enter URL for orphan\'s profile image',
                      icon: Icons.image,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 15),

                    // Name
                    _buildTextField(
                      controller: _nameController,
                      label: 'Name',
                      hintText: 'Enter orphan\'s full name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Phone
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone',
                      hintText: 'Enter orphan\'s phone number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // ID Number (if applicable)
                    _buildTextField(
                      controller: _idNumberController,
                      label: 'ID Number',
                      hintText: 'Enter orphan\'s ID number',
                      icon: Icons.credit_card,
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 15),

                    // Orphan No. (if applicable)
                    _buildTextField(
                      controller: _orphanNoController,
                      label: 'Orphan Number',
                      hintText: 'Enter orphan\'s unique number',
                      icon: Icons.numbers,
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 15),

                    // Total Support (assuming a single value field for simplicity in editing)
                    _buildTextField(
                      controller: _totalSupportController,
                      label: 'Total Support Amount (\$)',
                      hintText: 'e.g., 500.00',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter total support';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Latest Support Date
                    _buildDateField(
                      label: 'Latest Support Date',
                      selectedDate: _latestSupportDate,
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _latestSupportDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (pickedDate != null &&
                            pickedDate != _latestSupportDate) {
                          setState(() {
                            _latestSupportDate = pickedDate;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Dropdown for Family Members
                    _buildDropdownField<String>(
                      label: 'Total Family Members',
                      value: _selectedFamilyMembers,
                      items: [
                        '1',
                        '2',
                        '3',
                        '4',
                        '5',
                        '6',
                        '7',
                        '8',
                        '9',
                        '10+',
                      ], // Adjust as needed
                      onChanged: (value) {
                        setState(() {
                          _selectedFamilyMembers = value;
                        });
                      },
                      icon: Icons.group,
                      validator: (value) {
                        if (value == null) {
                          return 'Please select family members';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Dropdown for Age
                    _buildDropdownField<String>(
                      label: 'Age',
                      value: _selectedAge,
                      items:
                          List<String>.generate(19, (i) => (i + 1).toString()) +
                          ['19+'], // 1-18, then 19+
                      onChanged: (value) {
                        setState(() {
                          _selectedAge = value;
                        });
                      },
                      icon: Icons.child_care,
                      validator: (value) {
                        if (value == null) {
                          return 'Please select age';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Dropdown for Governorate
                    _buildDropdownField<String>(
                      label: 'Governorate',
                      value: _selectedGovernorate,
                      items: [
                        'North Gaza',
                        'Gaza',
                        'Khan Yunis',
                        'Rafah',
                        'Deir al-Balah',
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGovernorate = value;
                        });
                      },
                      icon: Icons.location_on,
                      validator: (value) {
                        if (value == null) {
                          return 'Please select governorate';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Dropdown for Relationship to deceased
                    _buildDropdownField<String>(
                      label: 'Relationship to deceased',
                      value: _selectedRelationship,
                      items: ['Father', 'Mother', 'Both', 'Other'],
                      onChanged: (value) {
                        setState(() {
                          _selectedRelationship = value;
                        });
                      },
                      icon: Icons.family_restroom,
                      validator: (value) {
                        if (value == null) {
                          return 'Please select relationship';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Dropdown for Gender
                    _buildDropdownField<String>(
                      label: 'Gender',
                      value: _selectedGender,
                      items: ['Male', 'Female'],
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                      icon: Icons.people,
                      validator: (value) {
                        if (value == null) {
                          return 'Please select gender';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Dropdown for Cause of Death
                    _buildDropdownField<String>(
                      label: 'Cause Of Death',
                      value: _selectedCauseOfDeath,
                      items: [
                        'Heart Attack',
                        'Accident',
                        'Illness',
                        'War',
                        'Other',
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCauseOfDeath = value;
                        });
                      },
                      icon: Icons.sick_outlined,
                      validator: (value) {
                        if (value == null) {
                          return 'Please select cause of death';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    Center(
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _updateOrphanDetails,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6DAF97),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Save Changes',
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
            ),
    );
  }

  // Helper widget for building text input fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4C7F7F),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: const Color(0xFF4C7F7F)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6DAF97)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6DAF97)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF4C7F7F), width: 2),
            ),
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 10.0,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  // Helper widget for building date selection field
  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4C7F7F),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'Select Date',
              prefixIcon: const Icon(
                Icons.calendar_today,
                color: Color(0xFF4C7F7F),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF6DAF97)),
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
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 10.0,
              ),
            ),
            child: Text(
              selectedDate == null
                  ? ''
                  : DateFormat('yyyy/MM/dd').format(selectedDate),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget for building dropdown fields
  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4C7F7F),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF4C7F7F)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6DAF97)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6DAF97)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF4C7F7F), width: 2),
            ),
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 10.0,
            ),
          ),
          hint: Text('Select $label'),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4C7F7F)),
          items: items.map<DropdownMenuItem<T>>((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString()),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}
