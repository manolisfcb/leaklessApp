import 'package:json_annotation/json_annotation.dart';

/// Budget consumption state. Derived from spent/limit ratio but stored/typed so
/// the UI (tube color, alert borders) maps directly.
enum BudgetStatus {
  @JsonValue('normal')
  normal,
  @JsonValue('warning')
  warning, // >= 75%
  @JsonValue('exceeded')
  exceeded; // >= 100%

  /// Maps a spent/limit [ratio] to its status (75% / 100% thresholds).
  static BudgetStatus fromRatio(double ratio) {
    if (ratio >= 1.0) return BudgetStatus.exceeded;
    if (ratio >= 0.75) return BudgetStatus.warning;
    return BudgetStatus.normal;
  }
}

/// Lifecycle of a savings goal.
enum GoalStatus {
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('paused')
  paused,
  @JsonValue('archived')
  archived;
}

/// How often a recurring subscription is charged. Drives the next-charge date
/// math for local reminders (see [nextChargeAfter]).
enum SubscriptionFrequency {
  @JsonValue('weekly')
  weekly,
  @JsonValue('monthly')
  monthly,
  @JsonValue('yearly')
  yearly;

  /// The charge date immediately following [from] for this frequency.
  ///
  /// Monthly/yearly clamp the day to the target month's last day, so a charge
  /// on the 31st advances to Feb 28/29, and a Feb 29 yearly charge lands on
  /// Feb 28 in non-leap years. The time-of-day is preserved for weekly and
  /// carried through by [_addMonths] for the others.
  DateTime nextChargeAfter(DateTime from) => switch (this) {
    SubscriptionFrequency.weekly => from.add(const Duration(days: 7)),
    SubscriptionFrequency.monthly => _addMonths(from, 1),
    SubscriptionFrequency.yearly => _addMonths(from, 12),
  };
}

/// Adds [months] calendar months to [date], clamping the day of month to the
/// target month's length (e.g. Jan 31 + 1 month → Feb 28/29).
DateTime _addMonths(DateTime date, int months) {
  final zeroBased = date.month - 1 + months;
  final year = date.year + (zeroBased ~/ 12);
  final month = (zeroBased % 12) + 1;
  // Day 0 of the following month resolves to the target month's last day.
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = date.day < lastDay ? date.day : lastDay;
  return DateTime(
    year,
    month,
    day,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
    date.microsecond,
  );
}

/// State of a detected recurring subscription.
enum SubscriptionStatus {
  @JsonValue('active')
  active,
  @JsonValue('trial')
  trial,
  @JsonValue('paused')
  paused,
  @JsonValue('canceled')
  canceled;
}
