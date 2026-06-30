import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/errors/app_exception.dart';
import '../../../domain/models/app_user.dart';

/// Authentication boundary used by the app.
///
/// Two implementations exist: [SupabaseAuthRepository] (real) and
/// [FakeAuthRepository] (in-memory, so the app runs before Supabase is wired).
abstract interface class AuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> authStateChanges();
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  });
  Future<void> signOut();
}

/// Supabase-backed authentication. Translates `supabase` errors into the app's
/// own [AppException] types so callers never depend on the SDK (rule #7).
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  AppUser? get currentUser => _mapUser(_client.auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() =>
      _client.auth.onAuthStateChange.map((state) => _mapUser(state.session?.user));

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _guard(() => _client.auth.signInWithPassword(email: email, password: password));

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) => _guard(() => _client.auth.signUp(email: email, password: password));

  @override
  Future<void> signOut() => _guard(_client.auth.signOut);

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on sb.AuthException catch (e, s) {
      throw AuthFailureException(e.message, cause: e, stackTrace: s);
    } catch (e, s) {
      throw ServerException('Auth request failed', cause: e, stackTrace: s);
    }
  }

  AppUser? _mapUser(sb.User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      createdAt: DateTime.tryParse(user.createdAt),
    );
  }
}

/// In-memory auth used when Supabase is not configured. Lets onboarding → auth →
/// dashboard be fully navigable without a backend.
class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async => _setUser(AppUser(id: 'demo-me', email: email));

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async => _setUser(AppUser(id: 'demo-me', email: email));

  @override
  Future<void> signOut() async => _setUser(null);

  void _setUser(AppUser? user) {
    _user = user;
    _controller.add(user);
  }

  void dispose() => unawaited(_controller.close());
}
