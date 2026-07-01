import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dev/demo_data.dart';
import '../../../core/errors/app_exception.dart';
import '../../../domain/models/subscription_item.dart';
import 'subscription_mapper.dart';

/// Reads detected recurring subscriptions for the household.
abstract interface class SubscriptionsRepository {
  Future<List<SubscriptionItem>> fetchForHousehold(String householdId);
}

/// Mock subscriptions from [DemoData]. Replace with a Supabase implementation
/// (querying `subscriptions`) once wired.
class MockSubscriptionsRepository implements SubscriptionsRepository {
  const MockSubscriptionsRepository();

  @override
  Future<List<SubscriptionItem>> fetchForHousehold(String householdId) async =>
      DemoData.subscriptions();
}

/// Supabase-backed subscription reads, scoped to the active household.
///
/// RLS already restricts `subscriptions` to the user's household; the explicit
/// `household_id` filter keeps this correct if a user ever belongs to more than
/// one, and mirrors the `transactions` pattern. Ordered by the soonest upcoming
/// charge (nulls last, Postgres default for ascending order).
class SupabaseSubscriptionsRepository implements SubscriptionsRepository {
  SupabaseSubscriptionsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<SubscriptionItem>> fetchForHousehold(String householdId) async {
    try {
      final rows = await _client
          .from('subscriptions')
          .select()
          .eq('household_id', householdId)
          .order('next_charge_at', ascending: true);
      return rows.map(SubscriptionMapper.fromRow).toList();
    } catch (e, s) {
      throw ServerException('Failed to load subscriptions', cause: e, stackTrace: s);
    }
  }
}
