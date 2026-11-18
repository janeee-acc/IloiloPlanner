import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'planner_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IloiloPlanner',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        Widget screen;
        switch (settings.name) {
          case '/search':
            screen = const SearchScreen();
            break;
          case '/planner':
            screen = const PlannerScreen();
            break;
          case '/profile':
            screen = const ProfileScreen();
            break;
          case '/':
          default:
            screen = const HomeScreen();
            break;
        }

        return PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => screen,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
      },
    );
  }
}