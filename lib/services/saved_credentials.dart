// lib/services/saved_credentials.dart
//
// "Remember me": keeps the email + password a person signed in with inside the
// platform keystore (Android Keystore / iOS Keychain) so the next sign-in is a
// single tap. Tenants and guests are stored separately because the login screen
// lets one phone use either.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SavedLogin {
  final String email;
  final String password;
  const SavedLogin(this.email, this.password);
}

class SavedCredentials {
  SavedCredentials._();

  static const FlutterSecureStorage _store = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static String _k(String role, String field) => 'lk_saved_${role}_$field';
  static String _role(bool isTenant) => isTenant ? 'tenant' : 'guest';

  /// Returns the saved login for this account type, or null when none is saved.
  static Future<SavedLogin?> load({required bool isTenant}) async {
    try {
      final r = _role(isTenant);
      final email = await _store.read(key: _k(r, 'email'));
      final password = await _store.read(key: _k(r, 'password'));
      if (email == null || email.isEmpty || password == null || password.isEmpty) {
        return null;
      }
      return SavedLogin(email, password);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save({
    required bool isTenant,
    required String email,
    required String password,
  }) async {
    try {
      final r = _role(isTenant);
      await _store.write(key: _k(r, 'email'), value: email.trim());
      await _store.write(key: _k(r, 'password'), value: password);
    } catch (_) {
      // Saving is a convenience; never block signing in because of it.
    }
  }

  static Future<void> clear({required bool isTenant}) async {
    try {
      final r = _role(isTenant);
      await _store.delete(key: _k(r, 'email'));
      await _store.delete(key: _k(r, 'password'));
    } catch (_) {}
  }

  /// After a password change/reset, keep the saved copy in step - but only when
  /// the saved account is the one that changed (a phone may hold someone else's).
  static Future<void> updatePasswordIfSaved({
    required bool isTenant,
    required String email,
    required String newPassword,
  }) async {
    try {
      final saved = await load(isTenant: isTenant);
      if (saved == null) return;
      if (saved.email.toLowerCase() != email.trim().toLowerCase()) return;
      await save(isTenant: isTenant, email: saved.email, password: newPassword);
    } catch (_) {}
  }
}
