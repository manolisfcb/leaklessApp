import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../domain/models/household.dart';
import '../../../domain/models/household_invitation.dart';
import '../../../domain/models/household_member.dart';
import '../../profile/application/profile_providers.dart';
import '../data/household_repository.dart';

/// Real (Supabase) or mock repository, chosen by config — same pattern as
/// [transactionsRepositoryProvider]. This resolves the real `householdId` that
/// scopes every other feature.
final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  if (ref.watch(supabaseEnabledProvider)) {
    return SupabaseHouseholdRepository(ref.watch(supabaseClientProvider));
  }
  return MockHouseholdRepository();
});

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

/// Coordinates invitation actions and exposes their latest result/error.
class HouseholdInvitationsController
    extends Notifier<AsyncValue<HouseholdInvitation?>> {
  @override
  AsyncValue<HouseholdInvitation?> build() => const AsyncData(null);

  Future<HouseholdInvitation?> create({
    required String householdId,
    required String email,
    Duration expiresIn = const Duration(days: 7),
  }) => _run(
    () => ref
        .read(householdRepositoryProvider)
        .createInvitation(
          householdId: householdId,
          email: email,
          expiresIn: expiresIn,
        ),
  );

  Future<HouseholdInvitation?> inspect(String token) => _run(
    () => ref.read(householdRepositoryProvider).inspectInvitation(token),
  );

  Future<HouseholdInvitation?> cancel(String invitationId) => _run(
    () => ref.read(householdRepositoryProvider).cancelInvitation(invitationId),
  );

  Future<HouseholdInvitation?> accept(String token) => _run(
    () => ref.read(householdRepositoryProvider).acceptInvitation(token),
    refreshHouseholdScope: true,
  );

  void clear() => state = const AsyncData(null);

  Future<HouseholdInvitation?> _run(
    Future<HouseholdInvitation> Function() action, {
    bool refreshHouseholdScope = false,
  }) async {
    state = const AsyncLoading();
    try {
      final invitation = await action();
      if (refreshHouseholdScope) {
        // Every household-scoped data provider watches currentHouseholdProvider,
        // so invalidating it also rebuilds transactions, categories, budgets,
        // goals and subscriptions for the accepted household.
        ref.invalidate(currentHouseholdProvider);
        ref.invalidate(householdMembersProvider);
        ref.invalidate(currentProfileProvider);
      }
      state = AsyncData(invitation);
      return invitation;
    } catch (error, stack) {
      state = AsyncError(error, stack);
      return null;
    }
  }
}

final householdInvitationsControllerProvider =
    NotifierProvider<
      HouseholdInvitationsController,
      AsyncValue<HouseholdInvitation?>
    >(HouseholdInvitationsController.new);
