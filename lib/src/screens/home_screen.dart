// lib/src/screens/home_screen.dart
import 'package:e_kafel/src/screens/orphans_list_screen.dart';
import 'package:e_kafel/src/screens/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'package:e_kafel/src/screens/login_screen.dart';
import 'package:e_kafel/src/screens/add_new_orphan_screen.dart';
import 'package:e_kafel/src/screens/field_visits_screen.dart';
import 'package:e_kafel/src/widgets/app_drawer.dart';

import 'supervisors_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(LoadHomeData());
  }

  Widget _buildDashboardCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    String countText = count.toString();
    if (count is double) {
      countText = '${(count).toInt()}';
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Icon(icon, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              countText,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitCard({
    required String date,
    required String name,
    required String location,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 80,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6DAF97).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF4C7F7F)),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4C7F7F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4C7F7F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      },
      builder: (context, authState) {
        return Scaffold(
          drawer: _buildDrawer(),
          body: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              if (state is HomeLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is HomeLoaded) {
                return Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                    GestureDetector(
                                      onTap: () =>
                                          Scaffold.of(context).openDrawer(),
                                      child: const CircleAvatar(
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          Icons.menu,
                                          color: Color(0xFF6DAF97),
                                        ),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'مرحبا، ${state.userName}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${state.userRole} في الميدان',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {},
                                          icon: const Icon(
                                            Icons.notifications_none,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF4C7F7F,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF4C7F7F,
                                        ).withOpacity(0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                              'المهام',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF4C7F7F),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${state.completedTasks}/${state.totalTasks}',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF4C7F7F),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 80,
                                          width: 80,
                                          child: CircularProgressIndicator(
                                            value:
                                                state.completedTasksPercentage /
                                                100,
                                            backgroundColor: Colors.grey
                                                .withOpacity(0.2),
                                            color: const Color(0xFF6DAF97),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                                        color: Colors.lightGreen,
                                        icon: Icons.people,
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const OrphansListScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildDashboardCard(
                                        title: 'أيتام بحاجة لتحديث',
                                        count: state.orphanRequiringUpdates,
                                        color: Colors.orange,
                                        icon: Icons.person_off,
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const OrphansListScreen(),
                                            ),
                                          );
                                        },
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
                                        color: Colors.blue,
                                        icon: Icons.favorite,
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const OrphansListScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildDashboardCard(
                                        title: 'الزيارات المنجزة',
                                        count: state.completedFieldVisits,
                                        color: Colors.purple,
                                        icon: Icons.assignment_turned_in,
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const TasksScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildDashboardCard(
                                        title: 'عدد المشرفين',
                                        count: state.supervisorsCount,
                                        color: Colors.red,
                                        icon: Icons.person_outline,
                                        onTap: () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const SupervisorsScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'الزيارات المجدولة',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4C7F7F),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                state.scheduledVisits.isEmpty
                                    ? const Center(
                                        child: Text('لا توجد زيارات مجدولة'),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: state.scheduledVisits.length,
                                        itemBuilder: (context, index) {
                                          final visit =
                                              state.scheduledVisits[index];
                                          return _buildVisitCard(
                                            date: visit['date'] ?? '',
                                            name: visit['name'] ?? '',
                                            location: visit['location'] ?? '',
                                            onTap: () {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'تفاصيل الزيارة',
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
                                  builder: (context) =>
                                      const FieldVisitsScreen(),
                                ),
                              );
                            },
                            label: const Text('إضافة زيارة ميدانية'),
                            icon: const Icon(Icons.add),
                            backgroundColor: const Color(0xFF6DAF97),
                            foregroundColor: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          FloatingActionButton.extended(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => AddNewOrphanScreen(
                                    institutionId: state.institutionId,
                                  ),
                                ),
                              );
                            },
                            label: const Text('إضافة يتيم جديد'),
                            icon: const Icon(Icons.person_add),
                            backgroundColor: const Color(0xFF4C7F7F),
                            foregroundColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              if (state is HomeError) {
                return Center(child: Text('Error: ${state.message}'));
              }
              return const Center(child: Text('Please log in.'));
            },
          ),
        );
      },
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
            orphanCount: state.totalOrphans,
            taskCount: state.completedTasks,
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
        // حالة التحميل أو الخطأ
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
