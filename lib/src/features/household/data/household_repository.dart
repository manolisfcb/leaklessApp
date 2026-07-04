import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dev/demo_data.dart';
import '../../../core/errors/app_exception.dart';
import '../../../domain/enums/household_invitation_status.dart';
import '../../../domain/models/household.dart';
import '../../../domain/models/household_invitation.dart';
import '../../../domain/models/household_member.dart';
import 'household_invitation_mapper.dart';
import 'household_mapper.dart';

/// Reads the current household and owns its invitation boundary.
abstract interface class HouseholdRepository {
  Future<Household?> fetchCurrentHousehold();
  Future<List<HouseholdMember>> fetchMembers(String householdId);
  Future<Household> configureHousehold({
    required String householdId,
    required String name,
    required String currency,
  });
  Future<HouseholdInvitation> createInvitation({
    required String householdId,
    required String email,
    Duration expiresIn = const Duration(days: 7),
  });
  Future<HouseholdInvitation> inspectInvitation(String token);
  Future<HouseholdInvitation> cancelInvitation(String invitationId);
  Future<HouseholdInvitation> acceptInvitation(String token);
}

/// Mock household backed by [DemoData]. Replace with a Supabase implementation
/// (joining `households` + `household_members`) when the backend is wired.
class MockHouseholdRepository implements HouseholdRepository {
  MockHouseholdRepository();

  Household _household = DemoData.household;
  HouseholdInvitation? _invitation;
  String? _invitationToken;
  var _invitationSequence = 0;

  @override
  Future<Household?> fetchCurrentHousehold() async => _household;

  @override
  Future<List<HouseholdMember>> fetchMembers(String householdId) async =>
      DemoData.members;

  @override
  Future<Household> configureHousehold({
    required String householdId,
    required String name,
    required String currency,
  }) async {
    if (householdId != _household.id) {
      throw const ServerException(
        'Household not found',
        code: 'not_household_owner',
      );
    }
    _household = _household.copyWith(
      name: name.trim(),
      currency: currency.trim().toUpperCase(),
      setupCompleted: true,
      updatedAt: DateTime.now().toUtc(),
    );
    return _household;
  }

  @override
  Future<HouseholdInvitation> createInvitation({
    required String householdId,
    required String email,
    Duration expiresIn = const Duration(days: 7),
  }) async {
    final now = DateTime.now().toUtc();
    final invitation = HouseholdInvitation(
      id: 'demo-invitation-${++_invitationSequence}',
      householdId: householdId,
      invitedEmail: email.trim().toLowerCase(),
      status: HouseholdInvitationStatus.pending,
      expiresAt: now.add(expiresIn),
      token: 'demo-invitation-token-$_invitationSequence',
    );
    _invitation = invitation;
    _invitationToken = invitation.token;
    return invitation;
  }

  @override
  Future<HouseholdInvitation> inspectInvitation(String token) async {
    final invitation = _matchingInvitation(token);
    final expired =
        invitation.expiresAt?.isBefore(DateTime.now().toUtc()) ?? false;
    return invitation.copyWith(
      token: null,
      householdName: DemoData.household.name,
      inviterId: DemoData.household.ownerId,
      inviterDisplayName: DemoData.members.first.displayName,
      status: expired ? HouseholdInvitationStatus.expired : invitation.status,
    );
  }

  @override
  Future<HouseholdInvitation> cancelInvitation(String invitationId) async {
    final invitation = _invitation;
    if (invitation == null || invitation.id != invitationId) {
      throw const ServerException(
        'Invitation not found',
        code: 'invitation_not_found',
      );
    }
    final cancelled = invitation.copyWith(
      status: HouseholdInvitationStatus.cancelled,
      token: null,
      updatedAt: DateTime.now().toUtc(),
    );
    _invitation = cancelled;
    return cancelled;
  }

  @override
  Future<HouseholdInvitation> acceptInvitation(String token) async {
    final invitation = _matchingInvitation(token);
    if (invitation.status == HouseholdInvitationStatus.cancelled) {
      throw const ServerException(
        'Invitation cancelled',
        code: 'invitation_cancelled',
      );
    }
    final accepted = invitation.copyWith(
      status: HouseholdInvitationStatus.accepted,
      token: null,
      acceptedAt: DateTime.now().toUtc(),
      alreadyAccepted: invitation.status == HouseholdInvitationStatus.accepted,
    );
    _invitation = accepted;
    return accepted;
  }

