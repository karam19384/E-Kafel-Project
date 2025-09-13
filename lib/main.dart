import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_kafel/src/blocs/auth/auth_bloc.dart';
import 'package:e_kafel/src/blocs/home/home_bloc.dart';
import 'package:e_kafel/src/screens/login_screen.dart';
import 'package:e_kafel/src/screens/home_screen.dart';
import 'package:e_kafel/src/services/auth_service.dart';
import 'package:e_kafel/src/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'src/blocs/orphans/orphans_bloc.dart';
import 'src/providers/visit_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true);
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (context) => AuthBloc(authService)),
        BlocProvider<HomeBloc>(
          create: (context) => HomeBloc(authService, firestoreService),
        ),
        BlocProvider<OrphansBloc>(
          create: (_) => OrphansBloc(firestore: FirebaseFirestore.instance),
        ),
        ChangeNotifierProvider(create: (ctx) => VisitProvider()),
      ],
      child: MaterialApp(
        title: 'E-Kafel App',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        home: _buildHome(),
      ),
    );
  }

  Widget _buildHome() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          BlocProvider.of<HomeBloc>(context).add(LoadHomeData());
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
