import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../household/application/household_providers.dart';
import '../../profile/application/profile_providers.dart';
import 'auth_providers.dart';
import 'password_recovery_controller.dart';

/// Invalidates every user/household-scoped cache whenever the authenticated
/// account changes (including sign out).
///
/// Riverpod keeps `FutureProvider` results cached until invalidated, so without
/// this a sign out followed by a different sign in could momentarily surface the
/// previous user's household, members or profile. Household-scoped feature data
/// (transactions, budgets, goals, subscriptions) all watch
/// [currentHouseholdProvider], so invalidating it cascades to them too.
///
/// Watched once at the app root ([sessionGuardProvider]) to keep it alive.
final sessionGuardProvider = Provider<void>((ref) {
  var lastUserId = ref.read(authRepositoryProvider).currentUser?.id;

  final sub = ref.read(authRepositoryProvider).authStateChanges().listen((
    user,
  ) {
    final newUserId = user?.id;
    if (newUserId == lastUserId) return;
    lastUserId = newUserId;

    ref.invalidate(currentProfileProvider);
    ref.invalidate(currentHouseholdProvider);
    ref.invalidate(householdMembersProvider);
    ref.invalidate(householdSetupStateProvider);

    // A fresh sign-out must not leave a stale recovery flag pinning the next
    // session to the reset-password screen.
    if (newUserId == null) {
      ref.read(passwordRecoveryPendingProvider.notifier).resolve();
    }
  });

  ref.onDispose(sub.cancel);
});
