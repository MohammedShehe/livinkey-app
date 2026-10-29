// lib/utils/password_policy.dart
/// Same rules as the server (8+ characters, at least one letter and one number),
/// so users get instant, friendly feedback instead of a server rejection.
String? validatePassword(String? password) {
  final p = password ?? '';
  if (p.length < 8) return 'Password must be at least 8 characters long.';
  if (p.length > 72) return 'Password must be 72 characters or fewer.';
  if (!RegExp(r'[A-Za-z]').hasMatch(p) || !RegExp(r'\d').hasMatch(p)) {
    return 'Password must include at least one letter and one number.';
  }
  return null;
}

const String kPasswordHint = 'Use 8+ characters with letters and numbers';
