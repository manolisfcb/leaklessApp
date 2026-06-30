import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// Handles auth actions (sign in / up / out) and exposes their async state so
/// the UI can show loading/errors without holding business logic (rule #4/#6).
class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn(String email, String password) => _run(
    () => ref
        .read(authRepositoryProvider)
        .signInWithEmail(email: email, password: password),
  );

  Future<void> signUp(String email, String password) => _run(
    () => ref
        .read(authRepositoryProvider)
        .signUpWithEmail(email: email, password: password),
  );

  Future<void> signOut() =>
      _run(() => ref.read(authRepositoryProvider).signOut());

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);
