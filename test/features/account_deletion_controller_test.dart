import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/core/errors/app_exception.dart';
import 'package:leakless/src/features/auth/application/account_deletion_controller.dart';
import 'package:leakless/src/features/auth/application/auth_providers.dart';
import 'package:leakless/src/features/auth/data/auth_repository.dart';

void main() {
  group('AccountDeletionController', () {
    test('deletes the account after a successful re-auth', () async {
      final auth = FakeAuthRepository();
      addTearDown(auth.dispose);
      await auth.signInWithEmail(email: 'me@leakless.app', password: 'right');
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);

      final ok = await container
          .read(accountDeletionControllerProvider.notifier)
          .deleteAccount(password: 'right', confirmHouseholdDeletion: true);

      expect(ok, isTrue);
      expect(auth.currentUser, isNull, reason: 'session should be cleared');
      expect(container.read(accountDeletionControllerProvider).hasError, isFalse);
    });

    test('surfaces a wrong password without deleting the account', () async {
      final auth = FakeAuthRepository();
      addTearDown(auth.dispose);
      await auth.signInWithEmail(email: 'me@leakless.app', password: 'right');
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);

      final ok = await container
          .read(accountDeletionControllerProvider.notifier)
          .deleteAccount(password: 'wrong', confirmHouseholdDeletion: false);

      expect(ok, isFalse);
      expect(auth.currentUser, isNotNull, reason: 'account must not be deleted');
      final error = container.read(accountDeletionControllerProvider).error;
      expect(error, isA<AuthFailureException>());
    });
  });
}
