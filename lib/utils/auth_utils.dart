// lib/utils/auth_utils.dart
import 'dart:convert';

/// Retourne true si le token est absent/malformed/expiré.
bool isJwtExpired(String? token) {
  if (token == null || token.isEmpty) return true;
  try {
    final parts = token.split('.');
    if (parts.length != 3) return true;
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final Map<String, dynamic> map = jsonDecode(decoded);
    final exp = map['exp'];
    if (exp == null) return true;
    final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return DateTime.now().isAfter(expiry);
  } catch (_) {
    return true;
  }
}
