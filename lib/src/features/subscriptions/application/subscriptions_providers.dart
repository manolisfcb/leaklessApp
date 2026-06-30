import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/subscription_item.dart';
import '../../household/application/household_providers.dart';
import '../data/subscriptions_repository.dart';

final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>(
  (ref) => const MockSubscriptionsRepository(),
);

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
