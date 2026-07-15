import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/subscription_item.dart';
import '../../features/subscriptions/application/subscriptions_providers.dart';
import '../l10n/app_localizations.dart';
import '../logging/app_logger.dart';
import '../prefs/locale_controller.dart';

/// Push-payload type routed to the subscriptions screen (see NotificationRouter).
const kRecurringReminderType = 'recurring_reminder';

/// Android channel id for recurring-charge reminders. Stable so the OS keeps a
/// single channel regardless of the (localized) display name.
const _reminderChannelId = 'recurring_reminders';

/// Localized copy for a reminder notification, resolved by the caller (which
/// has the current locale) so the scheduler itself stays free of l10n.
class ReminderContent {
  const ReminderContent({
    required this.channelName,
    required this.channelDescription,
    required this.title,
    required this.body,
  });

  final String channelName;
  final String channelDescription;
  final String title;

  /// Builds the notification body from the subscription's display name.
  final String Function(String subscriptionName) body;
}

/// The slice of `flutter_local_notifications` the scheduler depends on. Kept
/// behind an interface so the scheduling/reconciliation logic is unit-testable
/// with a fake (the plugin needs a real platform to run).
abstract interface class LocalNotifications {
  Future<void> initialize();
  Future<Set<int>> pendingIds();
  Future<void> schedule({
    required int id,
    required String channelName,
    required String channelDescription,
    required String title,
    required String body,
    required DateTime when,
    required String payload,
  });
  Future<void> cancel(int id);
}

/// Stable 31-bit notification id derived from a subscription id.
///
/// `String.hashCode` is not guaranteed stable across process runs, so we roll
/// our own: a deterministic id lets `zonedSchedule` replace the existing
/// pending reminder and survive app restarts.
int reminderNotificationId(String subscriptionId) {
  var hash = 0;
  for (final unit in subscriptionId.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash;
}

/// Schedules local, server-free reminders for recurring charges.
///
/// [syncSchedules] reconciles the OS's pending notifications with the current
/// set of subscriptions: it cancels reminders that are no longer wanted and
/// (re)schedules the rest at 09:00 local time, [reminderDaysBefore] days before
/// each `next_charge_at`. Subscriptions whose charge date has already passed are
/// returned so the caller can advance + persist them (which re-emits the stream
/// and triggers another sync with the fresh dates — reminders keep firing across
/// months without a server).
class LocalReminderScheduler {
  LocalReminderScheduler(this._notifications, {int reminderHour = 9})
    : _reminderHour = reminderHour;

  final LocalNotifications _notifications;
  final int _reminderHour;
  var _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _notifications.initialize();
    _initialized = true;
  }

  Future<List<SubscriptionItem>> syncSchedules(
    List<SubscriptionItem> items, {
    required ReminderContent content,
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final overdue = <SubscriptionItem>[];
    final desired = <int, ({SubscriptionItem item, DateTime fireAt})>{};
    for (final item in items) {
      if (!item.reminderEnabled) continue;
      final charge = item.nextChargeAt;
      if (charge == null) continue;
      if (!charge.isAfter(current)) {
        overdue.add(item);
        continue;
      }
      final fireAt = _fireTime(charge, item.reminderDaysBefore);
      // The reminder window (days-before) may already be behind us even though
      // the charge is still ahead; skip rather than schedule in the past.
      if (!fireAt.isAfter(current)) continue;
      desired[reminderNotificationId(item.id)] = (item: item, fireAt: fireAt);
    }

    final pending = await _notifications.pendingIds();
    for (final id in pending.difference(desired.keys.toSet())) {
      await _notifications.cancel(id);
    }
    for (final entry in desired.entries) {
      final reminder = entry.value;
      await _notifications.schedule(
        id: entry.key,
        channelName: content.channelName,
        channelDescription: content.channelDescription,
        title: content.title,
        body: content.body(reminder.item.name),
        when: reminder.fireAt,
        payload: jsonEncode({
          'type': kRecurringReminderType,
          'subscriptionId': reminder.item.id,
        }),
      );
    }
    return overdue;
  }

  /// 09:00 local time, [daysBefore] days before [charge].
  DateTime _fireTime(DateTime charge, int daysBefore) {
    final day = charge.subtract(Duration(days: daysBefore));
    return DateTime(day.year, day.month, day.day, _reminderHour);
  }
}

/// [LocalNotifications] backed by `flutter_local_notifications` + `timezone`.
///
/// Every entry point degrades to a safe no-op-on-failure so a missing platform
/// plugin never breaks the app (mock mode still runs on a device).
class FlutterLocalNotifications implements LocalNotifications {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _log = AppLogger.of('LocalReminders');
  var _ready = false;

  @override
  Future<void> initialize() async {
    try {
      tz_data.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (error) {
      // Keep the default (UTC) location; reminders still fire, just in UTC.
      _log.fine('timezone init skipped: $error');
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    try {
      await _plugin.initialize(settings: settings);
      _ready = true;
    } catch (error) {
      _log.fine('plugin init skipped: $error');
    }
  }

  @override
  Future<Set<int>> pendingIds() async {
    if (!_ready) return const {};
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.map((request) => request.id).toSet();
    } catch (error) {
      _log.fine('pending lookup failed: $error');
      return const {};
    }
  }

  @override
  Future<void> schedule({
    required int id,
    required String channelName,
    required String channelDescription,
    required String title,
    required String body,
    required DateTime when,
    required String payload,
  }) async {
    if (!_ready) return;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _reminderChannelId,
        channelName,
        channelDescription: channelDescription,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );
    try {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: details,
        // Inexact keeps us off the exact-alarm permission on Android 12+.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: payload,
      );
    } catch (error) {
      _log.fine('schedule failed for $id: $error');
    }
  }

  @override
  Future<void> cancel(int id) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: id);
    } catch (error) {
      _log.fine('cancel failed for $id: $error');
    }
  }
}

