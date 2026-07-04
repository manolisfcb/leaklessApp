import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// Drives the re-authenticated "delete my account" flow and exposes its
/// loading/error state. Mirrors [AuthController]: failures land in [state]
/// instead of throwing into the widget.
class AccountDeletionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Re-verifies [password] before deleting the account server-side. Returns
  /// `true` on success (the session is cleared and the router redirects to
  /// auth); on failure the error lives in [state].
  ///
  /// [confirmHouseholdDeletion] must be `true` only when the caller is the sole
  /// member of their household, acknowledging that its shared data is deleted
  /// with the account.
  Future<bool> deleteAccount({
    required String password,
    required bool confirmHouseholdDeletion,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.reauthenticate(password);
      await repo.deleteAccount(
        confirmHouseholdDeletion: confirmHouseholdDeletion,
      );
      state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      state = AsyncError(error, stack);
      return false;
    }
  }
}

final accountDeletionControllerProvider =
    NotifierProvider<AccountDeletionController, AsyncValue<void>>(
      AccountDeletionController.new,
    );
