import 'package:freezed_annotation/freezed_annotation.dart';

part 'fx_rate.freezed.dart';
part 'fx_rate.g.dart';

@freezed
abstract class FxRate with _$FxRate {
  const factory FxRate({
    required DateTime rateDate,
    required String foreignCurrency,
    required String reportingCurrency,
    required int scaledRate,
    required String source,
    required DateTime retrievedAt,
    required DateTime rawObservationDate,
    @Default(false) bool isEstimated,
  }) = _FxRate;
  const FxRate._();

  static const scale = 10000000000;

  factory FxRate.fromJson(Map<String, dynamic> json) => _$FxRateFromJson(json);

  factory FxRate.fromDecimalString({
    required DateTime rateDate,
    required String foreignCurrency,
    required String reportingCurrency,
    required String rate,
    required String source,
    required DateTime retrievedAt,
    DateTime? rawObservationDate,
    bool isEstimated = false,
  }) => FxRate(
    rateDate: rateDate,
    foreignCurrency: foreignCurrency,
    reportingCurrency: reportingCurrency,
    scaledRate: _parseScaled(rate),
    source: source,
    retrievedAt: retrievedAt,
    rawObservationDate: rawObservationDate ?? rateDate,
    isEstimated: isEstimated,
  );

  String get decimalValue {
    final whole = scaledRate ~/ scale;
    final fraction = (scaledRate % scale).toString().padLeft(10, '0');
    final compact = fraction.replaceFirst(RegExp(r'0+$'), '');
    return compact.isEmpty ? '$whole' : '$whole.$compact';
  }

  static int _parseScaled(String value) {
    final parts = value.trim().split('.');
    if (parts.length > 2) throw FormatException('Invalid FX rate: $value');
    final whole = int.parse(parts.first);
    final fraction = parts.length == 1
        ? '0000000000'
        : parts[1].padRight(10, '0').substring(0, 10);
    final result = whole * scale + int.parse(fraction);
    if (result <= 0) throw FormatException('FX rate must be positive.');
    return result;
  }
}
