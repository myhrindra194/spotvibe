import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/viewmodels/auth_viewmodel.dart';
import 'package:flutter_application_1/viewmodels/registration_viewmodel.dart';
import 'package:flutter_application_1/views/auth/login_screen.dart';
import 'package:flutter_application_1/views/auth/register_screen.dart';
import 'package:flutter_application_1/views/home_page.dart';
import 'package:flutter_application_1/views/splash_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => RegistrationViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegistrationScreen(),
          '/home': (context) => const HomePage()
        },
      ),
    );
  }
}
