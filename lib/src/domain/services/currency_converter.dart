import '../models/fx_rate.dart';
import '../models/money.dart';

class CurrencyConverter {
  const CurrencyConverter();

  Money convert(Money amount, String targetCurrency, {FxRate? rate}) {
    if (amount.currency == targetCurrency) {
      return amount.copyWith(currency: targetCurrency);
    }
    if (rate == null) throw StateError('fx_rate_required');

    final isForward =
        amount.currency == rate.foreignCurrency &&
        targetCurrency == rate.reportingCurrency;
    final isInverse =
        amount.currency == rate.reportingCurrency &&
        targetCurrency == rate.foreignCurrency;
    if (!isForward && !isInverse) throw StateError('fx_rate_pair_mismatch');

    final sourceFactor = _factor(amount.currency);
    final targetFactor = _factor(targetCurrency);
    final sourceMinor = BigInt.from(amount.minorUnits);
    final scale = BigInt.from(FxRate.scale);
    final scaledRate = BigInt.from(rate.scaledRate);
    final numerator = isForward
        ? sourceMinor * BigInt.from(targetFactor) * scaledRate
        : sourceMinor * BigInt.from(targetFactor) * scale;
    final denominator = isForward
        ? BigInt.from(sourceFactor) * scale
        : BigInt.from(sourceFactor) * scaledRate;
    final rounded = _roundHalfAwayFromZero(numerator, denominator);
    return Money(minorUnits: rounded.toInt(), currency: targetCurrency);
  }

  BigInt _roundHalfAwayFromZero(BigInt numerator, BigInt denominator) {
    final negative = numerator.isNegative;
    final absolute = numerator.abs();
    final quotient = absolute ~/ denominator;
    final remainder = absolute.remainder(denominator);
    final rounded = remainder * BigInt.two >= denominator
        ? quotient + BigInt.one
        : quotient;
    return negative ? -rounded : rounded;
  }

  int _factor(String currency) {
    const zeroDecimal = {
      'BIF',
      'CLP',
      'DJF',
      'GNF',
      'ISK',
      'JPY',
      'KRW',
      'PYG',
      'RWF',
      'UGX',
      'VND',
      'VUV',
      'XAF',
      'XOF',
      'XPF',
    };
    const threeDecimal = {'BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND'};
    if (zeroDecimal.contains(currency)) return 1;
    if (threeDecimal.contains(currency)) return 1000;
    return 100;
  }
}