final localNotificationsProvider = Provider<LocalNotifications>(
  (ref) => FlutterLocalNotifications(),
);

final localReminderSchedulerProvider = Provider<LocalReminderScheduler>(
  (ref) => LocalReminderScheduler(ref.watch(localNotificationsProvider)),
);

/// Keeps OS reminders in sync with the household's subscriptions.
///
/// Watched once at the app root: it reconciles on every subscription change
/// (each CRUD re-emits the stream) and exposes [resync] for the app-resume hook
/// so charges that lapsed while backgrounded get advanced and rescheduled.
class ReminderSyncController {
  ReminderSyncController(this._ref);

  final Ref _ref;
  final _log = AppLogger.of('LocalReminders');
  List<SubscriptionItem> _last = const [];

  Future<void> sync(List<SubscriptionItem> items) async {
    _last = items;
    try {
      final scheduler = _ref.read(localReminderSchedulerProvider);
      await scheduler.initialize();
      final overdue = await scheduler.syncSchedules(items, content: _content());
      if (overdue.isEmpty) return;
      final repo = _ref.read(subscriptionsRepositoryProvider);
      for (final item in overdue) {
        // Persisting re-emits the stream, which re-runs sync with fresh dates.
        await repo.advanceNextCharge(item);
      }
    } catch (error, stack) {
      // Reminders are best-effort; never surface plumbing failures to the UI.
      _log.warning('reminder sync failed', error, stack);
    }
  }

  /// Re-runs against the last known subscriptions (e.g. on app resume).
  Future<void> resync() => sync(_last);

  ReminderContent _content() {
    final l10n = lookupAppLocalizations(
      _resolveLocale(_ref.read(localeControllerProvider)),
    );
    return ReminderContent(
      channelName: l10n.recurringReminderChannelName,
      channelDescription: l10n.recurringReminderChannelDescription,
      title: l10n.recurringReminderTitle,
      body: l10n.recurringReminderBody,
    );
  }
}

/// Resolves the manual override (or the system language) to a supported locale,
/// falling back to Spanish — mirrors the fallback in [LeaklessApp].
Locale _resolveLocale(Locale? override) {
  const supported = {'es', 'en', 'pt'};
  final code =
      override?.languageCode ?? PlatformDispatcher.instance.locale.languageCode;
  return Locale(supported.contains(code) ? code : 'es');
}

final reminderSyncControllerProvider = Provider<ReminderSyncController>((ref) {
  final controller = ReminderSyncController(ref);
  ref.listen<AsyncValue<List<SubscriptionItem>>>(subscriptionsProvider, (
    _,
    next,
  ) {
    final items = next.asData?.value;
    if (items != null) unawaited(controller.sync(items));
  }, fireImmediately: true);
  return controller;
});
