import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_event.freezed.dart';
part 'notification_event.g.dart';

/// A cross-member notification event (e.g. "Pareja registró Uber $24.50").
///
/// Persisted so the in-app inbox and the push payload share one shape. [type]
/// is a free-form key the [NotificationRouter] maps to a deep link.
@freezed
abstract class NotificationEvent with _$NotificationEvent {
  const factory NotificationEvent({
    required String id,
    required String householdId,
    required String type,
    required String title,
    required String body,
    String? actorMemberId,
    String? transactionId,
    @Default(false) bool isRead,
    DateTime? createdAt,
  }) = _NotificationEvent;

  factory NotificationEvent.fromJson(Map<String, dynamic> json) =>
      _$NotificationEventFromJson(json);
}
