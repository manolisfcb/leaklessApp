/// Permission state for push notifications, decoupled from any SDK enum.
enum NotificationPermissionStatus {
  granted,
  denied,
  provisional,
  notDetermined;

  bool get isGranted =>
      this == NotificationPermissionStatus.granted ||
      this == NotificationPermissionStatus.provisional;
}

/// A normalized push message — the app never passes `RemoteMessage` around so
/// the UI/domain stay independent of Firebase (quality rule #7).
class NotificationMessage {
  const NotificationMessage({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;
  final Map<String, dynamic> data;
}

/// Abstraction over the push provider.
///
/// The concrete implementation is [FirebaseMessagingService]; depending on this
/// interface keeps features testable and swappable.
abstract interface class NotificationService {
  /// Sets up listeners (foreground/opened) and the token refresh hook.
  Future<void> initialize();

  /// Requests OS permission to display notifications.
  Future<NotificationPermissionStatus> requestPermission();

  /// Current permission status without prompting.
  Future<NotificationPermissionStatus> currentStatus();

  /// The device push token, if available.
  Future<String?> getToken();

  /// Invalidates the current device token (e.g. on sign out) so no further
  /// pushes reach this device until a new token is issued.
  Future<void> deleteToken();

  /// Emits whenever the push provider issues a new device token.
  Stream<String> get onTokenRefreshed;

  /// Emits when the user taps a notification that opened/foregrounded the app.
  Stream<NotificationMessage> get onMessageOpened;
}
