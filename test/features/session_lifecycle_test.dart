import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/features/auth/application/auth_providers.dart';
import 'package:leakless/src/features/auth/application/password_recovery_controller.dart';
import 'package:leakless/src/features/auth/application/session_guard.dart';
import 'package:leakless/src/features/auth/data/auth_repository.dart';
import 'package:leakless/src/features/household/application/household_providers.dart';

void main() {
  group('session guard', () {
    test('invalidates the household cache when the account changes', () async {
      var builds = 0;
      final auth = FakeAuthRepository();
      addTearDown(auth.dispose);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          currentHouseholdProvider.overrideWith((ref) async {
            builds++;
            return null;
          }),
        ],
      );
      addTearDown(container.dispose);

      container.read(sessionGuardProvider); // keep alive
      await container.read(currentHouseholdProvider.future);
      expect(builds, 1);

      // A different account signs in → the stale cache must be dropped.
      await auth.signInWithEmail(email: 'a@leakless.app', password: 'x');
      await Future<void>.delayed(Duration.zero);
      await container.read(currentHouseholdProvider.future);
      expect(
        builds,
        2,
        reason: 'household should be refetched for the new user',
      );

      // Signing out must also drop it.
      await auth.signOut();
      await Future<void>.delayed(Duration.zero);
      await container.read(currentHouseholdProvider.future);
      expect(builds, 3, reason: 'household should be cleared on sign out');
    });

    test('clears a pending recovery flag on sign out', () async {
      final auth = FakeAuthRepository();
      addTearDown(auth.dispose);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);

      container.read(sessionGuardProvider);
      // Build the provider so it subscribes before the (bufferless) event fires.
      container.read(passwordRecoveryPendingProvider);
      auth.emitPasswordRecovery();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(passwordRecoveryPendingProvider), isTrue);

      await auth.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(passwordRecoveryPendingProvider), isFalse);
    });
  });

  group('reset password controller', () {
    test('submitting a new password resolves the recovery flag', () async {
      final auth = FakeAuthRepository();
      addTearDown(auth.dispose);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);

      container.read(passwordRecoveryPendingProvider);
      auth.emitPasswordRecovery();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(passwordRecoveryPendingProvider), isTrue);

      final ok = await container
          .read(resetPasswordControllerProvider.notifier)
          .submit('newpass123');
      expect(ok, isTrue);
      expect(container.read(passwordRecoveryPendingProvider), isFalse);
    });
  });
}
