import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// Tracks whether the app is in a password-recovery session — i.e. the user
/// opened the recovery deep link and Supabase established a recovery session.
///
/// While `true` the router pins the user to the reset-password screen so a
/// recovery link can never reach the dashboard before the password is changed.
/// The flag is cleared once the new password is saved or the user backs out.
class PasswordRecoveryController extends Notifier<bool> {
  @override
  bool build() {
    final sub = ref
        .read(authRepositoryProvider)
        .passwordRecoveryEvents()
        .listen((_) => state = true);
    ref.onDispose(sub.cancel);
    return false;
  }

  /// Marks recovery resolved (password changed or explicitly abandoned).
  void resolve() => state = false;
}

final passwordRecoveryPendingProvider =
    NotifierProvider<PasswordRecoveryController, bool>(
      PasswordRecoveryController.new,
    );

/// Sets a new password during a recovery session and exposes loading/error
/// state to the reset-password screen. Mirrors [AuthController]: failures land
/// in [state] instead of throwing into the widget.
class ResetPasswordController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Returns `true` on success. On failure the error lives in [state].
  Future<bool> submit(String newPassword) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).updatePassword(newPassword);
      state = const AsyncData(null);
      ref.read(passwordRecoveryPendingProvider.notifier).resolve();
      return true;
    } catch (error, stack) {
      state = AsyncError(error, stack);
      return false;
    }
  }
}

final resetPasswordControllerProvider =
    NotifierProvider<ResetPasswordController, AsyncValue<void>>(
      ResetPasswordController.new,
    );
