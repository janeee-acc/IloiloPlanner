import 'dart:async';

import 'package:flutter/material.dart';

import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Timer _welcomeTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);

    _welcomeTimer = Timer(const Duration(seconds: 4), _openWelcomeScreen);
  }

  void _openWelcomeScreen() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (context) => const WelcomeScreen()),
    );
  }

  @override
  void dispose() {
    _welcomeTimer.cancel();
    _controller.dispose();
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
              width: 88,
              height: 88,
              fit: BoxFit.contain,
              semanticLabel: 'IloiloPlanner logo',
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.45),
            child: Semantics(
              label: 'Loading IloiloPlanner',
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final pulse = Curves.easeInOut.transform(_controller.value);

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: 1.0 - 0.15 * pulse,
                        child: const _LoadingDot(
                          size: 38,
                          topColor: Color(0xFF489F49),
                          bottomColor: Color(0xFF19451F),
                        ),
                      ),
                      Transform.scale(
                        scale: 1.0 + 0.15 * pulse,
                        child: const _LoadingDot(
                          size: 19,
                          topColor: Color(0xFFFFDF56),
                          bottomColor: Color(0xFFB49442),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingDot extends StatelessWidget {
  const _LoadingDot({
    required this.size,
    required this.topColor,
    required this.bottomColor,
  });

  final double size;
  final Color topColor;
  final Color bottomColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, bottomColor],
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}
