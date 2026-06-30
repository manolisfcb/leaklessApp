import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/household.dart';
import '../../../domain/models/household_member.dart';
import '../data/household_repository.dart';

final householdRepositoryProvider = Provider<HouseholdRepository>(
  (ref) => const MockHouseholdRepository(),
);

/// The user's active household.
final currentHouseholdProvider = FutureProvider<Household?>(
  (ref) => ref.watch(householdRepositoryProvider).fetchCurrentHousehold(),
);

/// Members of the active household (the couple).
final householdMembersProvider = FutureProvider<List<HouseholdMember>>((
  ref,
) async {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) return const [];
  return ref.watch(householdRepositoryProvider).fetchMembers(household.id);
});
