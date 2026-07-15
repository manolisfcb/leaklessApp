import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/models/fx_rate.dart';
import 'package:leakless/src/domain/models/money.dart';
import 'package:leakless/src/domain/services/currency_converter.dart';

void main() {
  final rate = FxRate.fromDecimalString(
    rateDate: DateTime(2026, 7, 15),
    foreignCurrency: 'USD',
    reportingCurrency: 'CAD',
    rate: '1.37',
    source: 'bank_of_canada',
    retrievedAt: DateTime(2026, 7, 15, 17),
  );
  const converter = CurrencyConverter();

  test('converts USD to CAD without floating point persistence', () {
    final result = converter.convert(
      const Money(minorUnits: 90000, currency: 'USD'),
      'CAD',
      rate: rate,
    );
    expect(result, const Money(minorUnits: 123300, currency: 'CAD'));
  });

  test('converts CAD to USD using the inverse rate', () {
    final result = converter.convert(
      const Money(minorUnits: 13700, currency: 'CAD'),
      'USD',
      rate: rate,
    );
    expect(result, const Money(minorUnits: 10000, currency: 'USD'));
  });

  test('same currency is an identity conversion', () {
    final result = converter.convert(
      const Money(minorUnits: 123, currency: 'CAD'),
      'CAD',
    );
    expect(result, const Money(minorUnits: 123, currency: 'CAD'));
  });

  test('rounds a zero-decimal target currency', () {
    final jpyRate = FxRate.fromDecimalString(
      rateDate: DateTime(2026, 7, 15),
      foreignCurrency: 'CAD',
      reportingCurrency: 'JPY',
      rate: '110.5',
      source: 'test',
      retrievedAt: DateTime(2026, 7, 15),
    );
    final result = converter.convert(
      const Money(minorUnits: 101, currency: 'CAD'),
      'JPY',
      rate: jpyRate,
    );
    expect(result.minorUnits, 112);
  });
}
