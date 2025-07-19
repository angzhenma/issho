import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:issho/pages/auth/login.dart';
import 'package:issho/pages/communities.dart';
import 'package:issho/themes/light_mode.dart';
import 'package:issho/themes/dark_mode.dart';
import 'package:issho/themes/theme_notifier.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:issho/routes.dart';

// Programmer Name: Mr. Ibrahim Azaan Mauroof
// Program Name: issho/lib/main.dart
// Program Description: Main entry point for the Issho mobile application.
// First Written on: Friday, 16-May-2025
// Last Modified on: Monday, 14-July-2025

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    return MaterialApp(
      title: 'Issho',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeNotifier.themeMode,
      scrollBehavior: const CupertinoScrollBehavior(),
      initialRoute: isLoggedIn ? AppRoutes.home : AppRoutes.login,
      onGenerateRoute: AppRouter.generate,
    );
  }
}

class CupertinoScrollBehavior extends ScrollBehavior {
  const CupertinoScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}