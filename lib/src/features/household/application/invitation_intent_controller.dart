import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'invitation_links.dart';

/// Minimal storage boundary for a pending invitation credential.
abstract interface class InvitationIntentStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

final class SecureInvitationIntentStore implements InvitationIntentStore {
  SecureInvitationIntentStore(this._storage);

  static const _storageKey = 'pending_household_invitation_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _storageKey);

  @override
  Future<void> write(String token) =>
      _storage.write(key: _storageKey, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _storageKey);
}

final invitationIntentStoreProvider = Provider<InvitationIntentStore>((ref) {
  return SecureInvitationIntentStore(const FlutterSecureStorage());
});

class InvitationIntentState {
  const InvitationIntentState({
    this.token,
    this.hydrated = false,
    this.persistenceFailed = false,
  });

  final String? token;
  final bool hydrated;
  final bool persistenceFailed;

  InvitationIntentState copyWith({
    String? token,
    bool clearToken = false,
    bool? hydrated,
    bool? persistenceFailed,
  }) => InvitationIntentState(
    token: clearToken ? null : token ?? this.token,
    hydrated: hydrated ?? this.hydrated,
    persistenceFailed: persistenceFailed ?? this.persistenceFailed,
  );
}

/// Holds the invitation while auth is completed and persists only its token.
class InvitationIntentController extends Notifier<InvitationIntentState> {
  var _revision = 0;

  @override
  InvitationIntentState build() {
    unawaited(_restore());
    return const InvitationIntentState();
  }

  Future<bool> capture(String rawToken) async {
    final token = InvitationLinks.normalizeToken(rawToken);
    if (token == null) return false;
    if (state.hydrated && state.token == token) return true;

    _revision++;
    state = InvitationIntentState(token: token, hydrated: true);
    try {
      await ref.read(invitationIntentStoreProvider).write(token);
    } catch (_) {
      // Keep the credential in memory for this app session, but make the
      // degraded persistence visible to the invitation screen.
      state = state.copyWith(persistenceFailed: true);
    }
    return true;
  }

  Future<void> discard() async {
    _revision++;
    state = const InvitationIntentState(hydrated: true);
    try {
      await ref.read(invitationIntentStoreProvider).clear();
    } catch (_) {
      state = state.copyWith(persistenceFailed: true);
    }
  }

  Future<void> _restore() async {
    final revision = _revision;
    try {
      final stored = await ref.read(invitationIntentStoreProvider).read();
      if (revision != _revision) return;
      final token = InvitationLinks.normalizeToken(stored);
      state = InvitationIntentState(token: token, hydrated: true);
      if (stored != null && token == null) {
        await ref.read(invitationIntentStoreProvider).clear();
      }
    } catch (_) {
      if (revision == _revision) {
        state = const InvitationIntentState(
          hydrated: true,
          persistenceFailed: true,
        );
      }
    }
  }
}

final invitationIntentControllerProvider =
    NotifierProvider<InvitationIntentController, InvitationIntentState>(
      InvitationIntentController.new,
    );
