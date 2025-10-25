import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_kafel/src/blocs/profile/profile_bloc.dart';
import 'package:e_kafel/src/blocs/settings/settings_bloc.dart';
import 'package:e_kafel/src/blocs/supervisors/supervisors_bloc.dart';
import 'package:e_kafel/src/models/user_model.dart';
import 'package:e_kafel/src/screens/auth/splash_screen.dart';
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
import 'package:e_kafel/src/screens/supervisors/supervisors_details_screen.dart';
import 'package:e_kafel/src/screens/supervisors/supervisors_screen.dart';
import 'package:e_kafel/src/screens/tasks/tasks_screen.dart';
import 'package:e_kafel/src/screens/visits/field_visits_screen.dart';
import 'package:e_kafel/src/services/reports_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'src/blocs/orphans/orphans_bloc.dart';
import 'src/blocs/reports/reports_bloc.dart';
import 'src/blocs/send_sms/send_sms_bloc.dart';
import 'src/blocs/sponsership/sponsership_bloc.dart';
import 'src/blocs/tasks/tasks_bloc.dart';
import 'src/blocs/visit/visit_bloc.dart';
import 'src/models/setting_model.dart';
import 'src/screens/onboarding/onboarding_screen.dart';
import 'src/screens/orphans/orphan_details_screen.dart';
import 'src/screens/reports/reports_screen.dart';
import 'src/screens/supervisors/edit_supervisors_details_screen.dart';
import 'src/services/sms_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AppInitializer {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      WidgetsFlutterBinding.ensureInitialized();
      
      // تهيئة Firebase الأساسية
      await _initializeFirebase();
      
      // تهيئة الخدمات الإضافية
      await _initializeAdditionalServices();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ Application initialized successfully');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ Application initialization failed: $e');
      }
      await FirebaseCrashlytics.instance.recordError(e, stack);
      rethrow;
    }
  }

  static Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // تفعيل Crashlytics
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

      if (kDebugMode) {
        print('✅ Firebase initialized successfully');
      }
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') {
        if (kDebugMode) {
          print('❌ Firebase initialization error: ${e.message}');
        }
        rethrow;
      }
    }
  }

  static Future<void> _initializeAdditionalServices() async {
    try {
      // تهيئة App Check (للإنتاج استبدل debug بـ safetyNet)
      if (!kIsWeb) {
        await FirebaseAppCheck.instance.activate(
          androidProvider: kDebugMode 
              ? AndroidProvider.debug 
              : AndroidProvider.playIntegrity,
          appleProvider: kDebugMode 
              ? AppleProvider.debug 
              : AppleProvider.appAttest,
        );
      }

      // تهيئة Analytics
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

      if (kDebugMode) {
        print('✅ Additional services initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Additional services initialization warning: $e');
      }
      // لا نعيد throw لأن هذه الخدمات ليست حرجة
    }
  }
}

class AppRoutes {
  static const String home = '/';
  static const String login = '/login_screen';
  static const String onboarding = '/onboarding';
  static const String splash = '/splash';
  static const String orphansList = '/orphans_list_screen';
  static const String orphanDetails = '/orphan_details_screen';
  static const String addOrphan = '/add_new_orphan_screen';
  static const String editOrphan = '/edit_orphan_details_screen';
  static const String orphanArchive = '/orphan_archive_list_screen';
  static const String tasks = '/tasks_screen';
  static const String reports = '/reports_screen';
  static const String fieldVisits = '/field_visits_screen';
  static const String profile = '/profile_screen';
  static const String editProfile = '/edit-profile';
  static const String sponsorship = '/sponsorship_management_screen';
  static const String settings = '/settings_screen';
  static const String sendSms = '/send_sms_screen';
  static const String supervisors = '/supervisors';
  static const String addSupervisor = '/add-supervisor';
  static const String editSupervisor = '/edit-supervisor';
  static const String supervisorDetails = '/supervisor-details';

  static Route<dynamic> generateRoute(RouteSettings setting) {
    final args = setting.arguments;

    switch (setting.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const AppRoot());
      
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen(onboardingComplete: _completeOnboarding));
      
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case orphansList:
        return MaterialPageRoute(builder: (_) => const OrphansListScreen());
      
