// lib/src/screens/orphans/orphan_archiv_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/blocs/orphans/orphans_bloc.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'package:e_kafel/src/widgets/app_drawer.dart';
import 'package:e_kafel/src/screens/Auth/login_screen.dart';
import '../../models/orphan_model.dart';
import 'orphan_details_screen.dart';

class OrphanArchivedListScreen extends StatefulWidget {
  static const routeName = '/orphan_archive_list_screen';

  const OrphanArchivedListScreen({super.key});

  @override
  State<OrphanArchivedListScreen> createState() =>
      _OrphanArchivedListScreenState();
}

class _OrphanArchivedListScreenState extends State<OrphanArchivedListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Filter variables based on OrphanModel from add screen
  String? _genderFilter;
  String? _orphanTypeFilter;
  String? _governorateFilter;
  String? _educationStatusFilter;
  String? _sponsorshipStatusFilter;
  String? _healthStatusFilter;
  String? _housingConditionFilter;
  String _sortField = 'fullName';
  bool _sortAsc = true;

  // قوائم الفلاتر المنسدلة (مطابقة للشاشة الأصلية)
  final List<String> _governorates = [
    'غزة',
    'شمال غزة',
    'خان يونس',
    'رفح',
    'المنطقة الوسطى',
  ];

  final List<String> _healthOptions = [
    'سليم',
    'سكري',
    'ربو',
    'فقر دم',
    'حساسية',
    'أمراض قلب',
    'إعاقة سمعية',
    'إعاقة بصرية',
    'إعاقة حركية',
    'أخرى',
  ];

  final List<String> _housingConditions = ['ممتاز', 'جيد', 'سيء'];

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
      context.read<OrphansBloc>().add(
        LoadOrphans(institutionId: homeState.institutionId),
      );
    }
  }

  List<Orphan> _applyFilters(List<Orphan> orphans) {
    final searchText = _searchController.text.toLowerCase();

    var filtered = orphans.where((orphan) {
      // Show ONLY archived orphans
      if (orphan.isArchived != true) return false;

      // Search filter - بحث شامل في الحقول المهمة
      if (searchText.isNotEmpty) {
        final matchesSearch =
            orphan.orphanFullName.toLowerCase().contains(searchText) ||
            (orphan.orphanIdNumber.toString()).contains(searchText) ||
            (orphan.orphanNo.toString()).contains(searchText) ||
            (orphan.mobileNumber?.toString() ?? '').contains(searchText) ||
            (orphan.familyName.toLowerCase()).contains(searchText) ||
            (orphan.fatherName.toLowerCase()).contains(searchText) ||
            (orphan.neighborhood?.toLowerCase() ?? '').contains(searchText);

        if (!matchesSearch) return false;
      }

      // Gender filter
      if (_genderFilter != null && _genderFilter!.isNotEmpty) {
        if (orphan.gender != _genderFilter) return false;
      }

      // Orphan type filter
      if (_orphanTypeFilter != null && _orphanTypeFilter!.isNotEmpty) {
        if (orphan.orphanType != _orphanTypeFilter) return false;
      }

      // Governorate filter
      if (_governorateFilter != null && _governorateFilter!.isNotEmpty) {
        if (orphan.governorate != _governorateFilter) return false;
      }

      // Education status filter
      if (_educationStatusFilter != null &&
          _educationStatusFilter!.isNotEmpty) {
        if (orphan.educationStatus != _educationStatusFilter) return false;
      }

      // Sponsorship status filter
      if (_sponsorshipStatusFilter != null &&
          _sponsorshipStatusFilter!.isNotEmpty) {
        if (orphan.sponsorshipStatus != _sponsorshipStatusFilter) return false;
      }

      // Health status filter
      if (_healthStatusFilter != null && _healthStatusFilter!.isNotEmpty) {
        if (orphan.healthStatus != _healthStatusFilter) return false;
      }

      // Housing condition filter
      if (_housingConditionFilter != null &&
          _housingConditionFilter!.isNotEmpty) {
        if (orphan.housingCondition != _housingConditionFilter) return false;
      }

      return true;
    }).toList();

    // Sorting
    filtered.sort((a, b) {
      dynamic aValue;
      dynamic bValue;

      switch (_sortField) {
        case 'fullName':
          aValue = a.orphanFullName.toLowerCase();
          bValue = b.orphanFullName.toLowerCase();
          break;
        case 'age':
          final now = DateTime.now();
          aValue = now.difference(a.dateOfBirth).inDays ~/ 365;
          bValue = now.difference(b.dateOfBirth).inDays ~/ 365;
          break;
        case 'orphanNo':
          aValue = a.orphanNo;
          bValue = b.orphanNo;
          break;
        case 'orphanIdNumber':
          aValue = a.orphanIdNumber;
          bValue = b.orphanIdNumber;
          break;
        case 'dateOfBirth':
          aValue = a.dateOfBirth;
          bValue = b.dateOfBirth;
          break;
        case 'sponsorshipAmount':
          aValue = a.sponsorshipAmount ?? 0;
          bValue = b.sponsorshipAmount ?? 0;
          break;
        case 'createdAt':
          aValue = a.createdAt;
          bValue = b.createdAt;
          break;
        case 'governorate':
          aValue = a.governorate ?? '';
          bValue = b.governorate ?? '';
          break;
        default:
          aValue = a.orphanFullName.toLowerCase();
          bValue = b.orphanFullName.toLowerCase();
      }

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
      _genderFilter = null;
      _orphanTypeFilter = null;
      _governorateFilter = null;
      _educationStatusFilter = null;
      _sponsorshipStatusFilter = null;
      _healthStatusFilter = null;
      _housingConditionFilter = null;
      _sortField = 'fullName';
      _sortAsc = true;
      _searchController.clear();
    });
  }

  // حساب العمر من تاريخ الميلاد
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // الحصول على معلومات السكن
  String _getHousingInfo(Orphan orphan) {
    final List<String> info = [];
    if (orphan.governorate != null && orphan.governorate!.isNotEmpty) {
      info.add(orphan.governorate!);
    }
    if (orphan.city != null && orphan.city!.isNotEmpty) {
      info.add(orphan.city!);
    }
    if (orphan.housingCondition != null &&
        orphan.housingCondition!.isNotEmpty) {
      info.add('سكن: ${orphan.housingCondition!}');
    }
    return info.isNotEmpty ? info.join(' • ') : 'لا توجد معلومات سكن';
  }

  // الحصول على معلومات التعليم

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
                  hintText: 'ابحث بالاسم، الرقم القومي، رقم اليتيم، أو المنطقة',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
              )
            : const Text(
                'الأيتام المؤرشفون',
                style: TextStyle(color: Colors.white),
              ),
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
            return Center(child: Text('خطأ: ${state.message}'));
          } else if (state is OrphansLoaded) {
            final List<Orphan> filteredOrphans = _applyFilters(state.orphans);

            if (filteredOrphans.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.archive, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'لا يوجد أيتام مؤرشفين',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    if (_searchController.text.isNotEmpty ||
                        _genderFilter != null ||
                        _orphanTypeFilter != null)
                      TextButton(
                        onPressed: _resetFilters,
                        child: const Text('إعادة تعيين الفلاتر'),
                      ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredOrphans.length,
              itemBuilder: (context, index) {
                final Orphan orphan = filteredOrphans[index];
                final age = _calculateAge(orphan.dateOfBirth);
                final archiveDate = orphan.archivedAt ?? orphan.updatedAt;

                return _buildOrphanCard(
                  orphan: orphan,
                  age: age,
                  archiveDate: archiveDate,
                  onTap: () {
                    if (orphan.id != null && orphan.id!.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              OrphanDetailsScreen(orphanId: orphan.id!, institutionId: orphan.institutionId,),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('لا يوجد معرف للوثيقة (id)'),
                        ),
                      );
                    }
                  },
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
    required Orphan orphan,
    required int age,
    required DateTime archiveDate,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 15),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF6DAF97),
                    backgroundImage:
                        orphan.orphanPhotoUrl != null &&
                            orphan.orphanPhotoUrl!.isNotEmpty
                        ? NetworkImage(orphan.orphanPhotoUrl!)
                        : null,
                    child:
                        orphan.orphanPhotoUrl == null ||
                            orphan.orphanPhotoUrl!.isEmpty
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.archive,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orphan.orphanFullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4C7F7F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'العمر: $age سنة • ${orphan.gender} • ${orphan.orphanType}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (orphan.healthStatus != null &&
                        orphan.healthStatus!.isNotEmpty)
                      Text(
                        'الصحة: ${orphan.healthStatus!}',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _getHousingInfo(orphan),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (orphan.sponsorshipStatus != null &&
                        orphan.sponsorshipStatus!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: orphan.sponsorshipStatus == 'مكفول'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: orphan.sponsorshipStatus == 'مكفول'
                                ? Colors.green
                                : Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'الكفالة: ${orphan.sponsorshipStatus!}',
                          style: TextStyle(
                            fontSize: 11,
                            color: orphan.sponsorshipStatus == 'مكفول'
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'أرشف في: ${archiveDate.toLocal().toString().split(' ').first}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF4C7F7F)),
            ],
          ),
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
                      'الفلاتر والترتيب',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4C7F7F),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Gender Filter
                    _buildDropdownSheet(
                      label: 'الجنس',
                      value: _genderFilter,
                      items: const ['ذكر', 'أنثى'],
                      onChanged: (val) =>
                          setSheetState(() => _genderFilter = val),
                    ),

                    // Orphan Type Filter
                    _buildDropdownSheet(
                      label: 'نوع اليتم',
                      value: _orphanTypeFilter,
                      items: const ['يتيم الأب', 'يتيم الأم', 'يتيم الوالدين'],
                      onChanged: (val) =>
                          setSheetState(() => _orphanTypeFilter = val),
                    ),

                    // Governorate Filter
                    _buildDropdownSheet(
                      label: 'المحافظة',
                      value: _governorateFilter,
                      items: _governorates,
                      onChanged: (val) =>
                          setSheetState(() => _governorateFilter = val),
                    ),

                    // Health Status Filter
                    _buildDropdownSheet(
                      label: 'الحالة الصحية',
                      value: _healthStatusFilter,
                      items: _healthOptions,
                      onChanged: (val) =>
                          setSheetState(() => _healthStatusFilter = val),
                    ),

                    // Housing Condition Filter
                    _buildDropdownSheet(
                      label: 'حالة السكن',
                      value: _housingConditionFilter,
                      items: _housingConditions,
                      onChanged: (val) =>
                          setSheetState(() => _housingConditionFilter = val),
                    ),

                    // Sponsorship Status Filter
                    _buildDropdownSheet(
                      label: 'حالة الكفالة',
                      value: _sponsorshipStatusFilter,
                      items: const ['مكفول', 'غير مكفول'],
                      onChanged: (val) =>
                          setSheetState(() => _sponsorshipStatusFilter = val),
                    ),

                    const SizedBox(height: 20),
                    const Text('ترتيب حسب'),
                    DropdownButton<String>(
                      value: _sortField,
                      items: [
                        const DropdownMenuItem(
                          value: 'fullName',
                          child: Text('الاسم'),
                        ),
                        const DropdownMenuItem(
                          value: 'age',
                          child: Text('العمر'),
                        ),
                        const DropdownMenuItem(
                          value: 'orphanNo',
                          child: Text('رقم اليتيم'),
                        ),
                        const DropdownMenuItem(
                          value: 'orphanIdNumber',
                          child: Text('الرقم القومي'),
                        ),
                        const DropdownMenuItem(
                          value: 'dateOfBirth',
                          child: Text('تاريخ الميلاد'),
                        ),
                        const DropdownMenuItem(
                          value: 'sponsorshipAmount',
                          child: Text('مبلغ الكفالة'),
                        ),
                        const DropdownMenuItem(
                          value: 'governorate',
                          child: Text('المحافظة'),
                        ),
                        const DropdownMenuItem(
                          value: 'createdAt',
                          child: Text('تاريخ الإضافة'),
                        ),
                      ],
                      onChanged: (val) =>
                          setSheetState(() => _sortField = val!),
                    ),
                    Row(
                      children: [
                        const Text('تصاعدي'),
                        Switch(
                          value: _sortAsc,
                          onChanged: (val) =>
                              setSheetState(() => _sortAsc = val),
                        ),
                        const Text('تنازلي'),
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
                          minimumSize: const Size(200, 50),
                        ),
                        child: const Text('تطبيق الفلاتر والترتيب'),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          _resetFilters();
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: const Text('إعادة تعيين الفلاتر'),
                      ),
                    ),
                    const SizedBox(height: 20),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
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
              hint: Text('اختر $label'),
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
          userName: 'جاري التحميل...',
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
