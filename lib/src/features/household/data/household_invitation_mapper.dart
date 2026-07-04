import '../../../domain/enums/household_invitation_status.dart';
import '../../../domain/models/household_invitation.dart';

/// Translates the deliberately narrow invitation RPC row shapes into domain.
abstract final class HouseholdInvitationMapper {
  HouseholdInvitationMapper._();

  static HouseholdInvitation fromCreateRow(Map<String, dynamic> row) =>
      HouseholdInvitation(
        id: _string(row, 'invitation_id'),
        householdId: _string(row, 'household_id'),
        invitedEmail: _nullableString(row['invited_email']),
        status: _status(row['status']),
        expiresAt: _date(row['expires_at']),
        token: _nullableString(row['token']),
      );

  static HouseholdInvitation fromInspectRow(Map<String, dynamic> row) =>
      HouseholdInvitation(
        id: _string(row, 'invitation_id'),
        householdId: _string(row, 'household_id'),
        householdName: _nullableString(row['household_name']),
        inviterId: _nullableString(row['inviter_id']),
        inviterDisplayName: _nullableString(row['inviter_display_name']),
        invitedEmail: _nullableString(row['invited_email']),
        status: _status(row['status']),
        expiresAt: _date(row['expires_at']),
      );

  static HouseholdInvitation fromCancelRow(Map<String, dynamic> row) =>
      HouseholdInvitation(
        id: _string(row, 'invitation_id'),
        householdId: _string(row, 'household_id'),
        status: _status(row['status']),
        updatedAt: _date(row['updated_at']),
      );

  static HouseholdInvitation fromAcceptRow(Map<String, dynamic> row) =>
      HouseholdInvitation(
        id: _string(row, 'invitation_id'),
        householdId: _string(row, 'household_id'),
        status: _status(row['status']),
        acceptedAt: _date(row['accepted_at']),
        alreadyAccepted: (row['already_accepted'] as bool?) ?? false,
      );

  static HouseholdInvitationStatus _status(Object? raw) {
    final value = raw as String?;
    if (value == null) {
      throw const FormatException('Missing invitation status');
    }
    try {
      return HouseholdInvitationStatus.values.byName(value);
    } on ArgumentError {
      throw FormatException('Unknown invitation status: $value');
    }
  }

  static String _string(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Missing invitation field: $key');
  }

  static String? _nullableString(Object? value) =>
      value is String ? value : null;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
