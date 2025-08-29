// lib/src/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'package:e_kafel/src/screens/login_screen.dart';
import 'package:e_kafel/src/screens/add_new_orphan_screen.dart';
import 'package:e_kafel/src/screens/field_visits_screen.dart';
import 'package:e_kafel/src/screens/orphans_list_screen.dart';
import 'package:e_kafel/src/widgets/app_drawer.dart';
import 'tasks_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
        backgroundColor: const Color(0xFF6DAF97),
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoaded) {
            return AppDrawer(
              userName: state.userName,
              userRole: state.userRole,
              profileImageUrl: state.profileImageUrl,
              orphanCount: state.orphanSponsored,
              taskCount: state.completedTasksPercentage.toInt(),
              visitCount: state.completedFieldVisits,
              onLogout: () {
                context.read<AuthBloc>().add(LogoutButtonPressed());
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            );
          }
          return const Drawer();
        },
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HomeLoaded) {
            // حساب القيم الإضافية بناءً على البيانات المتاحة
            final int totalOrphans =
                state.orphanSponsored + state.orphanRequiringUpdates;
            final int totalVisits =
                state.completedFieldVisits +
                5; // تقديري - تحتاج إلى بيانات حقيقية

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section 1: Dashboard Stats Cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        context,
                        'ORPHAN SPONSORED',
                        state.orphanSponsored.toString(),
                        '${((state.orphanSponsored / totalOrphans) * 100).toStringAsFixed(0)}%',
                        Icons.child_care,
                        const Color(0xFFC8A2C8),
                        () {
                          // الانتقال إلى قائمة الأيتام المكفولين
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrphansListScreen(),
                            ),
                          );
                        },
                      ),
                      _buildStatCard(
                        context,
                        'COMPLETED TASKS',
                        state.completedTasksPercentage.toInt().toString(),
                        '${state.completedTasksPercentage.toStringAsFixed(0)}%',
                        Icons.check_circle_outline,
                        const Color(0xFF4C7F7F),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TasksScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        context,
                        'ORPHAN REQUIRING DATA UPDATES',
                        state.orphanRequiringUpdates.toString(),
                        '${((state.orphanRequiringUpdates / totalOrphans) * 100).toStringAsFixed(0)}%',
                        Icons.edit,
                        const Color(0xFF6DAF97),
                        () {
                          // الانتقال إلى قائمة الأيتام المحتاجة للتحديث
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrphansListScreen(),
                            ),
                          );
                        },
                      ),
                      _buildStatCard(
                        context,
                        'SUPERVISOR',
                        state.supervisorsCount.toString(),
                        'ACTIVE',
                        Icons.group,
                        const Color(0xFFC8A2C8),
                        () {
                          // الانتقال إلى قائمة المشرفين
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => SupervisorsScreen(),
                          //   ),
                          // );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('شاشة المشرفين قريبًا')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    context,
                    'COMPLETED FIELD VISITS',
                    state.completedFieldVisits.toString(),
                    '${((state.completedFieldVisits / totalVisits) * 100).toStringAsFixed(0)}%',
                    Icons.location_on,
                    const Color(0xFF4C7F7F),
                    () {
                      // الانتقال إلى شاشة الزيارات الميدانية
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FieldVisitsScreen(),
                        ),
                      );
                    },
                    fullWidth: true,
                  ),
                  const SizedBox(height: 24),

                  // Section 2: Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AddNewOrphanScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('ADD NEW ORPHAN'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE0BBE4),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const FieldVisitsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_location),
                          label: const Text('ADD NEW VISIT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE0BBE4),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section 3: Scheduled Visits
                  const Text(
                    'Scheduled Visits',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4C7F7F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  state.scheduledVisits.isEmpty
                      ? const Text('لا توجد زيارات مجدولة')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.scheduledVisits.length,
                          itemBuilder: (context, index) {
                            final visit = state.scheduledVisits[index];
                            return _buildVisitCard(
                              date: visit['date'] ?? '',
                              name: visit['name'] ?? '',
                              location: visit['location'] ?? '',
                              onTap: () {
                                // الانتقال إلى تفاصيل الزيارة
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'تفاصيل زيارة ${visit['name']}',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ],
              ),
            );
          }
          if (state is HomeError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Center(child: Text('Please log in.'));
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String percentage,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          width: fullWidth ? double.infinity : 150,
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                percentage,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
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
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
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
                child: Text(
                  date,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4C7F7F),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VISIT ${name.toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4C7F7F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(location),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
