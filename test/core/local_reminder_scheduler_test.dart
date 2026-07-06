import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/core/notifications/local_reminder_scheduler.dart';
import 'package:leakless/src/domain/models/money.dart';
import 'package:leakless/src/domain/models/subscription_item.dart';

/// Records everything the scheduler asks of the platform so tests can assert on
/// scheduling/cancellation without a real plugin.
class _FakeLocalNotifications implements LocalNotifications {
  final Map<int, ({DateTime when, String payload, String body})> scheduled = {};
  final List<int> cancelled = [];
  Set<int> pending = {};
  int initializeCalls = 0;

  @override
  Future<void> initialize() async => initializeCalls++;

  @override
  Future<Set<int>> pendingIds() async => pending;

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
    scheduled[id] = (when: when, payload: payload, body: body);
  }

  @override
  Future<void> cancel(int id) async => cancelled.add(id);
}

void main() {
  const content = ReminderContent(
    channelName: 'Reminders',
    channelDescription: 'desc',
    title: 'Upcoming charge',
    body: _body,
  );

  SubscriptionItem sub({
    String id = 'sub-1',
    String name = 'Netflix',
    bool reminderEnabled = true,
    int reminderDaysBefore = 1,
    DateTime? nextChargeAt,
  }) => SubscriptionItem(
    id: id,
    householdId: 'hh',
    name: name,
    amount: const Money(minorUnits: 1000, currency: 'USD'),
    reminderEnabled: reminderEnabled,
    reminderDaysBefore: reminderDaysBefore,
    nextChargeAt: nextChargeAt,
  );

  test('reminderNotificationId is deterministic and non-negative', () {
    expect(reminderNotificationId('sub-1'), reminderNotificationId('sub-1'));
    expect(reminderNotificationId('sub-1'), isNot(reminderNotificationId('sub-2')));
    expect(reminderNotificationId('sub-1'), greaterThanOrEqualTo(0));
  });

  test('schedules an enabled reminder at 09:00 daysBefore the charge', () async {
    final fake = _FakeLocalNotifications();
    final scheduler = LocalReminderScheduler(fake);

    final item = sub(
      reminderDaysBefore: 3,
      nextChargeAt: DateTime(2026, 3, 20, 15, 0),
    );
    final overdue = await scheduler.syncSchedules(
      [item],
      content: content,
      now: DateTime(2026, 3, 1),
    );

    expect(overdue, isEmpty);
    final id = reminderNotificationId('sub-1');
    expect(fake.scheduled.containsKey(id), isTrue);
    expect(fake.scheduled[id]!.when, DateTime(2026, 3, 17, 9));
    expect(fake.scheduled[id]!.body, 'body:Netflix');
    expect(
      jsonDecode(fake.scheduled[id]!.payload),
      {'type': 'recurring_reminder', 'subscriptionId': 'sub-1'},
    );
  });

  test('skips disabled reminders and items without a charge date', () async {
    final fake = _FakeLocalNotifications();
    final scheduler = LocalReminderScheduler(fake);

    await scheduler.syncSchedules(
      [
        sub(id: 'off', reminderEnabled: false, nextChargeAt: DateTime(2026, 5, 1)),
        sub(id: 'nodate', nextChargeAt: null),
      ],
      content: content,
      now: DateTime(2026, 3, 1),
    );

    expect(fake.scheduled, isEmpty);
  });

  test('returns overdue subscriptions without scheduling them', () async {
    final fake = _FakeLocalNotifications();
    final scheduler = LocalReminderScheduler(fake);

    final overdue = await scheduler.syncSchedules(
      [sub(nextChargeAt: DateTime(2026, 2, 1))],
      content: content,
      now: DateTime(2026, 3, 1),
    );

    expect(overdue.map((s) => s.id), ['sub-1']);
    expect(fake.scheduled, isEmpty);
  });

  test('skips scheduling when the reminder window already elapsed', () async {
    final fake = _FakeLocalNotifications();
    final scheduler = LocalReminderScheduler(fake);

    // Charge is still ahead, but daysBefore pushes the fire time into the past.
    final overdue = await scheduler.syncSchedules(
      [sub(reminderDaysBefore: 10, nextChargeAt: DateTime(2026, 3, 3))],
      content: content,
      now: DateTime(2026, 3, 1),
    );

    expect(overdue, isEmpty);
    expect(fake.scheduled, isEmpty);
  });

  test('cancels pending reminders that are no longer wanted', () async {
    final fake = _FakeLocalNotifications()
      ..pending = {reminderNotificationId('stale'), reminderNotificationId('sub-1')};
    final scheduler = LocalReminderScheduler(fake);

    await scheduler.syncSchedules(
      [sub(nextChargeAt: DateTime(2026, 5, 10))],
      content: content,
      now: DateTime(2026, 3, 1),
    );

    expect(fake.cancelled, [reminderNotificationId('stale')]);
    expect(fake.scheduled.containsKey(reminderNotificationId('sub-1')), isTrue);
  });

  test('initialize runs the platform setup only once', () async {
    final fake = _FakeLocalNotifications();
    final scheduler = LocalReminderScheduler(fake);
    await scheduler.initialize();
    await scheduler.initialize();
    expect(fake.initializeCalls, 1);
  });
}

String _body(String name) => 'body:$name';
