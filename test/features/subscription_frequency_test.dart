import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/enums/finance_enums.dart';
import 'package:leakless/src/domain/models/money.dart';
import 'package:leakless/src/domain/models/subscription_item.dart';
import 'package:leakless/src/features/subscriptions/data/subscriptions_repository.dart';

void main() {
  group('SubscriptionFrequency.nextChargeAfter', () {
    test('weekly adds seven days', () {
      expect(
        SubscriptionFrequency.weekly.nextChargeAfter(DateTime(2026, 2, 25)),
        DateTime(2026, 3, 4),
      );
    });

    test('monthly clamps the day to the shorter target month', () {
      expect(
        SubscriptionFrequency.monthly.nextChargeAfter(DateTime(2026, 1, 31)),
        DateTime(2026, 2, 28),
      );
    });

    test('monthly lands on Feb 29 in a leap year', () {
      expect(
        SubscriptionFrequency.monthly.nextChargeAfter(DateTime(2024, 1, 31)),
        DateTime(2024, 2, 29),
      );
    });

    test('monthly rolls over the year boundary', () {
      expect(
        SubscriptionFrequency.monthly.nextChargeAfter(DateTime(2025, 12, 15)),
        DateTime(2026, 1, 15),
      );
    });

    test('yearly clamps Feb 29 to Feb 28 in a non-leap year', () {
      expect(
        SubscriptionFrequency.yearly.nextChargeAfter(DateTime(2024, 2, 29)),
        DateTime(2025, 2, 28),
      );
    });

    test('preserves the time of day', () {
      expect(
        SubscriptionFrequency.monthly.nextChargeAfter(
          DateTime(2026, 3, 10, 9, 30),
        ),
        DateTime(2026, 4, 10, 9, 30),
      );
    });
  });

  group('advanceSubscriptionCharge', () {
    SubscriptionItem sub({
      DateTime? nextChargeAt,
      SubscriptionFrequency frequency = SubscriptionFrequency.monthly,
    }) => SubscriptionItem(
      id: 'sub-1',
      householdId: 'hh',
      name: 'Rent',
      amount: const Money(minorUnits: 100000, currency: 'USD'),
      frequency: frequency,
      nextChargeAt: nextChargeAt,
    );

    test('advances a past charge to the next occurrence after now', () {
      final advanced = advanceSubscriptionCharge(
        sub(nextChargeAt: DateTime(2026, 1, 10)),
        now: DateTime(2026, 3, 15),
      );
      expect(advanced.nextChargeAt, DateTime(2026, 4, 10));
    });

    test('leaves a future charge untouched', () {
      final charge = DateTime(2026, 5, 20);
      final advanced = advanceSubscriptionCharge(
        sub(nextChargeAt: charge),
        now: DateTime(2026, 3, 15),
      );
      expect(advanced.nextChargeAt, charge);
    });

    test('returns the item unchanged when there is no charge date', () {
      final item = sub();
      expect(advanceSubscriptionCharge(item, now: DateTime(2026, 3, 15)), item);
    });

    test('advances weekly across a month boundary', () {
      final advanced = advanceSubscriptionCharge(
        sub(
          nextChargeAt: DateTime(2026, 2, 25),
          frequency: SubscriptionFrequency.weekly,
        ),
        now: DateTime(2026, 3, 10),
      );
      // Compare calendar day only: a weekly step can straddle a DST change,
      // shifting the wall-clock hour, which is irrelevant to the charge date.
      final next = advanced.nextChargeAt!;
      expect([next.year, next.month, next.day], [2026, 3, 11]);
    });
  });
}
