import 'package:finals/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'firebase_options.dart';
import 'repositories/auth_repository.dart';
import 'blocs/login_bloc.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepository>(
      create: (_) => AuthRepository(),
      child: BlocProvider<LoginBloc>(
        create: (context) =>
            LoginBloc(authRepository: context.read<AuthRepository>()),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ADDU Events Admin',
          theme: ThemeData(
            primaryColor: const Color(0xFF0B0C69),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0B0C69),
            ),
          ),
          home: const LoginScreen(),
        ),
      ),
    );
  }
}
