import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/utils/money_formatter.dart';

part 'money.freezed.dart';
part 'money.g.dart';

/// An immutable money value object stored as integer **minor units** (cents)
/// plus an ISO currency code.
///
/// Domain models never touch floating-point money directly — they hold [Money],
/// which centralizes arithmetic and formatting and keeps rounding correct
/// (quality rule #1/#7: domain stays independent of any backend).
@freezed
abstract class Money with _$Money {
  const factory Money({
    required int minorUnits,
    @Default('USD') String currency,
  }) = _Money;
  const Money._();

  factory Money.fromJson(Map<String, dynamic> json) => _$MoneyFromJson(json);

  /// Builds [Money] from a major-unit value (e.g. `10.99` → 1099 cents).
  factory Money.fromMajor(num major, {String currency = 'USD'}) {
    final factor = _factor(currency);
    return Money(minorUnits: (major * factor).round(), currency: currency);
  }

  /// A zero amount in the default currency.
  static const Money zero = Money(minorUnits: 0);

  /// The value in major units (e.g. dollars).
  double get major => MoneyFormatter.toMajor(minorUnits, currency);

  bool get isZero => minorUnits == 0;
  bool get isNegative => minorUnits < 0;
  bool get isPositive => minorUnits > 0;

  Money get absolute => copyWith(minorUnits: minorUnits.abs());

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return copyWith(minorUnits: minorUnits + other.minorUnits);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return copyWith(minorUnits: minorUnits - other.minorUnits);
  }

  /// Localized currency string, e.g. `$1,099.50`.
  String format({String? locale, bool showSymbol = true}) =>
      MoneyFormatter.format(
        minorUnits,
        currencyCode: currency,
        locale: locale,
        showSymbol: showSymbol,
      );

  /// Compact form for tight spaces, e.g. `$1.1K`.
  String formatCompact({String? locale}) => MoneyFormatter.formatCompact(
    minorUnits,
    currencyCode: currency,
    locale: locale,
  );

  void _assertSameCurrency(Money other) {
    assert(
      currency == other.currency,
      'Cannot operate on Money with different currencies '
      '($currency vs ${other.currency}).',
    );
  }

  static num _factor(String currency) {
    final digits = MoneyFormatter.decimalDigitsFor(currency);
    var result = 1;
    for (var i = 0; i < digits; i++) {
      result *= 10;
    }
    return result;
  }
}
