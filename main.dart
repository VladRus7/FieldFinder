// main.dart – setup cu Firebase și routing pentru Register/Login/Home
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home.dart';
import 'firebase_options.dart';
import 'services/notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.initialize(); // initializează notificările
  runApp(const FieldFinderApp());
}

class FieldFinderApp extends StatelessWidget {
  const FieldFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FieldFinder',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Poppins',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        
      },
    );
  }
}
