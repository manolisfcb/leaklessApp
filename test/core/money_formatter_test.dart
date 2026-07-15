import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/core/utils/money_formatter.dart';

void main() {
  group('MoneyFormatter', () {
    test('decimalDigitsFor handles zero-decimal currencies', () {
      expect(MoneyFormatter.decimalDigitsFor('USD'), 2);
      expect(MoneyFormatter.decimalDigitsFor('EUR'), 2);
      expect(MoneyFormatter.decimalDigitsFor('JPY'), 0);
      expect(MoneyFormatter.decimalDigitsFor('clp'), 0); // case-insensitive
    });

    test('toMajor divides by the right factor', () {
      expect(MoneyFormatter.toMajor(123456, 'USD'), closeTo(1234.56, 1e-9));
      expect(MoneyFormatter.toMajor(1500, 'JPY'), 1500);
    });

    test('format includes the amount digits', () {
      final formatted = MoneyFormatter.format(123456);
      expect(formatted, contains('234.56'));
    });

    test('format without symbol drops the currency symbol', () {
      final formatted = MoneyFormatter.format(1099, showSymbol: false).trim();
      expect(formatted, isNot(contains(r'$')));
      expect(formatted, contains('10.99'));
    });
  });
}
