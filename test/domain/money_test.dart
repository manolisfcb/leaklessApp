import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/models/money.dart';

void main() {
  group('Money', () {
    test('fromMajor converts to minor units', () {
      expect(Money.fromMajor(10.99).minorUnits, 1099);
      expect(Money.fromMajor(0).minorUnits, 0);
      // Zero-decimal currency keeps the value as-is.
      expect(Money.fromMajor(1500, currency: 'JPY').minorUnits, 1500);
    });

    test('major returns the decimal value', () {
      expect(const Money(minorUnits: 1099).major, closeTo(10.99, 1e-9));
    });

    test('addition and subtraction keep the currency', () {
      const a = Money(minorUnits: 500);
      const b = Money(minorUnits: 250);
      expect((a + b).minorUnits, 750);
      expect((a - b).minorUnits, 250);
      expect((a + b).currency, 'USD');
    });

    test('sign helpers', () {
      expect(const Money(minorUnits: -100).isNegative, isTrue);
      expect(const Money(minorUnits: 100).isPositive, isTrue);
      expect(Money.zero.isZero, isTrue);
      expect(const Money(minorUnits: -100).absolute.minorUnits, 100);
    });

    test('format renders a currency string', () {
      expect(const Money(minorUnits: 1099).format(), contains('10.99'));
    });

    test('equality follows value semantics (freezed)', () {
      expect(
        const Money(minorUnits: 100),
        equals(const Money(minorUnits: 100)),
      );
      expect(
        const Money(minorUnits: 100),
        isNot(const Money(minorUnits: 100, currency: 'EUR')),
      );
    });
  });
}
