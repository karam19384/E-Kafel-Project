import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/orphans/orphans_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/models/orphan_model.dart';
import 'package:e_kafel/src/screens/orphans/orphan_details_screen.dart';
import 'package:e_kafel/src/screens/orphans/add_new_orphan_screen.dart';

class OrphansListScreen extends StatefulWidget {
  static const routeName = '/orphans_list_screen';

  const OrphansListScreen({super.key});

  @override
  State<OrphansListScreen> createState() => _OrphansListScreenState();
}

class _OrphansListScreenState extends State<OrphansListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showSearchField = false;
  String? _genderFilter;
  String? _typeFilter;
  String? _gradeFilter;
  String? _govFilter;
  String _sortBy = 'name'; // name, date, age

  // دالة حساب العمر من تاريخ الميلاد
  int _calculateAge(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return 0;
    
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    
    // التحقق إذا لم يحن عيد الميلاد بعد هذا العام
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    
    return age;
  }

  // دالة مساعدة لعرض العمر بشكل نصي
  String _getAgeDisplay(DateTime? dateOfBirth) {
    final age = _calculateAge(dateOfBirth);
    return age > 0 ? '$age سنة' : 'غير محدد';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeState = context.read<HomeBloc>().state;
      if (homeState is HomeLoaded) {
        context.read<OrphansBloc>().add(
          LoadOrphans(institutionId: homeState.institutionId),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchCtrl.clear();
      _genderFilter = null;
      _typeFilter = null;
      _gradeFilter = null;
      _govFilter = null;
      _sortBy = 'name';
    });
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.filter_list, color: Color(0xFF4C7F7F)),
              SizedBox(width: 8),
              Text('تصفية وترتيب'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // تصفية حسب الجنس
                _buildFilterSection(
                  title: 'الجنس',
                  value: _genderFilter,
                  options: const ['ذكر', 'أنثى'],
                  onChanged: (value) => setDialogState(() => _genderFilter = value),
                ),
                
                const SizedBox(height: 16),
                
                // تصفية حسب نوع اليتم
                _buildFilterSection(
                  title: 'نوع اليتم',
                  value: _typeFilter,
                  options: const ['يتيم الأب', 'يتيم الأم', 'يتيم الوالدين'],
                  onChanged: (value) => setDialogState(() => _typeFilter = value),
                ),
                
                const SizedBox(height: 16),
                
                // تصفية حسب الصف
                _buildFilterSection(
                  title: 'الصف',
                  value: _gradeFilter,
                  options: const [
                    'الأول','الثاني','الثالث','الرابع','الخامس','السادس',
                    'السابع','الثامن','التاسع','الأول ثانوي','الثاني ثانوي','الثالث ثانوي'
                  ],
                  onChanged: (value) => setDialogState(() => _gradeFilter = value),
                ),
                
                const SizedBox(height: 16),
                
                // تصفية حسب المحافظة
                _buildFilterSection(
                  title: 'المحافظة',
                  value: _govFilter,
                  options: const ['الوسطى','غزة','شمال غزة','خانيونس','رفح'],
                  onChanged: (value) => setDialogState(() => _govFilter = value),
                ),
                
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                
                // ترتيب النتائج
                _buildSortSection(setDialogState),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearFilters();
                Navigator.pop(context);
              },
              child: const Text('مسح الكل', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C7F7F),
                foregroundColor: Colors.white,
              ),
              child: const Text('تطبيق'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required String? value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = value == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                onChanged(selected ? option : null);
              },
              backgroundColor: Colors.grey[200],
              selectedColor: const Color(0xFF4C7F7F).withOpacity(0.2),
              checkmarkColor: const Color(0xFF4C7F7F),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF4C7F7F) : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSortSection(StateSetter setDialogState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ترتيب النتائج',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildSortOption('الاسم', 'name', setDialogState),
            _buildSortOption('التاريخ', 'date', setDialogState),
            _buildSortOption('العمر', 'age', setDialogState),
          ],
        ),
      ],
    );
  }

  Widget _buildSortOption(String label, String value, StateSetter setDialogState) {
    final isSelected = _sortBy == value;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            setDialogState(() => _sortBy = value);
          },
          backgroundColor: Colors.grey[200],
          selectedColor: const Color(0xFF4C7F7F).withOpacity(0.2),
          checkmarkColor: const Color(0xFF4C7F7F),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFF4C7F7F) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  List<Orphan> _applyFilters(List<Orphan> list) {
    final q = _searchCtrl.text.trim().toLowerCase();
    var filteredList = list.where((o) {
      if (o.isArchived == true) return false;

      final name = o.orphanFullName.toLowerCase();
      final matchesSearch = q.isEmpty || name.contains(q);
      final matchesGender = _genderFilter == null || o.gender == _genderFilter;
      final matchesType = _typeFilter == null || o.orphanType == _typeFilter;
      final matchesGrade = _gradeFilter == null || (o.grade ?? '') == _gradeFilter;
      final matchesGov = _govFilter == null || (o.governorate ?? '') == _govFilter;

      return matchesSearch && matchesGender && matchesType && matchesGrade && matchesGov;
    }).toList();

    // تطبيق الترتيب
    filteredList.sort((a, b) {
      switch (_sortBy) {
        case 'date':
          return (b.createdAt).compareTo(a.createdAt);
        case 'age':
          final ageA = _calculateAge(a.dateOfBirth);
          final ageB = _calculateAge(b.dateOfBirth);
          return ageA.compareTo(ageB);
        case 'name':
        default:
          return a.orphanFullName.compareTo(b.orphanFullName);
      }
    });

    return filteredList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocBuilder<OrphansBloc, OrphansState>(
        builder: (context, state) {
          if (state is OrphansLoading || state is OrphansInitial) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4C7F7F)),
              ),
            );
          }
          if (state is OrphansError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'حدث خطأ: ${state.message}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final homeState = context.read<HomeBloc>().state;
                      if (homeState is HomeLoaded) {
                        context.read<OrphansBloc>().add(
                          LoadOrphans(institutionId: homeState.institutionId),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C7F7F),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }
          if (state is OrphansLoaded) {
            final items = _applyFilters(state.orphans);
            if (items.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'لا يوجد نتائج',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final o = items[i];
                return _OrphanCard(
                  orphan: o,
                  age: _getAgeDisplay(o.dateOfBirth), // تمرير العمر المحسوب
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrphanDetailsScreen(
                          orphanId: o.id ?? '',
                          institutionId: o.institutionId,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'orphans_list_fab',
        backgroundColor: const Color(0xFF4C7F7F),
        child: const Icon(Icons.person_add, color: Colors.white),
        onPressed: () {
          final homeState = context.read<HomeBloc>().state;
          String institutionId = '';
          String kafalaHeadId = '';
          if (homeState is HomeLoaded) {
            institutionId = homeState.institutionId;
            kafalaHeadId = homeState.kafalaHeadId;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddNewOrphanScreen(
                institutionId: institutionId,
                kafalaHeadId: kafalaHeadId,
              ),
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: _showSearchField 
          ? TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'ابحث باسم اليتيم...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
            )
          : const Text('قائمة الأيتام'),
      centerTitle: true,
      backgroundColor: const Color(0xFF4C7F7F),
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        // أيقونة البحث
        if (!_showSearchField)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _showSearchField = true;
              });
            },
          ),
        
        // أيقونة التصفية والترتيب
        IconButton(
          icon: Badge(
            isLabelVisible: _genderFilter != null || 
                           _typeFilter != null || 
                           _gradeFilter != null || 
                           _govFilter != null,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.filter_list),
          ),
          onPressed: () => _showFilterDialog(context),
        ),
        
        // أيقونة إغلاق البحث
        if (_showSearchField)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _showSearchField = false;
                _searchCtrl.clear();
              });
            },
          ),
      ],
    );
  }
}

class _OrphanCard extends StatelessWidget {
  final Orphan orphan;
  final String age;
  final VoidCallback onTap;

  const _OrphanCard({
    required this.orphan,
    required this.age,
    required this.onTap,
  });

  String _formatPhone(int? n) => n == null ? 'لا يوجد' : n.toString();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // الصورة
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  image: (orphan.orphanPhotoUrl != null && orphan.orphanPhotoUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(orphan.orphanPhotoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (orphan.orphanPhotoUrl == null || orphan.orphanPhotoUrl!.isEmpty)
                    ? Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.grey[400],
                      )
                    : null,
              ),
              
              const SizedBox(width: 16),
              
              // المعلومات
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orphan.orphanFullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📱 ${_formatPhone(orphan.mobileNumber)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '⚧ ${orphan.gender} • 🎂 $age • 🏫 ${orphan.gender}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // السهم
              Icon(
                Icons.chevron_left,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}