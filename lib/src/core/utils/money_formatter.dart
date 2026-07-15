import 'package:intl/intl.dart';

/// Formats monetary amounts stored as **minor units** (e.g. cents) into
/// localized, human-readable strings.
///
/// Storing money as integer minor units avoids floating-point rounding errors;
/// this is the single place that turns them back into display text
/// (quality rule #1: no duplicated formatting logic).
abstract final class MoneyFormatter {
  MoneyFormatter._();

  /// Number of decimal digits for [currencyCode] (defaults to 2).
  ///
  /// A handful of common zero-decimal currencies are special-cased; everything
  /// else falls back to 2, which is correct for the vast majority.
  static int decimalDigitsFor(String currencyCode) {
    const zeroDecimal = {'JPY', 'KRW', 'CLP', 'VND', 'ISK', 'PYG', 'XOF'};
    return zeroDecimal.contains(currencyCode.toUpperCase()) ? 0 : 2;
  }

  /// Converts [minorUnits] into the major-unit value (e.g. 1099 → 10.99).
  static double toMajor(int minorUnits, String currencyCode) {
    final digits = decimalDigitsFor(currencyCode);
    return minorUnits / _pow10(digits);
  }

  /// Formats [minorUnits] as a currency string, e.g. `$1,099.50`.
  ///
  /// [locale] controls grouping/decimal separators and symbol placement.
  /// When [showSymbol] is false only the number is rendered.
  static String format(
    int minorUnits, {
    String currencyCode = 'USD',
    String? locale,
    bool showSymbol = true,
  }) {
    final digits = decimalDigitsFor(currencyCode);
    final value = minorUnits / _pow10(digits);
    final format = NumberFormat.currency(
      locale: locale,
      name: currencyCode,
      symbol: showSymbol ? _symbolFor(currencyCode, locale) : '',
      decimalDigits: digits,
    );
    return format.format(value).trim();
  }

  /// A compact form for tight UI, e.g. `$1.1K`, `$2.4M`.
  static String formatCompact(
    int minorUnits, {
    String currencyCode = 'USD',
    String? locale,
  }) {
    final value = toMajor(minorUnits, currencyCode);
    final format = NumberFormat.compactCurrency(
      locale: locale,
      name: currencyCode,
      symbol: _symbolFor(currencyCode, locale),
    );
    return format.format(value).trim();
  }

  static String _symbolFor(String currencyCode, String? locale) =>
      NumberFormat.simpleCurrency(
        locale: locale,
        name: currencyCode,
      ).currencySymbol;

  static num _pow10(int digits) {
    var result = 1;
    for (var i = 0; i < digits; i++) {
      result *= 10;
    }
    return result;
  }
}
