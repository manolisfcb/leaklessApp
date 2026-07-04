import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/enums/household_invitation_status.dart';
import 'package:leakless/src/features/household/data/household_invitation_mapper.dart';

void main() {
  group('HouseholdInvitationMapper', () {
    test('maps the one-time token returned by create', () {
      final invitation = HouseholdInvitationMapper.fromCreateRow({
        'invitation_id': 'invitation-1',
        'household_id': 'household-1',
        'invited_email': 'pareja@example.com',
        'status': 'pending',
        'expires_at': '2026-07-10T12:00:00Z',
        'token': 'one-time-secret',
      });

      expect(invitation.id, 'invitation-1');
      expect(invitation.status, HouseholdInvitationStatus.pending);
      expect(invitation.invitedEmail, 'pareja@example.com');
      expect(invitation.token, 'one-time-secret');
      expect(invitation.expiresAt, DateTime.utc(2026, 7, 10, 12));
    });

    test('maps the safe recipient preview and derived expired state', () {
      final invitation = HouseholdInvitationMapper.fromInspectRow({
        'invitation_id': 'invitation-1',
        'household_id': 'household-1',
        'household_name': 'Casa Azul',
        'inviter_id': 'user-1',
        'inviter_display_name': 'Alex',
        'invited_email': 'pareja@example.com',
        'status': 'expired',
        'expires_at': '2026-07-01T12:00:00Z',
      });

      expect(invitation.status, HouseholdInvitationStatus.expired);
      expect(invitation.householdName, 'Casa Azul');
      expect(invitation.inviterDisplayName, 'Alex');
      expect(invitation.token, isNull);
    });

    test('maps an idempotent acceptance result', () {
      final invitation = HouseholdInvitationMapper.fromAcceptRow({
        'invitation_id': 'invitation-1',
        'household_id': 'household-1',
        'status': 'accepted',
        'accepted_at': '2026-07-03T15:30:00Z',
        'already_accepted': true,
      });

      expect(invitation.status, HouseholdInvitationStatus.accepted);
      expect(invitation.alreadyAccepted, isTrue);
      expect(invitation.acceptedAt, DateTime.utc(2026, 7, 3, 15, 30));
    });

    test('rejects unknown backend states instead of silently defaulting', () {
      expect(
        () => HouseholdInvitationMapper.fromCancelRow({
          'invitation_id': 'invitation-1',
          'household_id': 'household-1',
          'status': 'mystery',
          'updated_at': '2026-07-03T15:30:00Z',
        }),
        throwsFormatException,
      );
    });
  });
}
