import '../../../core/errors/app_exception.dart';

String invitationErrorMessage(Object error) {
  final code = error is ServerException ? error.code : null;
  return switch (code) {
    'invalid_invitation_email' => 'Escribe un correo válido.',
    'invalid_invitation_expiry' => 'La duración de la invitación no es válida.',
    'cannot_invite_self' => 'No puedes invitar tu propio correo.',
    'not_household_owner' => 'Sólo quien creó este hogar puede invitar.',
    'user_already_household_member' => 'Esa persona ya pertenece a este hogar.',
    'invalid_invitation_token' =>
      'El enlace o código de invitación no es válido.',
    'invitation_email_mismatch' =>
      'Esta invitación fue enviada a otro correo. Usa esa cuenta para continuar.',
    'invitation_already_used' => 'Esta invitación ya fue utilizada.',
    'invitation_cancelled' => 'La invitación fue revocada.',
    'invitation_expired' => 'La invitación ha vencido.',
    'invitation_not_found' => 'No encontramos esta invitación.',
    'accepted_invitation_cannot_be_cancelled' =>
      'Una invitación aceptada ya no se puede revocar.',
    'current_household_not_empty' =>
      'Tu hogar actual contiene datos. No podemos moverlos automáticamente.',
    'profile_not_found' => 'No encontramos tu perfil. Inténtalo de nuevo.',
    'authentication_required' => 'Inicia sesión para continuar.',
    _ => 'No pudimos completar la invitación. Inténtalo de nuevo.',
  };
}
