import 'dart:async';

import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'local_auth.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final Timer _welcomeTimer;

  @override
  void initState() {
    super.initState();
    _welcomeTimer = Timer(
      const Duration(seconds: 2),
      _openNextScreen,
    );
  }

  Future<void> _openNextScreen() async {
    bool isLoggedIn;

    try {
      isLoggedIn = await LocalAuth.hasActiveSession();
    } catch (error) {
      // If the session cannot be read, let the user sign in again.
      debugPrint('Could not restore session: ${error.runtimeType}');
      isLoggedIn = false;
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) =>
            isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _welcomeTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF406735),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 96,
              height: 96,
              fit: BoxFit.contain,
              semanticLabel: 'IloiloPlanner logo',
            ),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 160),
              child: Text(
                'Discover, Plan, Visit Iloilo.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}