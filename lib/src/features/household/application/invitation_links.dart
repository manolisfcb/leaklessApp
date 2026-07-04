import '../../../core/router/app_routes.dart';

/// Centralized invitation-link contract.
///
/// Invitation tokens are credentials. Callers may render or share the URI,
/// but must never log or persist the complete URI. The pending-intent store
/// persists only the validated token in platform secure storage.
abstract final class InvitationLinks {
  InvitationLinks._();

  static const String scheme = 'leakless';
  static const String host = 'app';
  static const String tokenParameter = 'token';

  static final RegExp _tokenPattern = RegExp(r'^[a-fA-F0-9]{64}$');

  static String? normalizeToken(String? value) {
    final token = value?.trim();
    if (token == null || !_tokenPattern.hasMatch(token)) return null;
    return token.toLowerCase();
  }

  static String? tokenFromUri(Uri uri) {
    if (uri.path != AppRoutes.invitation) return null;
    if (uri.hasScheme && (uri.scheme != scheme || uri.host != host)) {
      return null;
    }
    return normalizeToken(uri.queryParameters[tokenParameter]);
  }

  static Uri invitationUri(String token) {
    final normalized = normalizeToken(token);
    if (normalized == null) {
      throw const FormatException('Invalid invitation token');
    }
    return Uri(
      scheme: scheme,
      host: host,
      path: AppRoutes.invitation,
      queryParameters: {tokenParameter: normalized},
    );
  }
}
