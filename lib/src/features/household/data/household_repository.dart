import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dev/demo_data.dart';
import '../../../core/errors/app_exception.dart';
import '../../../domain/models/household.dart';
import '../../../domain/models/household_member.dart';
import 'household_mapper.dart';

/// Reads the current household and its members.
abstract interface class HouseholdRepository {
  Future<Household?> fetchCurrentHousehold();
  Future<List<HouseholdMember>> fetchMembers(String householdId);
}

/// Mock household backed by [DemoData]. Replace with a Supabase implementation
/// (joining `households` + `household_members`) when the backend is wired.
class MockHouseholdRepository implements HouseholdRepository {
  const MockHouseholdRepository();

  @override
  Future<Household?> fetchCurrentHousehold() async => DemoData.household;

  @override
  Future<List<HouseholdMember>> fetchMembers(String householdId) async =>
      DemoData.members;
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
      throw ServerException('Failed to load household', cause: e, stackTrace: s);
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
}