      case orphanDetails:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => OrphanDetailsScreen(
              orphanId: args['orphanId'] ?? '',
              institutionId: args['institutionId'],
            ),
          );
        }
        return _buildErrorRoute('Invalid arguments for orphan details');
      
      case addOrphan:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => AddNewOrphanScreen(
              institutionId: args['institutionId'] ?? '',
              kafalaHeadId: args['kafalaHeadId'] ?? '',
            ),
          );
        }
        return _buildErrorRoute('Invalid arguments for add orphan');
      
      case editOrphan:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => EditOrphanDetailsScreen(
              orphanId: args['orphanId'] ?? '',
              institutionId: args['institutionId'] ?? '',
              orphanData: args['orphanData'],
            ),
          );
        }
        return _buildErrorRoute('Invalid arguments for edit orphan');
      
      case orphanArchive:
        return MaterialPageRoute(builder: (_) => const OrphanArchivedListScreen());
      
      case tasks:
        return MaterialPageRoute(builder: (_) => const TasksScreen());
      
      case reports:
        return MaterialPageRoute(builder: (_) => const ReportsScreen());
      
      case fieldVisits:
        return MaterialPageRoute(builder: (_) => const FieldVisitsScreen());
      
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      
      case editProfile:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => EditProfileScreen(profile: args['profile']),
          );
        }
        return _buildErrorRoute('Invalid arguments for edit profile');
      
      case sponsorship:
        return MaterialPageRoute(builder: (_) => const SponsorshipManagementScreen());
      
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      
      case sendSms:
        return MaterialPageRoute(builder: (_) => const SendSMSScreen(
          recipientNumber: '',
        ));
      
      case supervisors:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => SupervisorsScreen(
              institutionId: args['institutionId'] ?? '',
              kafalaHeadId: args['kafalaHeadId'] ?? '',
              isActive: true,
            ),
          );
        }
        return _buildErrorRoute('Invalid arguments for supervisors');
      
      case addSupervisor:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => AddNewSupervisorScreen(
              institutionId: args['institutionId'] ?? '',
              kafalaHeadId: args['kafalaHeadId'] ?? '',
            ),
          );
        }
        return _buildErrorRoute('Invalid arguments for add supervisor');
      
      case editSupervisor:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => EditSupervisorsDetailsScreen(
              user: args['supervisorData'] ?? <String, dynamic>{},
            ),
          );
        }
        return _buildErrorRoute('Invalid arguments for edit supervisor');
      
      case supervisorDetails:
        if (args is UserModel) {
          return MaterialPageRoute(
            builder: (_) => SupervisorsDetailsScreen(user: args, isHeadOfKafala: true,),
          );
        }
        return _buildErrorRoute('Invalid arguments for supervisor details');
      
      default:
        return _buildErrorRoute('No route defined for ${setting.name}');
    }
  }

  static Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
  }

  static MaterialPageRoute<dynamic> _buildErrorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                'خطأ في المسار',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _isLoading = true;
  bool _hasSeenOnboarding = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // التحقق مما إذا كان المستخدم قد رأى شاشات Onboarding
      final prefs = await SharedPreferences.getInstance();
      _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

      // التحقق من حالة تسجيل الدخول الحالية
      _currentUser = FirebaseAuth.instance.currentUser;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing app: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }

    // إذا لم ير المستخدم Onboarding من قبل
    if (!_hasSeenOnboarding) {
      return const OnboardingScreen(onboardingComplete: _completeOnboarding);
    }

    // إذا كان المستخدم مسجل الدخول
    if (_currentUser != null && _isValidUser(_currentUser!)) {
      return const HomeScreen();
    }

    // إذا لم يكن مسجل الدخول
    return const LoginScreen();
  }

  bool _isValidUser(User user) {
    return user.uid.isNotEmpty && 
           (user.emailVerified || _isTestUser(user));
  }

  bool _isTestUser(User user) {
    return kDebugMode && (user.email?.contains('test') == true);
  }

  static Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 20),
            Text(
              'جاري التحميل...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const ErrorScreen({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              'حدث خطأ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text('إعادة المحاولة'),
              ),
          ],
        ),
      ),
    );
  }
}

