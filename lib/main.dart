import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'splash_screen.dart';
import 'planner_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Route<void> _onGenerateRoute(RouteSettings settings) {
    final Widget screen;
    switch (settings.name) {
      case '/splash':
        screen = const SplashScreen();
        break;
      case '/search':
        screen = const SearchScreen();
        break;
      case '/planner':
        screen = const PlannerScreen();
        break;
      case '/profile':
        screen = const ProfileScreen();
        break;
      case '/home':
      case '/':
        screen = const HomeScreen();
        break;
      default:
        screen = const SplashScreen();
        break;
    }

    return PageRouteBuilder<void>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IloiloPlanner',
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      onGenerateRoute: _onGenerateRoute,
      onGenerateInitialRoutes:
          (initialRoute) => [
            _onGenerateRoute(RouteSettings(name: initialRoute)),
          ],
    );
  }
}
