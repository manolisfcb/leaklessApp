import '../../../core/errors/app_exception.dart';

/// Maps an auth error to a specific, friendly Spanish message for the sign-in /
/// sign-up screen.
///
/// Prefers Supabase's machine-readable [AuthFailureException.code]; falls back
/// to matching the raw message text for SDK versions that don't populate a
/// code, and finally to sensible generic copy. Keeping this here (not in the
/// generic [AppFailure]) lets the auth UI speak precisely — "correo ya
/// registrado" vs. "contraseña muy corta" — without leaking backend strings.
String authErrorMessage(Object error) {
  if (error is AuthFailureException) {
    final code = error.code;
    final text = error.message.toLowerCase();

    bool has(String needle) => text.contains(needle);

    switch (code) {
      case 'invalid_credentials':
      case 'invalid_grant':
        return 'Correo o contraseña incorrectos.';
      case 'email_not_confirmed':
        return 'Confirma tu correo antes de iniciar sesión. Revisa tu bandeja '
            'de entrada.';
      case 'user_already_exists':
      case 'email_exists':
        return 'Ya existe una cuenta con este correo. Inicia sesión.';
      case 'weak_password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      case 'same_password':
        return 'La nueva contraseña debe ser distinta a la anterior.';
      case 'email_address_invalid':
        return 'El correo no es válido.';
      case 'signup_disabled':
        return 'El registro está deshabilitado por ahora.';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
    }

    // Fallbacks for SDK versions that don't set `code`.
    if (has('invalid login') || has('invalid credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (has('not confirmed') || has('email not confirmed')) {
      return 'Confirma tu correo antes de iniciar sesión. Revisa tu bandeja '
          'de entrada.';
    }
    if (has('already registered') || has('already exists')) {
      return 'Ya existe una cuenta con este correo. Inicia sesión.';
    }
    if (has('password') && (has('short') || has('least') || has('6'))) {
      return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
    }
    if (has('rate limit') || has('too many')) {
      return 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
    }
    return 'No pudimos completar la operación. Inténtalo de nuevo.';
  }

  if (error is NetworkException) {
    return 'Revisa tu conexión a internet.';
  }

  return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
}
