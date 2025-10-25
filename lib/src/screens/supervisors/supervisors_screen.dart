import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/supervisors/supervisors_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/user_model.dart';
import 'add_new_supervisor_screen.dart';
import 'supervisors_details_screen.dart';

class SupervisorsScreen extends StatefulWidget {
  final String institutionId;
  final String kafalaHeadId; // لتصفية المشرفين المرتبطين بهذا الرئيس
  final bool isActive;

  const SupervisorsScreen({
    super.key,
    required this.institutionId,
    required this.kafalaHeadId,
    required this.isActive,
  });

  @override
  State<SupervisorsScreen> createState() => _SupervisorsScreenState();
}

class _SupervisorsScreenState extends State<SupervisorsScreen> {
  bool? _activeFilter; // null=الكل، true=فعال، false=غير فعال
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    final isHead =
        auth is AuthAuthenticated && auth.userRole == 'kafala_head';
    if (!isHead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا تملك صلاحية للوصول إلى المشرفين')),
        );
        Navigator.of(context).pop();
      });
      return;
    }
    context.read<SupervisorsBloc>().add(LoadSupervisorsByHead(
          institutionId: widget.institutionId,
          kafalaHeadId: widget.kafalaHeadId,
          isActive: widget.isActive,
        ));
  }

  void _openAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddNewSupervisorScreen(
          institutionId: widget.institutionId,
          kafalaHeadId: widget.kafalaHeadId,
        ),
      ),
    );
  }

  void _search() {
    context.read<SupervisorsBloc>().add(
          SearchSupervisors(
            institutionId: widget.institutionId,
            search: _searchCtrl.text.trim(),
            userRole: 'supervisor',
            isActive: _activeFilter,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final isHead = auth is AuthAuthenticated && auth.userRole == 'kafala_head';

    return Scaffold(
      appBar: AppBar(
        title: const Text('المشرفون'),
        backgroundColor: const Color(0xFF6DAF97),
        actions: [
          if (isHead)
            IconButton(
              onPressed: _openAdd,
              icon: const Icon(Icons.person_add_alt_1),
              tooltip: 'إضافة مشرف',
            ),
        ],
      ),
      body: Column(
        children: [
          // بحث وفلترة
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم/البريد/الهاتف',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<bool?>(
                  tooltip: 'فلترة الحالة',
                  onSelected: (v) {
                    setState(() => _activeFilter = v);
                    _search();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: null, child: Text('الكل')),
                    PopupMenuItem(value: true, child: Text('فعال')),
                    PopupMenuItem(value: false, child: Text('غير فعال')),
                  ],
                  child: Chip(
                    label: Text(
                      _activeFilter == null
                          ? 'الكل'
                          : _activeFilter == true
                              ? 'فعال'
                              : 'غير فعال',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<SupervisorsBloc, SupervisorsState>(
              builder: (context, state) {
                if (state is SupervisorsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6DAF97)),
                  );
                }
                if (state is SupervisorsError) {
                  return Center(child: Text(state.message));
                }
                if (state is SupervisorsLoaded) {
                  final list = state.supervisors.where((u) {
                    final byHead = u.kafalaHeadId == widget.kafalaHeadId;
                    final byActive = _activeFilter == null
                        ? true
                        : (u.isActive == _activeFilter);
                    final q = _searchCtrl.text.trim().toLowerCase();
                    final bySearch = q.isEmpty
                        ? true
                        : (u.fullName.toLowerCase().contains(q) ||
                            u.email.toLowerCase().contains(q) ||
                            (u.mobileNumber)
                                .toString()
                                .toLowerCase()
                                .contains(q));
                    return byHead && byActive && bySearch;
                  }).toList();

                  if (list.isEmpty) {
                    return const Center(child: Text('لا يوجد مشرفون'));
                  }

                  return ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _SupervisorTile(
                      user: list[i],
                      onTap: (u) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SupervisorsDetailsScreen(user: u, isHeadOfKafala: isHead,),
                          ),
                        );
                      },
                      onToggleActive: (u, val) {
                        context.read<SupervisorsBloc>().add(
                              ToggleSupervisorActive(uid: u.uid, isActive: val),
                            );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SupervisorTile extends StatelessWidget {
  final UserModel user;
  final void Function(UserModel) onTap;
  final void Function(UserModel, bool)? onToggleActive;

  const _SupervisorTile({
    required this.user,
    required this.onTap,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final String name =
        (user.fullName.trim().isNotEmpty) ? user.fullName.trim() : 'بدون اسم';
    final String email =
        (user.email.trim().isNotEmpty) ? user.email.trim() : '—';
    final String mobile = (user.mobileNumber).toString().trim().isNotEmpty
        ? (user.mobileNumber).toString().trim()
        : '—';
    final bool isActive = user.isActive;
    final String? photo = (user.profileImageUrl != null &&
            user.profileImageUrl!.isNotEmpty)
        ? user.profileImageUrl
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: () => onTap(user),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF6DAF97).withOpacity(0.1),
          backgroundImage: photo != null ? NetworkImage(photo) : null,
          child: photo == null
              ? const Icon(Icons.person, color: Color(0xFF6DAF97))
              : null,
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'البريد: $email\nالجوال: $mobile',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: onToggleActive == null
            ? null
            : Switch.adaptive(
                value: isActive,
                onChanged: (val) => onToggleActive!(user, val),
              ),
      ),
    );
  }
}
