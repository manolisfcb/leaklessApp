import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/features/household/application/invitation_intent_controller.dart';

void main() {
  const tokenA =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const tokenB =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

  test(
    'restores, validates and clears only the token in secure storage',
    () async {
      final store = _MemoryInvitationIntentStore(initialValue: tokenA);
      final container = ProviderContainer(
        overrides: [invitationIntentStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      container.read(invitationIntentControllerProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(invitationIntentControllerProvider).token, tokenA);

      final captured = await container
          .read(invitationIntentControllerProvider.notifier)
          .capture(tokenB.toUpperCase());

      expect(captured, isTrue);
      expect(store.value, tokenB);
      expect(store.value, isNot(contains('://')));

      await container
          .read(invitationIntentControllerProvider.notifier)
          .discard();
      expect(container.read(invitationIntentControllerProvider).token, isNull);
      expect(store.value, isNull);
    },
  );

  test('a newly captured deep link wins over a late storage restore', () async {
    final store = _DelayedInvitationIntentStore();
    final container = ProviderContainer(
      overrides: [invitationIntentStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    container.read(invitationIntentControllerProvider);
    final capture = container
        .read(invitationIntentControllerProvider.notifier)
        .capture(tokenB);
    store.readCompleter.complete(tokenA);
    await capture;
    await Future<void>.delayed(Duration.zero);

    expect(container.read(invitationIntentControllerProvider).token, tokenB);
    expect(store.value, tokenB);
  });
}

class _MemoryInvitationIntentStore implements InvitationIntentStore {
  _MemoryInvitationIntentStore({String? initialValue}) : value = initialValue;

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;

  @override
  Future<void> clear() async => value = null;
}

class _DelayedInvitationIntentStore implements InvitationIntentStore {
  final readCompleter = Completer<String?>();
  String? value;

  @override
  Future<String?> read() => readCompleter.future;

  @override
  Future<void> write(String token) async => value = token;

  @override
  Future<void> clear() async => value = null;
}
