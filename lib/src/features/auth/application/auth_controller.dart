import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import 'auth_providers.dart';

/// Handles auth actions (sign in / up / out / reset) and exposes their async
/// state so the UI can show loading/errors without holding business logic
/// (rule #4/#6).
class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn(String email, String password) => _run(
    () => ref
        .read(authRepositoryProvider)
        .signInWithEmail(email: email, password: password),
  );

  /// Registers a new account. Returns the [SignUpOutcome] on success (so the UI
  /// can tell "signed in" from "confirm your email"), or `null` on failure — in
  /// which case the error lives in [state].
  Future<SignUpOutcome?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    try {
      final outcome = await ref
          .read(authRepositoryProvider)
          .signUpWithEmail(
            email: email,
            password: password,
            displayName: displayName,
          );
      state = const AsyncData(null);
      return outcome;
    } catch (error, stack) {
      state = AsyncError(error, stack);
      return null;
    }
  }

  Future<void> sendPasswordReset(String email) =>
      _run(() => ref.read(authRepositoryProvider).sendPasswordReset(email));

  Future<void> signOut() =>
      _run(() => ref.read(authRepositoryProvider).signOut());

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);
