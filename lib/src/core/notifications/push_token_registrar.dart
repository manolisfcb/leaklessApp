import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/application/auth_providers.dart';
import '../logging/app_logger.dart';
import '../supabase/supabase_providers.dart';
import 'notification_providers.dart';
import 'notification_service.dart';

/// Persistence for device push tokens (`device_push_tokens` table).
///
/// Same interface + Supabase/no-op split as the repositories: the no-op keeps
/// mock mode (no `.env`) working without a backend.
abstract interface class PushTokenStore {
  Future<void> upsertToken({
    required String userId,
    required String token,
    required String platform,
  });

  Future<void> deleteToken(String token);
}

class NoopPushTokenStore implements PushTokenStore {
  const NoopPushTokenStore();

  @override
  Future<void> upsertToken({
    required String userId,
    required String token,
    required String platform,
  }) async {}

  @override
  Future<void> deleteToken(String token) async {}
}

class SupabasePushTokenStore implements PushTokenStore {
  SupabasePushTokenStore(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upsertToken({
    required String userId,
    required String token,
    required String platform,
  }) {
    return _client.from('device_push_tokens').upsert({
      'user_id': userId,
      'token': token,
      'platform': platform,
    }, onConflict: 'token');
  }

  @override
  Future<void> deleteToken(String token) {
    return _client.from('device_push_tokens').delete().eq('token', token);
  }
}

/// Keeps the device's push token registered for whoever is signed in.
///
/// Reacts to two signals: account changes (sign in/out) and token refreshes
/// from the push provider. Permission is NOT requested here — that happens
/// contextually when the user enables their first budget alert; on Android a
/// token exists regardless, and on iOS [NotificationService.getToken] returns
/// null until permission lands, after which `onTokenRefreshed` re-triggers us.
class PushTokenRegistrar {
  PushTokenRegistrar({
    required NotificationService service,
    required PushTokenStore store,
    required String platform,
  }) : _service = service,
       _store = store,
       _platform = platform;

  final NotificationService _service;
  final PushTokenStore _store;
  final String _platform;
  final _log = AppLogger.of('PushTokens');

  String? _userId;
  String? _lastToken;

  Future<void> handleUserChanged(String? userId) async {
    if (userId == _userId) return;
    _userId = userId;
    if (userId == null) {
      await _unregister();
    } else {
      await _register(userId);
    }
  }

  Future<void> handleTokenRefreshed(String token) async {
    _lastToken = token;
    final userId = _userId;
    if (userId == null) return;
    await _upsert(userId, token);
  }

  Future<void> _register(String userId) async {
    final token = await _service.getToken();
    if (token == null) {
      return; // No Firebase, or iOS permission not granted yet.
    }
    _lastToken = token;
    await _upsert(userId, token);
  }

  /// Best effort: by the time the sign-out event reaches us the Supabase
  /// session is already gone, so the RLS-guarded row delete may be a no-op.
  /// Invalidating the token at the provider guarantees no push arrives anyway,
  /// and the Edge Function prunes the dead row on its next send.
  Future<void> _unregister() async {
    final token = _lastToken;
    _lastToken = null;
    if (token == null) return;
    try {
      await _store.deleteToken(token);
    } catch (error) {
      _log.fine('token row delete skipped: $error');
    }
    await _service.deleteToken();
  }

  Future<void> _upsert(String userId, String token) async {
    try {
      await _store.upsertToken(
        userId: userId,
        token: token,
        platform: _platform,
      );
    } catch (error, stack) {
      // Never surface push plumbing failures to the UI.
      _log.warning('token upsert failed', error, stack);
    }
  }
}

final pushTokenStoreProvider = Provider<PushTokenStore>((ref) {
  if (ref.watch(supabaseEnabledProvider)) {
    return SupabasePushTokenStore(ref.watch(supabaseClientProvider));
  }
  return const NoopPushTokenStore();
});

/// Watched once at the app root (like `sessionGuardProvider`) so the device
/// token follows the signed-in account for the whole app lifetime.
final pushTokenRegistrarProvider = Provider<void>((ref) {
  final service = ref.watch(notificationServiceProvider);
  final registrar = PushTokenRegistrar(
    service: service,
    store: ref.watch(pushTokenStoreProvider),
    platform: defaultTargetPlatform.name,
  );

  final auth = ref.watch(authRepositoryProvider);
  unawaited(registrar.handleUserChanged(auth.currentUser?.id));
  final authSub = auth.authStateChanges().listen(
    (user) => registrar.handleUserChanged(user?.id),
  );
  final tokenSub = service.onTokenRefreshed.listen(
    registrar.handleTokenRefreshed,
  );

  ref.onDispose(() {
    unawaited(authSub.cancel());
    unawaited(tokenSub.cancel());
  });
});
