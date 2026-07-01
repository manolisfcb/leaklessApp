import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../domain/models/subscription_item.dart';
import '../../household/application/household_providers.dart';
import '../data/subscriptions_repository.dart';

/// Real (Supabase) or mock repository, chosen by config — same pattern as
/// [budgetsRepositoryProvider] / [transactionsRepositoryProvider].
final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>((ref) {
  if (ref.watch(supabaseEnabledProvider)) {
    return SupabaseSubscriptionsRepository(ref.watch(supabaseClientProvider));
  }
  return const MockSubscriptionsRepository();
});

/// Detected subscriptions for the active household.
final subscriptionsProvider = FutureProvider<List<SubscriptionItem>>((
  ref,
) async {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) return const [];
  return ref
      .watch(subscriptionsRepositoryProvider)
      .fetchForHousehold(household.id);
});
