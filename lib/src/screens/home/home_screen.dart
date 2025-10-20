// lib/src/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/blocs/visit/visit_bloc.dart';
import 'package:e_kafel/src/screens/Auth/login_screen.dart';
import 'package:e_kafel/src/screens/orphans/orphans_list_screen.dart';
import 'package:e_kafel/src/screens/orphans/add_new_orphan_screen.dart';
import 'package:e_kafel/src/screens/visits/field_visits_screen.dart';
import 'package:e_kafel/src/screens/supervisors/supervisors_screen.dart';
import 'package:e_kafel/src/widgets/app_drawer.dart';
import 'package:e_kafel/src/services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home_screen';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _fs = FirestoreService();

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(LoadHomeData());
  }

  void _refreshData() {
    context.read<HomeBloc>().add(LoadHomeData());
  }

  // تحميل الزيارات عند نجاح تحميل بيانات الهوم (أضمن من didChangeDependencies)
  Widget _visitLoaderListener({required Widget child}) {
    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (prev, curr) => curr is HomeLoaded,
      listener: (context, state) {
        final s = state as HomeLoaded;
        context.read<VisitBloc>().add(
              LoadVisitsByStatus(
                institutionId: s.institutionId,
                status: 'scheduled',
              ),
            );
      },
      child: child,
    );
  }

  Future<void> _markAllNotificationsRead(
    List<Map<String, dynamic>> notifications,
  ) async {
    final unread = notifications.where((n) => n['isRead'] != true);
    for (final n in unread) {
      final id = (n['notificationId'] ?? '').toString();
      if (id.isNotEmpty) {
        await _fs.markNotificationRead(id);
      }
    }
    if (mounted) _refreshData();
  }

  void _showNotificationsPopup(List<Map<String, dynamic>> notifications) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final hasUnread = notifications.any((n) => n['isRead'] != true);
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.notifications, color: Color(0xFF6DAF97)),
              const SizedBox(width: 8),
              const Text('الإشعارات'),
              const Spacer(),
              if (notifications.isNotEmpty)
                TextButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _markAllNotificationsRead(notifications);
                  },
                  icon: const Icon(Icons.mark_email_read_outlined, size: 18),
                  label: const Text('علّم الكل كمقروء'),
                ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: notifications.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد إشعارات جديدة',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          onTap: () async {
                            final id =
                                (notification['notificationId'] ?? '').toString();
                            if (id.isNotEmpty && notification['isRead'] != true) {
                              await _fs.markNotificationRead(id);
                              if (mounted) _refreshData();
                            }
                          },
                          leading: CircleAvatar(
                            backgroundColor:
                                const Color(0xFF6DAF97).withOpacity(0.1),
                            child: Icon(
                              _getNotificationIcon(notification['type']),
                              color: const Color(0xFF6DAF97),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            (notification['title'] ?? 'لا يوجد عنوان').toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          // ملاحظة: في FirestoreService الحقل اسمه "message" وليس "body"
                          subtitle: Text(
                            (notification['message'] ?? 'لا يوجد محتوى').toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: notification['isRead'] == true
                              ? null
                              : Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
          ),
          actions: <Widget>[
            if (hasUnread)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _markAllNotificationsRead(notifications);
                },
                child: const Text('علّم الكل كمقروء'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'orphan':
        return Icons.person;
      case 'visit':
        return Icons.assignment_turned_in;
      case 'task':
        return Icons.task;
      case 'supervisor':
        return Icons.supervisor_account;
      default:
        return Icons.notifications;
    }
  }

  Widget _buildDashboardCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(icon, color: color, size: 24),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisitsSection(List<Map<String, dynamic>> visits) {
    if (visits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_today, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            const Text(
              'لا توجد زيارات مجدولة',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'يمكنك إضافة زيارة جديدة من الزر أدناه',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: visits.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final visit = visits[index];
              return Container(
                width: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('زيارة ميدانية',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            )),
                        const SizedBox(height: 4),
                        Text(
                          (visit['name'] ?? 'بدون اسم').toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            (visit['location'] ?? 'لا يوجد موقع').toString(),
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            (visit['date'] ?? 'لا يوجد تاريخ').toString(),
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6DAF97).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'مجدولة',
                        style: TextStyle(
                          color: Color(0xFF6DAF97),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (visits.length > 3) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FieldVisitsScreen()),
              );
            },
            child: const Text('عرض جميع الزيارات'),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _visitLoaderListener(
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, authState) {
          if (authState is AuthUnauthenticated) {
            Navigator.pushNamed(context, '/login_screen');
          }
        },
        builder: (context, authState) {
          return Scaffold(
            key: _scaffoldKey,
            drawer: _buildDrawer(),
            body: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                if (state is HomeLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF6DAF97),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'جاري تحميل البيانات...',
                          style: TextStyle(
                            color: Color(0xFF4C7F7F),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (state is HomeLoaded) {
                  final unreadExists =
                      state.notifications.any((n) => n['isRead'] != true);

                  return Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: () async {
                          _refreshData();
                          await Future.delayed(const Duration(milliseconds: 400));
                        },
                        color: const Color(0xFF6DAF97),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF6DAF97),
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(30),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // افتح القائمة باستخدام مفتاح الـ Scaffold (أكثر أماناً)
                                        GestureDetector(
                                          onTap: () => _scaffoldKey.currentState
                                              ?.openDrawer(),
                                          child: const CircleAvatar(
                                            backgroundColor: Colors.white,
                                            child: Icon(
                                              Icons.menu,
                                              color: Color(0xFF6DAF97),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                'مرحباً، ${state.userName}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                state.userRole == 'kafala_head'
                                                    ? 'رئيس قسم الكفالة'
                                                    : state.userRole == 'supervisor'
                                                        ? 'مشرف'
                                                        : 'مستخدم',
                                                style: TextStyle(
                                                  color:
                                                      Colors.white.withOpacity(0.9),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _showNotificationsPopup(
                                            state.notifications,
                                          ),
                                          icon: Badge(
                                            isLabelVisible: unreadExists,
                                            child: const Icon(
                                              Icons.notifications_none,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Progress Card
                                    Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'تقدم المهام',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF4C7F7F),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${state.completedTasks}/${state.totalTasks}',
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF4C7F7F),
                                                  ),
                                                ),
                                                Text(
                                                  'مهمة مكتملة',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                SizedBox(
                                                  height: 80,
                                                  width: 80,
                                                  child:
                                                      CircularProgressIndicator(
                                                    value: state.totalTasks > 0
                                                        ? state.completedTasks /
                                                            state.totalTasks
                                                        : 0,
                                                    backgroundColor: Colors.grey
                                                        .withOpacity(0.2),
                                                    color:
                                                        const Color(0xFF6DAF97),
                                                    strokeWidth: 8,
                                                  ),
                                                ),
                                                Text(
                                                  '${((state.totalTasks > 0 ? state.completedTasks / state.totalTasks : 0) * 100).toStringAsFixed(0)}%',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF4C7F7F),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Dashboard Cards
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildDashboardCard(
                                            title: 'إجمالي الأيتام',
                                            count: state.totalOrphans,
                                            color: const Color(0xFF4CAF50),
                                            icon: Icons.people_outline,
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/orphans_list_screen',
                                                arguments: {
                                                  'institutionId':
                                                      state.institutionId,
                                                },
                                              );
                                            },
                                            subtitle: 'إجمالي المسجلين',
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildDashboardCard(
                                            title: 'الأيتام المؤرشفين',
                                            count: state.archivedOrphansCount,
                                            color: const Color(0xFFFF9800),
                                            icon: Icons.archive,
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/orphans_archive_list_screen',
                                                arguments: {
                                                  'institutionId':
                                                      state.institutionId,
                                                },
                                              );
                                            },
                                            subtitle: 'في الأرشيف',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildDashboardCard(
                                            title: 'الأيتام المكفولين',
                                            count: state.orphanSponsored,
                                            color: const Color(0xFF2196F3),
                                            icon: Icons.favorite_border,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      OrphansListScreen(),
                                                ),
                                              );
                                            },
                                            subtitle: 'تحت الكفالة',
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildDashboardCard(
                                            title: 'الزيارات المنجزة',
                                            count: state.completedFieldVisits,
                                            color: const Color(0xFF9C27B0),
                                            icon: Icons.assignment_turned_in,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const FieldVisitsScreen(),
                                                ),
                                              );
                                            },
                                            subtitle: 'تم تنفيذها',
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildDashboardCard(
                                            title: 'المشرفين',
                                            count: state.supervisorsCount,
                                            color: const Color(0xFFF44336),
                                            icon: Icons.supervisor_account,
                                            onTap: () {
                                              // إصلاح: تمرير kafalaHeadId الصحيح (كان يُمرَّر userRole بالغلط)
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      SupervisorsScreen(
                                                    institutionId:
                                                        state.institutionId,
                                                    kafalaHeadId:
                                                        state.kafalaHeadId,
                                                  ),
                                                ),
                                              );
                                            },
                                            subtitle: 'فريق العمل',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: Color(0xFF4C7F7F),
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'الزيارات المجدولة',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4C7F7F),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    BlocBuilder<VisitBloc, VisitState>(
                                      builder: (context, visitState) {
                                        if (visitState is VisitLoading) {
                                          return const Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(20),
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        } else if (visitState is VisitLoaded) {
                                          return _buildVisitsSection(
                                            visitState.scheduledVisits,
                                          );
                                        } else if (visitState is VisitError) {
                                          return Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Column(
                                              children: [
                                                const Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red,
                                                  size: 48,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'حدث خطأ في تحميل الزيارات',
                                                  style: TextStyle(
                                                    color: Colors.red[700],
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  visitState.message,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.red[600],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                ElevatedButton(
                                                  onPressed: _refreshData,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                  ),
                                                  child:
                                                      const Text('إعادة المحاولة'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // أزرار الإجراء
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            FloatingActionButton.extended(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const FieldVisitsScreen(),
                                  ),
                                );
                              },
                              label: const Text('إضافة زيارة'),
                              icon: const Icon(Icons.add),
                              backgroundColor: const Color(0xFF6DAF97),
                              foregroundColor: Colors.white,
                              elevation: 4,
                            ),
                            const SizedBox(height: 12),
                            FloatingActionButton.extended(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AddNewOrphanScreen(
                                      institutionId: state.institutionId,
                                      kafalaHeadId: '', // إذا كان مطلوب تمريره فعلاً
                                    ),
                                  ),
                                );
                              },
                              label: const Text('إضافة يتيم'),
                              icon: const Icon(Icons.person_add),
                              backgroundColor: const Color(0xFF4C7F7F),
                              foregroundColor: Colors.white,
                              elevation: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                if (state is HomeError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'حدث خطأ: ${state.message}',
                          style: const TextStyle(fontSize: 16, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _refreshData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6DAF97),
                          ),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                return const Center(child: Text('الرجاء تسجيل الدخول'));
              },
            ),
          );
        },
      ),
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
