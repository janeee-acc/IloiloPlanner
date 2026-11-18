import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAuth {
  static final _storage = SharedPreferencesAsync();

  static const _sessionKey = 'iloilo.session.v1.email';

  static final _passwordHasher = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 600000,
    bits: 256,
  );

  static String _accountKey(String email) {
    return 'iloilo.account.v1.${email.trim().toLowerCase()}';
  }

  static Future<List<int>> _hashPassword(
    String password,
    List<int> salt,
  ) async {
    final key = await _passwordHasher.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );

    return key.extractBytes();
  }

  static Future<bool> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final key = _accountKey(normalizedEmail);

    if (await _storage.getString(key) != null) return false;

    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final hash = await _hashPassword(password, salt);

    final account = {
      'email': normalizedEmail,
      'username': username.trim(),
      'salt': base64Encode(salt),
      'passwordHash': base64Encode(hash),
    };

    await _storage.setString(key, jsonEncode(account));
    return true;
  }

  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final saved = await _storage.getString(_accountKey(normalizedEmail));

    if (saved == null) {
      if (kDebugMode) debugPrint('Login: no saved account for this email.');
      return null;
    }

    final account = jsonDecode(saved) as Map<String, dynamic>;
    final username = account['username'] as String;
    final salt = base64Decode(account['salt'] as String);
    final expected = base64Decode(account['passwordHash'] as String);
    final actual = await _hashPassword(password, salt);

    if (actual.length != expected.length) return null;

    var difference = 0;
    for (var i = 0; i < actual.length; i++) {
      difference |= actual[i] ^ expected[i];
    }

    if (difference != 0) {
      if (kDebugMode) debugPrint('Login: password did not match.');
      return null;
    }

    // Save the session before the Login screen opens Home.
    await _storage.setString(_sessionKey, normalizedEmail);
    return username;
  }

  // Welcome uses this to decide whether to open Home or Login.
  static Future<bool> hasActiveSession() async {
    final email = await _storage.getString(_sessionKey);
    if (email == null || email.isEmpty) return false;

    final account = await _storage.getString(_accountKey(email));
    if (account != null) return true;

    // Clear a leftover session if its account was removed.
    await logout();
    return false;
  }

  // The future Profile logout button can call this.
  static Future<void> logout() async {
    await _storage.remove(_sessionKey);
  }
}