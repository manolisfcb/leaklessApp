import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/core/notifications/notification_service.dart';
import 'package:leakless/src/core/notifications/push_token_registrar.dart';

class _FakeNotificationService implements NotificationService {
  String? token = 'token-1';
  int deleteTokenCalls = 0;
  // Closed in tearDown; the lint can't see across the fake's lifecycle.
  // ignore: close_sinks
  final tokenController = StreamController<String>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  Future<NotificationPermissionStatus> requestPermission() async =>
      NotificationPermissionStatus.granted;

  @override
  Future<NotificationPermissionStatus> currentStatus() async =>
      NotificationPermissionStatus.granted;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> deleteToken() async {
    deleteTokenCalls++;
    token = null;
  }

  @override
  Stream<String> get onTokenRefreshed => tokenController.stream;

  @override
  Stream<NotificationMessage> get onMessageOpened => const Stream.empty();
}

class _RecordingStore implements PushTokenStore {
  final upserts = <(String userId, String token, String platform)>[];
  final deletes = <String>[];
  Object? throwOnUpsert;

  @override
  Future<void> upsertToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    if (throwOnUpsert != null) throw throwOnUpsert!;
    upserts.add((userId, token, platform));
  }

  @override
  Future<void> deleteToken(String token) async => deletes.add(token);
}

void main() {
  late _FakeNotificationService service;
  late _RecordingStore store;
  late PushTokenRegistrar registrar;

  setUp(() {
    service = _FakeNotificationService();
    store = _RecordingStore();
    registrar = PushTokenRegistrar(
      service: service,
      store: store,
      platform: 'android',
    );
  });

  tearDown(() => service.tokenController.close());

  test('upserts the current token when a user signs in', () async {
    await registrar.handleUserChanged('user-1');

    expect(store.upserts, [('user-1', 'token-1', 'android')]);
  });

  test('skips registration when no token is available', () async {
    service.token = null;

    await registrar.handleUserChanged('user-1');

    expect(store.upserts, isEmpty);
  });

  test('re-upserts when the provider refreshes the token', () async {
    await registrar.handleUserChanged('user-1');
    await registrar.handleTokenRefreshed('token-2');

    expect(store.upserts, [
      ('user-1', 'token-1', 'android'),
      ('user-1', 'token-2', 'android'),
    ]);
  });

  test('ignores token refreshes while signed out', () async {
    await registrar.handleTokenRefreshed('token-2');

    expect(store.upserts, isEmpty);
  });

  test('deletes the row and invalidates the token on sign out', () async {
    await registrar.handleUserChanged('user-1');
    await registrar.handleUserChanged(null);

    expect(store.deletes, ['token-1']);
    expect(service.deleteTokenCalls, 1);
  });

  test('sign out without a registered token does nothing', () async {
    await registrar.handleUserChanged(null);

    expect(store.deletes, isEmpty);
    expect(service.deleteTokenCalls, 0);
  });

  test('repeated events for the same user do not re-upsert', () async {
    await registrar.handleUserChanged('user-1');
    await registrar.handleUserChanged('user-1');

    expect(store.upserts, hasLength(1));
  });

  test('a new account on the same device re-registers the token', () async {
    await registrar.handleUserChanged('user-1');
    await registrar.handleUserChanged(null);
    service.token = 'token-3'; // FCM issues a fresh token after deleteToken
    await registrar.handleUserChanged('user-2');

    expect(store.upserts.last, ('user-2', 'token-3', 'android'));
  });

  test('store failures are swallowed (push plumbing must never crash)', () async {
    store.throwOnUpsert = StateError('offline');

    await expectLater(registrar.handleUserChanged('user-1'), completes);
  });
}
