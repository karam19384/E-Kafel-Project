// lib/src/screens/orphans_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/blocs/orphans/orphans_bloc.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'package:e_kafel/src/widgets/app_drawer.dart';
import 'package:e_kafel/src/screens/login_screen.dart';

class OrphansListScreen extends StatefulWidget {
  final bool showIncomplete;
  const OrphansListScreen({super.key, this.showIncomplete = false});
  @override
  State<OrphansListScreen> createState() => _OrphansListScreenState();
}

class _OrphansListScreenState extends State<OrphansListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  // Filter & Sort variables
  RangeValues _supportRange = const RangeValues(0, 10000);
  String? _gender;
  String? _ageGroup;
  String _sortField = 'name';
  bool _sortAsc = true;

  @override
  void initState() {
    super.initState();
    _fetchOrphans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchOrphans() {
    final homeState = BlocProvider.of<HomeBloc>(context).state;
    if (homeState is HomeLoaded) {
      context.read<OrphansBloc>().add(LoadOrphans());
    }
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> orphans) {
    final searchText = _searchController.text.toLowerCase();

    var filtered = orphans.where((orphan) {
      // Exclude archived
      if (orphan['isArchived'] == true) return false;

      // Search filter
      if (searchText.isNotEmpty) {
        final matchesSearch =
            (orphan['name'] ?? '').toString().toLowerCase().contains(
              searchText,
            ) ||
            (orphan['idNumber'] ?? '').toString().toLowerCase().contains(
              searchText,
            ) ||
            (orphan['orphanNo'] ?? '').toString().toLowerCase().contains(
              searchText,
            ) ||
            (orphan['guardianPhone'] ?? '').toString().toLowerCase().contains(
              searchText,
            );
        if (!matchesSearch) return false;
      }

      // Support range filter
      final totalSupport = (orphan['totalSupport'] ?? 0) as num;
      if (totalSupport < _supportRange.start ||
          totalSupport > _supportRange.end) {
        return false;
      }

      // Gender filter
      if (_gender != null && _gender!.isNotEmpty) {
        if (orphan['gender'] != _gender) return false;
      }

      // Age group filter
      if (_ageGroup != null && _ageGroup!.isNotEmpty) {
        if (orphan['ageGroup'] != _ageGroup) return false;
      }

      return true;
    }).toList();

    // Sorting
    filtered.sort((a, b) {
      dynamic aValue = a[_sortField];
      dynamic bValue = b[_sortField];

      if (aValue is String) aValue = aValue.toLowerCase();
      if (bValue is String) bValue = bValue.toLowerCase();

      int cmp;
      if (aValue is Comparable && bValue is Comparable) {
        cmp = aValue.compareTo(bValue);
      } else {
        cmp = 0;
      }
      return _sortAsc ? cmp : -cmp;
    });

    return filtered;
  }

  void _resetFilters() {
    setState(() {
      _supportRange = const RangeValues(0, 10000);
      _gender = null;
      _ageGroup = null;
      _sortField = 'name';
      _sortAsc = true;
      _searchController.clear();
    });
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
                onChanged: (_) => setState(() {}),
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
                if (_isSearching) _searchController.clear();
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
      body: BlocBuilder<OrphansBloc, OrphansState>(
        builder: (context, state) {
          if (state is OrphansLoading || state is OrphansInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is OrphansError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is OrphansLoaded) {
            final filteredOrphans = _applyFilters(state.orphans);

            if (filteredOrphans.isEmpty) {
              return const Center(child: Text('No orphans found.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredOrphans.length,
              itemBuilder: (context, index) {
                final orphanData = filteredOrphans[index];
                String latestSupport = 'N/A';
                if (orphanData['latestSupportDate'] != null) {
                  final date = orphanData['latestSupportDate'];
                  latestSupport = date is DateTime
                      ? date.toLocal().toString().split(' ')[0]
                      : date.toString();
                }
                return _buildOrphanCard(
                  name: orphanData['name'] ?? 'Unknown',
                  phone: orphanData['mobileNumber'] ?? 'N/A',
                  latestSupport: 'Latest Support: $latestSupport',
                  imageUrl: orphanData['profileImageUrl'] ?? '',
                );
              },
            );
          } else {
            return const SizedBox.shrink();
          }
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
                          setState(() {});
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
                          setState(() {});
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
