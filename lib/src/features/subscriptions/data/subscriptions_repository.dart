import '../../../core/dev/demo_data.dart';
import '../../../domain/models/subscription_item.dart';

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
