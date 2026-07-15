import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_messaging_service.dart';
import 'notification_permission_handler.dart';
import 'notification_router.dart';
import 'notification_service.dart';

/// The push notification service (Firebase-backed, no-op until configured).
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = FirebaseMessagingService();
  ref.onDispose(service.dispose);
  return service;
});

/// Maps push payloads to in-app routes.
final notificationRouterProvider = Provider<NotificationRouter>(
  (ref) => const NotificationRouter(),
);

/// Permission-flow helper.
final notificationPermissionHandlerProvider =
    Provider<NotificationPermissionHandler>(
      (ref) =>
          NotificationPermissionHandler(ref.watch(notificationServiceProvider)),
    );

/// Current OS notification permission status.
final notificationPermissionProvider =
    FutureProvider<NotificationPermissionStatus>(
      (ref) => ref.watch(notificationServiceProvider).currentStatus(),
    );