  HouseholdInvitation _matchingInvitation(String token) {
    final invitation = _invitation;
    if (invitation == null || _invitationToken != token) {
      throw const ServerException(
        'Invalid invitation token',
        code: 'invalid_invitation_token',
      );
    }
    return invitation;
  }
}

/// Supabase-backed household reads.
///
/// The "current" household is resolved from the signed-in user's `profiles`
/// row (`household_id`), which the `handle_new_user` trigger links on sign-up.
/// Everything else in the app is scoped by the id this returns, so it must be
/// the real household id — not a demo one.
class SupabaseHouseholdRepository implements HouseholdRepository {
  SupabaseHouseholdRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Household?> fetchCurrentHousehold() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final profile = await _client
          .from('profiles')
          .select('household_id')
          .eq('id', userId)
          .maybeSingle();
      final householdId = profile?['household_id'] as String?;
      if (householdId == null) return null;

      final row = await _client
          .from('households')
          .select()
          .eq('id', householdId)
          .maybeSingle();
      return row == null ? null : HouseholdMapper.fromRow(row);
    } catch (e, s) {
      throw ServerException(
        'Failed to load household',
        cause: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<List<HouseholdMember>> fetchMembers(String householdId) async {
    try {
      final rows = await _client
          .from('household_members')
          .select()
          .eq('household_id', householdId)
          .order('created_at');
      return rows.map(HouseholdMemberMapper.fromRow).toList();
    } catch (e, s) {
      throw ServerException(
        'Failed to load household members',
        cause: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<Household> configureHousehold({
    required String householdId,
    required String name,
    required String currency,
  }) async {
    try {
      final row = await _client
          .rpc<List<Map<String, dynamic>>>(
            'configure_household',
            params: {
              'p_household_id': householdId,
              'p_name': name.trim(),
              'p_currency': currency.trim().toUpperCase(),
            },
          )
          .single();
      return HouseholdMapper.fromRow(row);
    } catch (e, s) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to configure household',
        code: e is PostgrestException ? e.message : null,
        cause: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<HouseholdInvitation> createInvitation({
    required String householdId,
    required String email,
    Duration expiresIn = const Duration(days: 7),
  }) async {
    try {
      final row = await _client
          .rpc<List<Map<String, dynamic>>>(
            'create_household_invitation',
            params: {
              'p_household_id': householdId,
              'p_email': email.trim().toLowerCase(),
              'p_expires_in': '${expiresIn.inSeconds} seconds',
            },
          )
          .single();
      return HouseholdInvitationMapper.fromCreateRow(row);
    } catch (e, s) {
      throw _invitationError('Failed to create invitation', e, s);
    }
  }

  @override
  Future<HouseholdInvitation> inspectInvitation(String token) async {
    try {
      final row = await _client
          .rpc<List<Map<String, dynamic>>>(
            'inspect_household_invitation',
            params: {'p_token': token},
          )
          .single();
      return HouseholdInvitationMapper.fromInspectRow(row);
    } catch (e, s) {
      throw _invitationError('Failed to inspect invitation', e, s);
    }
  }

  @override
  Future<HouseholdInvitation> cancelInvitation(String invitationId) async {
    try {
      final row = await _client
          .rpc<List<Map<String, dynamic>>>(
            'cancel_household_invitation',
            params: {'p_invitation_id': invitationId},
          )
          .single();
      return HouseholdInvitationMapper.fromCancelRow(row);
    } catch (e, s) {
      throw _invitationError('Failed to cancel invitation', e, s);
    }
  }

  @override
  Future<HouseholdInvitation> acceptInvitation(String token) async {
    try {
      final row = await _client
          .rpc<List<Map<String, dynamic>>>(
            'accept_household_invitation',
            params: {'p_token': token},
          )
          .single();
      return HouseholdInvitationMapper.fromAcceptRow(row);
    } catch (e, s) {
      throw _invitationError('Failed to accept invitation', e, s);
    }
  }

  ServerException _invitationError(
    String message,
    Object error,
    StackTrace stackTrace,
  ) {
    if (error is ServerException) return error;
    return ServerException(
      message,
      code: error is PostgrestException ? error.message : null,
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
