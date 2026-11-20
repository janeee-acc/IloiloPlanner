import 'package:flutter/material.dart';

import 'local_auth.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _username = '';
  String _password = '';
  bool _isSaving = false;

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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFF55995C)),
      ),
    );
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signUp() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final created = await LocalAuth.register(
        email: _email,
        username: _username,
        password: _password,
      );

      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;

      if (created) {
        Navigator.of(context).pop(true);
      } else {
        _showMessage('This email already has an account.');
      }
    } catch (_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        _showMessage('Could not save the account. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            LayoutBuilder(
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
                          const SizedBox(height: 24),
                          const Text(
                            'Welcome to',
                            style: TextStyle(
                              color: Color(0xFF34883E),
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Image.asset(
                            'assets/images/iloilo_planner_text.png',
                            width: 176,
                            height: 52,
                            fit: BoxFit.contain,
                            semanticLabel: 'IloiloPlanner',
                          ),
                          SizedBox(height: height * 0.06),
                          Form(
                            key: _formKey,
                            child: SizedBox(
                              width: layoutWidth * 0.68,
                              child: Column(
                                children: [
                                  TextFormField(
                                    enabled: !_isSaving,
                                    decoration: _fieldStyle('Email'),
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                    autocorrect: false,
                                    onChanged: (value) => _email = value,
                                    validator: (value) {
                                      final email = value?.trim() ?? '';
                                      if (email.isEmpty) {
                                        return 'Enter your email.';
                                      }

                                      final pattern = RegExp(
                                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                      );
                                      if (!pattern.hasMatch(email)) {
                                        return 'Enter a valid email address.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    enabled: !_isSaving,
                                    decoration: _fieldStyle('Username'),
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.newUsername,
                                    ],
                                    autocorrect: false,
                                    onChanged: (value) => _username = value,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Enter a username.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    enabled: !_isSaving,
                                    decoration: _fieldStyle('Password'),
                                    obscureText: true,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    autofillHints: const [
                                      AutofillHints.newPassword,
                                    ],
                                    textInputAction: TextInputAction.done,
                                    onChanged: (value) => _password = value,
                                    onFieldSubmitted: (_) => _signUp(),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter a password.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 34),
                                  ElevatedButton(
                                    onPressed: _isSaving ? null : _signUp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF55995C),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      minimumSize: const Size(86, 36),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                    ),
                                    child: Text(
                                      _isSaving ? 'Saving...' : 'Sign up',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                tooltip: 'Back to login',
                icon: const Icon(Icons.arrow_back, color: Color(0xFF34883E)),
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
