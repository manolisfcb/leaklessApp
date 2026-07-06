import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';

/// Maps an auth error to a specific, friendly localized message for the
/// sign-in / sign-up screen.
///
/// Prefers Supabase's machine-readable [AuthFailureException.code]; falls back
/// to matching the raw message text for SDK versions that don't populate a
/// code, and finally to sensible generic copy. Keeping this here (not in the
/// generic [AppFailure]) lets the auth UI speak precisely — "email already
/// registered" vs. "password too short" — without leaking backend strings.
String authErrorMessage(Object error, AppLocalizations l10n) {
  if (error is AuthFailureException) {
    final code = error.code;
    final text = error.message.toLowerCase();

    bool has(String needle) => text.contains(needle);

    switch (code) {
      case 'invalid_credentials':
      case 'invalid_grant':
        return l10n.authErrorInvalidCredentials;
      case 'email_not_confirmed':
        return l10n.authErrorEmailNotConfirmed;
      case 'user_already_exists':
      case 'email_exists':
        return l10n.authErrorEmailExists;
      case 'weak_password':
        return l10n.authErrorWeakPassword;
      case 'same_password':
        return l10n.authErrorSamePassword;
      case 'email_address_invalid':
        return l10n.authErrorInvalidEmail;
      case 'signup_disabled':
        return l10n.authErrorSignupDisabled;
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return l10n.authErrorRateLimit;
    }

    // Fallbacks for SDK versions that don't set `code`.
    if (has('invalid login') || has('invalid credentials')) {
      return l10n.authErrorInvalidCredentials;
    }
    if (has('not confirmed') || has('email not confirmed')) {
      return l10n.authErrorEmailNotConfirmed;
    }
    if (has('already registered') || has('already exists')) {
      return l10n.authErrorEmailExists;
    }
    if (has('password') && (has('short') || has('least') || has('6'))) {
      return l10n.authErrorWeakPassword;
    }
    if (has('rate limit') || has('too many')) {
      return l10n.authErrorRateLimit;
    }
    return l10n.authErrorGeneric;
  }

  if (error is NetworkException) {
    return l10n.errorNetwork;
  }

  return l10n.authErrorUnexpected;
}
