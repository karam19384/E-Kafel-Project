// lib/src/screens/supervisors/supervisors_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/supervisors/supervisors_bloc.dart';

import 'supervisor_details_screen.dart';
import 'add_new_supervisor_screen.dart';

class SupervisorsScreen extends StatefulWidget {
  final String institutionId;
  final String kafalaHeadId;
  const SupervisorsScreen({
    super.key,
    required this.institutionId,
    required this.kafalaHeadId,
  });

  @override
  State<SupervisorsScreen> createState() => _SupervisorsScreenState();
}

class _SupervisorsScreenState extends State<SupervisorsScreen> {
  final _searchCtrl = TextEditingController();
  String? _userRoleFilter;
  String? _areaFilter;
  bool? _isActiveFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<SupervisorsBloc>().add(
      SearchSupervisors(
        institutionId: widget.institutionId,
        search: _searchCtrl.text.trim().isEmpty
            ? null
            : _searchCtrl.text.trim(),
        userRole: _userRoleFilter,
        areaResponsibleFor: _areaFilter,
        isActive: _isActiveFilter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المشرفون')),
      body: Column(
        children: [
          _filters(),
          Expanded(
            child: BlocBuilder<SupervisorsBloc, SupervisorsState>(
              builder: (context, state) {
                if (state is SupervisorsLoading ||
                    state is SupervisorsInitial) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is SupervisorsError) {
                  return Center(child: Text(state.message));
                } else if (state is SupervisorsLoaded) {
                  final list = state.supervisors;
                  if (list.isEmpty) {
                    return const Center(child: Text('لا يوجد مشرفون'));
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (_, i) {
                      final u = list[i];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            u.fullName.isNotEmpty ? u.fullName[0] : '?',
                          ),
                        ),
                        title: Text(u.fullName),
                        subtitle: Text('${u.email} • ${u.mobileNumber}'),
                        trailing: Icon(
                          u.isActive ? Icons.check_circle : Icons.cancel,
                          color: u.isActive ? Colors.green : Colors.red,
                        ),
                        onTap: () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SupervisorDetailsScreen(user: u),
                            ),
                          );
                          if (changed == true && mounted) _load();
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
        heroTag: 'fab_sup_list',
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddNewSupervisorScreen(
                institutionId: widget.institutionId,
                kafalaHeadId: widget.kafalaHeadId,
              ),
            ),
          );
          if (created == true && mounted) _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        runSpacing: 8,
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 220,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'بحث بالاسم/البريد/الجوال/الرقم',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _load,
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          DropdownButton<String>(
            hint: const Text('الدور'),
            value: _userRoleFilter,
            items: const [
              DropdownMenuItem(value: 'supervisor', child: Text('مشرف')),
              DropdownMenuItem(
                value: 'kafala_head',
                child: Text('رئيس قسم كفالة'),
              ),
            ],
            onChanged: (v) => setState(() {
              _userRoleFilter = v;
              _load();
            }),
          ),
          DropdownButton<String>(
            hint: const Text('المنطقة'),
            value: _areaFilter,
            items: const [
              DropdownMenuItem(value: 'north', child: Text('الشمال')),
              DropdownMenuItem(value: 'south', child: Text('الجنوب')),
              DropdownMenuItem(value: 'east', child: Text('الشرق')),
              DropdownMenuItem(value: 'west', child: Text('الغرب')),
              DropdownMenuItem(value: 'center', child: Text('الوسط')),
            ],
            onChanged: (v) => setState(() {
              _areaFilter = v;
              _load();
            }),
          ),
          DropdownButton<bool>(
            hint: const Text('الحالة'),
            value: _isActiveFilter,
            items: const [
              DropdownMenuItem(value: true, child: Text('مفعل')),
              DropdownMenuItem(value: false, child: Text('غير مفعل')),
            ],
            onChanged: (v) => setState(() {
              _isActiveFilter = v;
              _load();
            }),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _searchCtrl.clear();
                _userRoleFilter = null;
                _areaFilter = null;
                _isActiveFilter = null;
              });
              _load();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('تصفير الفلاتر'),
          ),
        ],
      ),
    );
  }
}
