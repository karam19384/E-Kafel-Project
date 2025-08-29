// lib/src/screens/orphans_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'package:e_kafel/src/services/firestore_service.dart';
import 'package:e_kafel/src/widgets/app_drawer.dart';
import 'package:e_kafel/src/screens/login_screen.dart';

class OrphansListScreen extends StatefulWidget {
  final bool showIncomplete;

  const OrphansListScreen({super.key, this.showIncomplete = false});

  @override
  State<OrphansListScreen> createState() => _OrphansListScreenState();
}

class _OrphansListScreenState extends State<OrphansListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String? _institutionId;
  bool _isSearching = false;

  // Filter & Sort variables
  RangeValues _supportRange = const RangeValues(0, 10000);
  DateTime _birthStart = DateTime(2000, 1, 1);
  DateTime _birthEnd = DateTime.now();
  DateTime _deathStart = DateTime(2000, 1, 1);
  DateTime _deathEnd = DateTime.now();
  DateTime _sponsorshipStart = DateTime(2000, 1, 1);
  DateTime _sponsorshipEnd = DateTime.now();
  String? _gender;
  String? _ageGroup;
  String _sortField = 'name';
  bool _sortAsc = true;

  Stream<QuerySnapshot>? _orphansStream;

  @override
  void initState() {
    super.initState();
    _fetchInstitutionId();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInstitutionId() async {
    final homeState = BlocProvider.of<HomeBloc>(context).state;
    if (homeState is HomeLoaded) {
      _institutionId = homeState.institutionId;
      _applyFilters();
    }
  }

  void _applyFilters() {
    if (_institutionId == null) return;

    Query query = _firestoreService.getOrphansQuery(
      institutionId: _institutionId!,
      showIncomplete: widget.showIncomplete,
    );

    // Filter by support range
    query = query
        .where('totalSupport', isGreaterThanOrEqualTo: _supportRange.start)
        .where('totalSupport', isLessThanOrEqualTo: _supportRange.end);

    // Filter by birth date
    query = query
        .where(
          'birthDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_birthStart),
        )
        .where('birthDate', isLessThanOrEqualTo: Timestamp.fromDate(_birthEnd));

    // Filter by death date
    query = query
        .where(
          'deathDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_deathStart),
        )
        .where('deathDate', isLessThanOrEqualTo: Timestamp.fromDate(_deathEnd));

    // Filter by sponsorship date
    query = query
        .where(
          'latestSupportDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_sponsorshipStart),
        )
        .where(
          'latestSupportDate',
          isLessThanOrEqualTo: Timestamp.fromDate(_sponsorshipEnd),
        );

    // Gender filter
    if (_gender != null && _gender!.isNotEmpty) {
      query = query.where('gender', isEqualTo: _gender);
    }

    // Age filter
    if (_ageGroup != null && _ageGroup!.isNotEmpty) {
      query = query.where('ageGroup', isEqualTo: _ageGroup);
    }

    // Apply sorting
    query = query.orderBy(_sortField, descending: !_sortAsc);

    setState(() {
      _orphansStream = query.snapshots();
    });
  }

  void _resetFilters() {
    setState(() {
      _supportRange = const RangeValues(0, 10000);
      _birthStart = DateTime(2000, 1, 1);
      _birthEnd = DateTime.now();
      _deathStart = DateTime(2000, 1, 1);
      _deathEnd = DateTime.now();
      _sponsorshipStart = DateTime(2000, 1, 1);
      _sponsorshipEnd = DateTime.now();
      _gender = null;
      _ageGroup = null;
      _sortField = 'name';
      _sortAsc = true;
      _searchController.clear();
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0E8EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6DAF97),
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search by Name, ID, Orphan No, or Guardian',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
              )
            : const Text('Orphans List'),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onPressed: () => _openFilterSortSheet(),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _institutionId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _orphansStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No orphans found.'));
                }

                final filteredOrphans = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final searchText = _searchController.text.toLowerCase();
                  return data['name'].toString().toLowerCase().contains(
                        searchText,
                      ) ||
                      data['idNumber'].toString().toLowerCase().contains(
                        searchText,
                      ) ||
                      data['orphanNo'].toString().toLowerCase().contains(
                        searchText,
                      ) ||
                      data['guardianPhone'].toString().toLowerCase().contains(
                        searchText,
                      );
                }).toList();

                if (filteredOrphans.isEmpty) {
                  return const Center(
                    child: Text('No matching orphans found.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredOrphans.length,
                  itemBuilder: (context, index) {
                    final orphanData =
                        filteredOrphans[index].data() as Map<String, dynamic>;
                    String latestSupport = 'N/A';
                    if (orphanData['latestSupportDate'] is Timestamp) {
                      latestSupport =
                          (orphanData['latestSupportDate'] as Timestamp)
                              .toDate()
                              .toLocal()
                              .toString()
                              .split(' ')[0];
                    }
                    return _buildOrphanCard(
                      name: orphanData['name'] ?? 'Unknown',
                      phone: orphanData['guardianPhone'] ?? 'N/A',
                      latestSupport: 'Latest Support: $latestSupport',
                      imageUrl: orphanData['profileImageUrl'] ?? '',
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildOrphanCard({
    required String name,
    required String phone,
    required String latestSupport,
    String? imageUrl,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF6DAF97),
              backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : null,
              child: imageUrl == null || imageUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 30)
                  : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name: $name',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4C7F7F),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Phone: $phone',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    latestSupport,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilterSortSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filters & Sorting',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4C7F7F),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Support Amount (\$0 - \$10000)'),
                    RangeSlider(
                      values: _supportRange,
                      min: 0,
                      max: 10000,
                      divisions: 100,
                      labels: RangeLabels(
                        _supportRange.start.round().toString(),
                        _supportRange.end.round().toString(),
                      ),
                      onChanged: (values) =>
                          setSheetState(() => _supportRange = values),
                    ),
                    const SizedBox(height: 20),
                    _buildDropdownSheet(
                      label: 'Gender',
                      value: _gender,
                      items: ['Male', 'Female'],
                      onChanged: (val) => setSheetState(() => _gender = val),
                    ),
                    _buildDropdownSheet(
                      label: 'Age Group',
                      value: _ageGroup,
                      items: ['0-5', '6-10', '11-15', '16-18', '19+'],
                      onChanged: (val) => setSheetState(() => _ageGroup = val),
                    ),
                    const SizedBox(height: 20),
                    const Text('Sort by'),
                    DropdownButton<String>(
                      value: _sortField,
                      items: [
                        DropdownMenuItem(
                          value: 'name',
                          child: const Text('Name'),
                        ),
                        DropdownMenuItem(
                          value: 'age',
                          child: const Text('Age'),
                        ),
                        DropdownMenuItem(
                          value: 'birthDate',
                          child: const Text('Birth Date'),
                        ),
                        DropdownMenuItem(
                          value: 'deathDate',
                          child: const Text('Death Date'),
                        ),
                        DropdownMenuItem(
                          value: 'totalSupport',
                          child: const Text('Total Support'),
                        ),
                      ],
                      onChanged: (val) =>
                          setSheetState(() => _sortField = val!),
                    ),
                    Row(
                      children: [
                        const Text('Ascending'),
                        Switch(
                          value: _sortAsc,
                          onChanged: (val) =>
                              setSheetState(() => _sortAsc = val),
                        ),
                        const Text('Descending'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          _applyFilters();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC8A2C8),
                        ),
                        child: const Text('Apply Filters & Sort'),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          _resetFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Reset Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdownSheet({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          margin: const EdgeInsets.only(top: 8, bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF4C7F7F)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text('Select $label'),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoaded) {
          return AppDrawer(
            userName: state.userName,
            userRole: state.userRole,
            profileImageUrl: state.profileImageUrl,
            orphanCount: state.orphanSponsored,
            taskCount: state.completedTasksPercentage,
            visitCount: state.completedFieldVisits,
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
