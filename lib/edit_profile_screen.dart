import 'package:flutter/material.dart';

import 'local_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _green = Color(0xFF406735);
  static const _maxUsername = 30;
  static const _maxBio = 150;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.profile.username);
    _bioController = TextEditingController(text: widget.profile.bio);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  InputDecoration _fieldStyle({String? hint, bool readOnly = false}) {
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
      fillColor: readOnly ? const Color(0xFFE2E2E2) : const Color(0xFFEDEDED),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: border,
      enabledBorder: border,
      disabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFF55995C)),
      ),
    );
  }

  String? _validateUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) return 'Enter a username.';
    if (username.length > _maxUsername) {
      return 'Use $_maxUsername characters or fewer.';
    }
    return null;
  }

  String? _validateBio(String? value) {
    if ((value?.trim().length ?? 0) > _maxBio) {
      return 'Use $_maxBio characters or fewer.';
    }
    return null;
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      await LocalAuth.updateProfile(
        username: _usernameController.text,
        bio: _bioController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Could not save your profile: $error');
    }
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E2E2))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to Profile',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: _green),
          ),
          const Expanded(
            child: Text(
              'Edit Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _green,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    // Default avatar: changing the photo is not part of this screen.
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEAF3E6),
        border: Border.all(color: _green, width: 2),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 46, color: _green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Update your personal information.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF686868),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(child: _buildAvatar()),
                          const SizedBox(height: 20),
                          _label('Email'),
                          TextFormField(
                            initialValue: widget.profile.email,
                            enabled: false,
                            readOnly: true,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF606060),
                            ),
                            decoration: _fieldStyle(readOnly: true),
                          ),
                          const SizedBox(height: 14),
                          _label('Username'),
                          TextFormField(
                            controller: _usernameController,
                            enabled: !_isSaving,
                            maxLength: _maxUsername,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 13),
                            decoration: _fieldStyle(
                              hint: 'Username',
                            ).copyWith(counterText: ''),
                            validator: _validateUsername,
                          ),
                          const SizedBox(height: 14),
                          _label('Password'),
                          TextFormField(
                            initialValue: '••••••••',
                            enabled: false,
                            readOnly: true,
                            obscureText: true,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF606060),
                            ),
                            decoration: _fieldStyle(readOnly: true),
                          ),
                          const SizedBox(height: 14),
                          _label('Bio'),
                          TextFormField(
                            controller: _bioController,
                            enabled: !_isSaving,
                            minLines: 3,
                            maxLines: 4,
                            maxLength: _maxBio,
                            keyboardType: TextInputType.multiline,
                            style: const TextStyle(fontSize: 13),
                            decoration: _fieldStyle(
                              hint: 'Tell others about yourself',
                            ),
                            validator: _validateBio,
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: SizedBox(
                              width: 140,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF55995C),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(40),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child:
                                    _isSaving
                                        ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Text(
                                          'Save',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 3) {
            Navigator.of(context).pop();
            return;
          }
          const routes = ['/home', '/search', '/planner', '/profile'];
          final navigator = Navigator.of(context);
          navigator.popUntil((route) => route.isFirst);
          navigator.pushReplacementNamed(routes[index]);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: _green,
        unselectedItemColor: const Color(0xFF81869D),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.travel_explore),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Planner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
