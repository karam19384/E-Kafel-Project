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
  String? _genderFilter; // 'ذكر' | 'أنثى'
  String? _typeFilter;   // نوع اليتم
  String? _gradeFilter;  // الصف
  String? _govFilter;    // المحافظة

  @override
  void initState() {
    super.initState();
    // تحميل الأيتام فور توفر بيانات المؤسسة من HomeBloc
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
    });
  }

  // قائمة المحافظات والمدن

  List<Orphan> _applyFilters(List<Orphan> list) {
    final q = _searchCtrl.text.trim().toLowerCase();
    return list.where((o) {
      // استبعاد المؤرشفين
      if (o.isArchived == true) return false;

      final name = o.orphanFullName.toLowerCase();
      final matchesSearch = q.isEmpty || name.contains(q);

      final matchesGender = _genderFilter == null || o.gender == _genderFilter;
      final matchesType = _typeFilter == null || o.orphanType == _typeFilter;
      final matchesGrade = _gradeFilter == null || (o.grade ?? '') == _gradeFilter;
      final matchesGov = _govFilter == null || (o.governorate ?? '') == _govFilter;

      return matchesSearch && matchesGender && matchesType && matchesGrade && matchesGov;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الأيتام'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4C7F7F),
      ),
      body: Column(
        children: [
          _FiltersBar(
            searchCtrl: _searchCtrl,
            onChanged: () => setState(() {}),
            gender: _genderFilter,
            onGender: (v) => setState(() => _genderFilter = v),
            orphanType: _typeFilter,
            onType: (v) => setState(() => _typeFilter = v),
            grade: _gradeFilter,
            onGrade: (v) => setState(() => _gradeFilter = v),
            governorate: _govFilter,
            onGovernorate: (v) => setState(() => _govFilter = v),
            onClear: _clearFilters,
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<OrphansBloc, OrphansState>(
              builder: (context, state) {
                if (state is OrphansLoading || state is OrphansInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is OrphansError) {
                  return Center(child: Text('حدث خطأ: ${state.message}'));
                }
                if (state is OrphansLoaded) {
                  final items = _applyFilters(state.orphans);
                  if (items.isEmpty) {
                    return const Center(child: Text('لا يوجد نتائج'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final o = items[i];
                      return _OrphanCard(
                        orphan: o,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => OrphanDetailsScreen(orphanId: o.id ?? '', institutionId: o.institutionId,),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'orphans_list_fab', // لمنع تعارض الـ Hero
        backgroundColor: const Color(0xFF4C7F7F),
        child: const Icon(Icons.person_add),
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
}

class _FiltersBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final VoidCallback onChanged;
  final String? gender;
  final ValueChanged<String?> onGender;
  final String? orphanType;
  final ValueChanged<String?> onType;
  final String? grade;
  final ValueChanged<String?> onGrade;
  final String? governorate;
  final ValueChanged<String?> onGovernorate;
  final VoidCallback onClear;

  const _FiltersBar({
    required this.searchCtrl,
    required this.onChanged,
    required this.gender,
    required this.onGender,
    required this.orphanType,
    required this.onType,
    required this.grade,
    required this.onGrade,
    required this.governorate,
    required this.onGovernorate,
    required this.onClear,
  });
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F7F7),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          children: [
            TextField(
              controller: searchCtrl,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                hintText: 'بحث بالاسم الكامل...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchCtrl.clear();
                          onChanged();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Dropdown<String>(
                  label: 'الجنس',
                  value: gender,
                  items: const ['ذكر', 'أنثى'],
                  onChanged: onGender,
                ),
                _Dropdown<String>(
                  label: 'نوع اليتم',
                  value: orphanType,
                  items: const ['يتيم الأب', 'يتيم الأم', 'يتيم الوالدين'],
                  onChanged: onType,
                ),
                _Dropdown<String>(
                  label: 'الصف',
                  value: grade,
                  items: const [
                    'الأول','الثاني','الثالث','الرابع','الخامس','السادس',
                    'السابع','الثامن','التاسع','الأول ثانوي','الثاني ثانوي','الثالث ثانوي'
                  ],
                  onChanged: onGrade,
                ),
                _Dropdown<String>(
                  label: 'المحافظة',
                  value: governorate,
                  items: ['الوسطى','غزة','شمال غزة','خانيونس','رفح'],
                  onChanged: onGovernorate,
                ),
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('مسح الفلاتر'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isDense: true,
            isExpanded: true,
            items: items.map((e) => DropdownMenuItem<T>(value: e, child: Text(e.toString()))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _OrphanCard extends StatelessWidget {
  final Orphan orphan;
  final VoidCallback onTap;

  const _OrphanCard({required this.orphan, required this.onTap});

  String _formatPhone(int? n) => n == null ? 'لا يوجد' : n.toString();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundImage: (orphan.orphanPhotoUrl != null && orphan.orphanPhotoUrl!.isNotEmpty)
              ? NetworkImage(orphan.orphanPhotoUrl!)
              : null,
          child: (orphan.orphanPhotoUrl == null || orphan.orphanPhotoUrl!.isEmpty)
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(orphan.orphanFullName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('الهاتف: ${_formatPhone(orphan.mobileNumber)} • الجنس: ${orphan.gender}'),
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }
}
