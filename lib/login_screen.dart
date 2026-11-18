import 'package:flutter/material.dart';

import 'create_account_screen.dart';
import 'home_screen.dart';
import 'local_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoggingIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldStyle(String hint) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide.none,
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF707070),
        fontSize: 13,
        fontStyle: FontStyle.italic,
      ),
      filled: true,
      fillColor: const Color(0xFFEDEDED),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 15,
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFF55995C)),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) return 'Enter your email.';

    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!pattern.hasMatch(email)) return 'Enter a valid email address.';

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password.';
    return null;
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logIn() async {
    if (_isLoggingIn || !_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    FocusScope.of(context).unfocus();
    setState(() => _isLoggingIn = true);

    final String? username;
    try {
      username = await LocalAuth.login(
        email: email,
        password: password,
      );
    } catch (error) {
      debugPrint('Local login failed: ${error.runtimeType}');
      if (!mounted) return;

      setState(() => _isLoggingIn = false);
      _showMessage('Could not read the saved account. Please try again.');
      return;
    }

    if (!mounted) return;

    if (username == null) {
      setState(() => _isLoggingIn = false);
      _showMessage('Incorrect email or password.');
      return;
    }

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  Future<void> _openCreateAccount() async {
    FocusScope.of(context).unfocus();

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => const CreateAccountScreen(),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      _showMessage('Account created. You can now log in.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            final layoutWidth =
                constraints.maxWidth.clamp(0.0, 360.0).toDouble();

            return SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: layoutWidth,
                  child: Column(
                    children: [
                      SizedBox(height: height * 0.19),
                      Image.asset(
                        'assets/images/logo.png',
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                        semanticLabel: 'IloiloPlanner logo',
                      ),
                      SizedBox(height: height * 0.12),

                      SizedBox(
                        width: layoutWidth * 0.78,
                        child: Form(
                          key: _formKey,
                          child: AutofillGroup(
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  enabled: !_isLoggingIn,
                                  decoration: _fieldStyle('Email'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.2,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  autocorrect: false,
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: 15),
                                TextFormField(
                                  controller: _passwordController,
                                  enabled: !_isLoggingIn,
                                  decoration: _fieldStyle('Password'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.2,
                                  ),
                                  obscureText: true,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  autofillHints: const [AutofillHints.password],
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _logIn(),
                                  validator: _validatePassword,
                                ),
                                SizedBox(height: height * 0.07),
                                SizedBox(
                                  width: layoutWidth * 0.257,
                                  child: ElevatedButton(
                                    onPressed: _isLoggingIn ? null : _logIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF55995C),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      minimumSize: const Size(0, 34),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                    ),
                                    child: _isLoggingIn
                                        ? const SizedBox.square(
                                            dimension: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              semanticsLabel: 'Logging in',
                                            ),
                                          )
                                        : const Text(
                                            'Log in',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: height * 0.14),
                      SizedBox(
                        width: layoutWidth * 0.70,
                        child: OutlinedButton(
                          onPressed: _isLoggingIn ? null : _openCreateAccount,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF555555),
                            minimumSize: const Size(0, 48),
                            side: const BorderSide(color: Color(0xFFB0B0B0)),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            'Create new account',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Image.asset(
                        'assets/images/iloilo_planner_text.png',
                        width: 176,
                        height: 52,
                        fit: BoxFit.contain,
                        semanticLabel: 'IloiloPlanner',
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}