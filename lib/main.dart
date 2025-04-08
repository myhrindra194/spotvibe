import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/spot_model.dart';
import 'package:flutter_application_1/repositories/spot_repository.dart';
import 'package:flutter_application_1/viewmodels/auth_viewmodel.dart';
import 'package:flutter_application_1/viewmodels/registration_viewmodel.dart';
import 'package:flutter_application_1/viewmodels/spot_viewmodel.dart';
import 'package:flutter_application_1/views/add_edit_spot_screen.dart';
import 'package:flutter_application_1/views/auth/login_screen.dart';
import 'package:flutter_application_1/views/auth/register_screen.dart';
import 'package:flutter_application_1/views/home_screen.dart';
import 'package:flutter_application_1/views/splash_screen.dart';
import 'package:flutter_application_1/views/spot_details_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => RegistrationViewModel()),
        ChangeNotifierProxyProvider<AuthViewModel, SpotViewModel>(
          create: (context) => SpotViewModel(
            SpotRepository(),
            Provider.of<AuthViewModel>(context, listen: false),
          ),
          update: (context, authVm, spotVm) => SpotViewModel(
            SpotRepository(),
            authVm,
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Spots App',
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegistrationScreen(),
          '/home': (context) => const HomeScreen(),
          '/addSpot': (context) => const AddEditSpotScreen(),
          '/editSpot': (context) {
            final spot = ModalRoute.of(context)?.settings.arguments as Spot?;
            return AddEditSpotScreen(spot: spot);
          },
          '/spotDetails': (context) {
            final spot = ModalRoute.of(context)?.settings.arguments as Spot;
            return SpotDetailsScreen(spot: spot);
          },
        },
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Erreur')),
              body: Center(
                child: Text('Route non trouvée: ${settings.name}'),
              ),
            ),
          );
        },
      ),
    );
  }
}
