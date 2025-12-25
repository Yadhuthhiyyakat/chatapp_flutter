import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart'; // You will need to create this file
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase correctly with options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flash Chat',
      theme: ThemeData(
        useMaterial3: true,
        // Using a modern Seed Color for an attractive UI
        colorSchemeSeed: const Color(0xFF6366F1),
        brightness: Brightness.light,
      ),
      // This Auth Gate automatically checks if the user is signed in
      home: const AuthGate(),
    );
  }
}

// Attractive Auth Gate to handle Login vs Home automatically
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. If user is logged in, go to Home Page
          if (snapshot.hasData) {
            return const HomePage();
          }
          // 2. If user is NOT logged in, show Login Page
          return const LoginPage();
        },
      ),
    );
  }
}