class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();

    return MultiBlocProvider(
      providers: [
        // Authentication & Core
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authService),
        ),
        
        BlocProvider<HomeBloc>(
          create: (_) => HomeBloc(authService, firestoreService),
        ),

        // Data Management
        BlocProvider<OrphansBloc>(
          create: (_) => OrphansBloc(
            firestore: FirebaseFirestore.instance,
            storage: FirebaseStorage.instance,
            firestoreService: firestoreService,
          ),
        ),

        BlocProvider<VisitBloc>(
          create: (_) => VisitBloc(firestoreService),
        ),

        BlocProvider<TasksBloc>(
          create: (_) => TasksBloc(firestoreService),
        ),

        BlocProvider<ReportsBloc>(
          create: (_) => ReportsBloc(ReportsService()),
        ),

        BlocProvider<SupervisorsBloc>(
          create: (_) => SupervisorsBloc(firestoreService),
        ),

        BlocProvider<ProfileBloc>(
          create: (_) => ProfileBloc(firestoreService),
        ),

        BlocProvider<SponsorshipBloc>(
          create: (_) => SponsorshipBloc(firestore: firestoreService),
        ),

        BlocProvider<SMSBloc>(
          create: (_) => SMSBloc(SMSService()),
        ),

         BlocProvider<SettingsBloc>(
      create: (context) => SettingsBloc(firestoreService),
    ),
      ],
      child: child,
    );
  }
}

void main() {
  runZonedGuarded(() async {
    await AppInitializer.initialize();
    runApp(const MyApp());
  }, (error, stack) {
    if (kDebugMode) {
      print('🔥 Global error: $error');
    }
    FirebaseCrashlytics.instance.recordError(error, stack);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          // استخدام الإعدادات من البلوك لتطبيق الثيم واللغة
          SettingsModel settings;
          if (state is SettingsLoaded) {
            settings = state.settings;
          } else if (state is SettingsUpdated) {
            settings = state.settings;
          } else if (state is SettingsUpdating) {
            settings = state.settings;
          } else {
            settings = SettingsModel.defaultSettings;
          }

          return MaterialApp(
            title: 'E-Kafel App',
            theme: _buildAppTheme(settings, false),
            darkTheme: _buildAppTheme(settings, true),
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,
            navigatorObservers: [
              FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
            ],
            locale: _getLocale(settings.language),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ar'), // Arabic
              Locale('en'), // English
            ],
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: _getTextScaleFactor(settings.fontSize),
                ),
                child: Directionality(
                  textDirection: _getTextDirection(settings.language),
                  child: child!,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // باقي الدوال تبقى كما هي...
  Color _getThemeColor(String themeColor) {
    switch (themeColor) {
      case 'أزرق':
        return Colors.blue;
      case 'أحمر':
        return Colors.red;
      case 'بنفسجي':
        return Colors.purple;
      case 'برتقالي':
        return Colors.orange;
      default: // 'أخضر أساسي'
        return const Color(0xFF6DAF97);
    }
  }

  double _getTextScaleFactor(String fontSize) {
    switch (fontSize) {
      case 'صغير':
        return 0.9;
      case 'كبير':
        return 1.2;
      case 'كبير جداً':
        return 1.4;
      default: // 'متوسط'
        return 1.0;
    }
  }

  Locale _getLocale(String language) {
    switch (language) {
      case 'English':
        return const Locale('en');
      case 'Français':
        return const Locale('fr');
      case 'Español':
        return const Locale('es');
      default: // 'العربية'
        return const Locale('ar');
    }
  }

  TextDirection _getTextDirection(String language) {
    switch (language) {
      case 'English':
      case 'Français':
      case 'Español':
        return TextDirection.ltr;
      default: // 'العربية'
        return TextDirection.rtl;
    }
  }

  ThemeData _buildAppTheme(SettingsModel settings, bool isDark) {
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();
    final primaryColor = _getThemeColor(settings.themeColor);
    
    return baseTheme.copyWith(
      primaryColor: primaryColor,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: primaryColor,
        secondary: primaryColor.withOpacity(0.8),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}