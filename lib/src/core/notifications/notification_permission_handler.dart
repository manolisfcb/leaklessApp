import 'notification_service.dart';

/// Small policy wrapper around requesting notification permission.
///
/// Keeps the "ask once, then respect the OS decision" logic out of the UI. The
/// design routes the transaction → partner push through here, but we never ask
/// for sensitive permissions (SMS / notification listener) at this stage.
class NotificationPermissionHandler {
  NotificationPermissionHandler(this._service);

  final NotificationService _service;

  /// Requests permission and reports whether notifications are allowed.
  Future<bool> ensurePermission() async {
    final current = await _service.currentStatus();
    if (current.isGranted) return true;
    if (current == NotificationPermissionStatus.denied) return false;
    final result = await _service.requestPermission();
    return result.isGranted;
  }
}
