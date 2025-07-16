import 'package:flutter/material.dart';
import 'package:issho/pages/auth/login.dart';
import 'package:issho/pages/community/search.dart';
import 'package:issho/pages/settings.dart';
import 'package:issho/pages/communities.dart';
import 'package:issho/pages/app_shell.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home'; 
}

class AppRouter {
  static Route<dynamic> generate(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case AppRoutes.home: // now leads to AppShell
        return MaterialPageRoute(builder: (_) => const AppShell());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("We can't find what you're looking for!")),
          ),
        );
    }
  }
}
