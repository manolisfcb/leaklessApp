import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';

String invitationErrorMessage(Object error, AppLocalizations l10n) {
  final code = error is ServerException ? error.code : null;
  return switch (code) {
    'invalid_invitation_email' => l10n.invitationErrorInvalidEmail,
    'invalid_invitation_expiry' => l10n.invitationErrorInvalidExpiry,
    'cannot_invite_self' => l10n.invitationErrorCannotInviteSelf,
    'not_household_owner' => l10n.invitationErrorNotOwner,
    'user_already_household_member' => l10n.invitationErrorAlreadyMember,
    'invalid_invitation_token' => l10n.invitationErrorInvalidToken,
    'invitation_email_mismatch' => l10n.invitationErrorEmailMismatch,
    'invitation_already_used' => l10n.invitationAlreadyUsedMessage,
    'invitation_cancelled' => l10n.invitationCancelledMessage,
    'invitation_expired' => l10n.invitationExpiredMessage,
    'invitation_not_found' => l10n.invitationErrorNotFound,
    'accepted_invitation_cannot_be_cancelled' =>
      l10n.invitationErrorAcceptedCannotCancel,
    'current_household_not_empty' => l10n.invitationErrorHouseholdNotEmpty,
    'profile_not_found' => l10n.invitationErrorProfileNotFound,
    'authentication_required' => l10n.commonSignInToContinue,
    _ => l10n.invitationErrorGeneric,
  };
}
