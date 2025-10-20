import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_kafel/src/blocs/profile/profile_bloc.dart';
import 'package:e_kafel/src/blocs/supervisors/supervisors_bloc.dart';
import 'package:e_kafel/src/models/user_model.dart';
import 'package:e_kafel/src/screens/orphans/add_new_orphan_screen.dart';
import 'package:e_kafel/src/screens/orphans/edit_orphan_details_screen.dart';
import 'package:e_kafel/src/screens/orphans/orphan_archiv_list_screen.dart';
import 'package:e_kafel/src/screens/orphans/orphans_list_screen.dart';
import 'package:e_kafel/src/screens/profile/edit_profile_screen.dart';
import 'package:e_kafel/src/screens/profile/profile_screen.dart';
import 'package:e_kafel/src/screens/settings/settings_screen.dart';
import 'package:e_kafel/src/screens/sms/send_sms_screen.dart';
import 'package:e_kafel/src/screens/sponsorship/sponsorship_management_screen.dart';
import 'package:e_kafel/src/screens/supervisors/add_new_supervisor_screen.dart';
import 'package:e_kafel/src/screens/supervisors/edit_supervisor_screen.dart';
import 'package:e_kafel/src/screens/supervisors/supervisor_details_screen.dart';
import 'package:e_kafel/src/screens/supervisors/supervisors_screen.dart';
import 'package:e_kafel/src/screens/tasks/tasks_screen.dart';
import 'package:e_kafel/src/screens/visits/field_visits_screen.dart';
import 'package:e_kafel/src/services/reports_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/screens/Auth/login_screen.dart';
import 'package:e_kafel/src/screens/Home/home_screen.dart';
import 'package:e_kafel/src/services/auth_service.dart';
import 'package:e_kafel/src/services/firestore_service.dart';
import 'firebase_options.dart';
import 'src/blocs/orphans/orphans_bloc.dart';
import 'src/blocs/reports/reports_bloc.dart';
import 'src/blocs/send_sms/send_sms_bloc.dart';
import 'src/blocs/sponsership/sponsership_bloc.dart';
import 'src/blocs/tasks/tasks_bloc.dart';
import 'src/blocs/visit/visit_bloc.dart';
import 'src/screens/orphans/orphan_details_screen.dart';
import 'src/screens/reports/reports_screen.dart';
import 'src/services/sms_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  // App Check (وضع التطوير)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  // سجل هاندلر الرسائل بالخلفية قبل runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());

  // بعد عرض الواجهة: اطلب صلاحيات الإشعارات وجلب/حفظ التوكن
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final sms = SMSService();
    try {
      await sms.setupFCM();
      // في حال المستخدم سجّل لاحقًا، زامن التوكن تلقائيًا
      sms.listenAuthAndSyncToken();
    } catch (e) {
      debugPrint('setupFCM error: $e');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => AuthBloc(authService)),
        BlocProvider<HomeBloc>(create: (_) => HomeBloc(authService, firestoreService)),
        BlocProvider<OrphansBloc>(
          create: (_) => OrphansBloc(
            firestore: FirebaseFirestore.instance,
            storage: FirebaseStorage.instance,
            firestoreService: firestoreService,
          ),
        ),
        BlocProvider<VisitBloc>(create: (_) => VisitBloc(firestoreService)),
        BlocProvider<TasksBloc>(create: (_) => TasksBloc(firestoreService)),
        BlocProvider(create: (_) => ReportsBloc(ReportsService())),
        BlocProvider(create: (_) => SupervisorsBloc(firestoreService)),
        BlocProvider(create: (_) => ProfileBloc(firestoreService)),
        BlocProvider(create: (_) => SponsorshipBloc(firestore: firestoreService)),
        BlocProvider(create: (_) => SMSBloc(SMSService())),
      ],
      child: MaterialApp(
        title: 'E-Kafel App',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => _buildHome());
            case '/login_screen':
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case '/home_screen':
              return MaterialPageRoute(builder: (_) => const HomeScreen());
            case '/orphans_archive_list_screen':
              return MaterialPageRoute(builder: (_) => const OrphanArchivedListScreen());
            case '/tasks_screen':
              return MaterialPageRoute(builder: (_) => const TasksScreen());
            case '/reports_screen':
              return MaterialPageRoute(builder: (_) => const ReportsScreen());
            case '/add_new_orphan_screen':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => AddNewOrphanScreen(
                  institutionId: args?['institutionId'] ?? '',
                  kafalaHeadId: args?['kafalaHeadId'] ?? '',
                ),
              );
            case '/edit_orphan_details_screen':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => EditOrphanDetailsScreen(
                  orphanId: args?['orphanId'] ?? '',
                  institutionId: args?['institutionId'] ?? '',
                  orphanData: args!['orphanData'],
                ),
              );
            case '/field_visits_screen':
              return MaterialPageRoute(builder: (_) => const FieldVisitsScreen());
            case '/orphans_list_screen':
              return MaterialPageRoute(builder: (_) => const OrphansListScreen());
            case '/orphan_details_screen':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => OrphanDetailsScreen(orphanId: args?['orphanId'] ?? '', institutionId: args?['institutionId'],),
              );
            case '/profile_screen':
              return MaterialPageRoute(builder: (_) => const ProfileScreen());
            case '/sponsorship_management_screen':
              return MaterialPageRoute(builder: (_) => const SponsorshipManagementScreen());
            case '/settings_screen':
              return MaterialPageRoute(builder: (_) => const SettingsScreen());
            case '/send_sms_screen':
              return MaterialPageRoute(builder: (_) => const SendSMSScreen());
            case '/supervisors_screen':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => SupervisorsScreen(
                  institutionId: args?['institutionId'] ?? '',
                  kafalaHeadId: args?['kafalaHeadId'] ?? '',
                ),
              );
            case '/add_new_supervisors_screen':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => AddNewSupervisorScreen(
                  institutionId: args?['institutionId'] ?? '',
                  kafalaHeadId: args?['kafalaHeadId'] ?? '',
                ),
              );
            case '/edit_supervisors_screen':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => EditSupervisorScreen(user: args?['supervisorData'] ?? {}),
              );
            case '/supervisors_details_screen':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => SupervisorDetailsScreen(user: args as UserModel),
              );
            case '/edit_profile_screen':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => EditProfileScreen(profile: args?['profile']),
              );
            default:
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('No route defined')),
                ),
              );
          }
        },
      ),
    );
  }

  Widget _buildHome() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
