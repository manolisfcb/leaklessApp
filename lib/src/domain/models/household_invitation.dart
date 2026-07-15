import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/household_invitation_status.dart';

part 'household_invitation.freezed.dart';

/// Safe client-side view of a household invitation.
///
/// The backend deliberately returns different fields for each operation. For
/// example, [token] is returned only once on creation, while [householdName]
/// and inviter details are exposed only to the authenticated recipient during
/// inspection. Optional fields preserve that security boundary without making
/// the domain depend on the RPC row shapes.
@freezed
abstract class HouseholdInvitation with _$HouseholdInvitation {
  const factory HouseholdInvitation({
    required String id,
    required String householdId,
    required HouseholdInvitationStatus status,
    String? invitedEmail,
    String? householdName,
    String? inviterId,
    String? inviterDisplayName,
    String? token,
    DateTime? expiresAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    @Default(false) bool alreadyAccepted,
  }) = _HouseholdInvitation;
}
