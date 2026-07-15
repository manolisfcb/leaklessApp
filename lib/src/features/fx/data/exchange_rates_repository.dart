import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/models/fx_rate.dart';

abstract interface class ExchangeRatesRepository {
  Future<FxRate?> resolve({
    required String foreignCurrency,
    required String reportingCurrency,
    required DateTime onOrBefore,
  });
  Future<FxRate?> latest({
    required String foreignCurrency,
    required String reportingCurrency,
  });
}

class MockExchangeRatesRepository implements ExchangeRatesRepository {
  FxRate get _usdCad => FxRate.fromDecimalString(
    rateDate: DateTime.now(),
    foreignCurrency: 'USD',
    reportingCurrency: 'CAD',
    rate: '1.37',
    source: 'bank_of_canada',
    retrievedAt: DateTime.now(),
  );

  @override
  Future<FxRate?> latest({
    required String foreignCurrency,
    required String reportingCurrency,
  }) async =>
      foreignCurrency == 'USD' && reportingCurrency == 'CAD' ? _usdCad : null;

  @override
  Future<FxRate?> resolve({
    required String foreignCurrency,
    required String reportingCurrency,
    required DateTime onOrBefore,
  }) => latest(
    foreignCurrency: foreignCurrency,
    reportingCurrency: reportingCurrency,
  );
}

class SupabaseExchangeRatesRepository implements ExchangeRatesRepository {
  SupabaseExchangeRatesRepository(this.client);
  final SupabaseClient client;

  @override
  Future<FxRate?> latest({
    required String foreignCurrency,
    required String reportingCurrency,
  }) => _query(foreignCurrency, reportingCurrency, null);

  @override
  Future<FxRate?> resolve({
    required String foreignCurrency,
    required String reportingCurrency,
    required DateTime onOrBefore,
  }) => _query(foreignCurrency, reportingCurrency, _dateOnly(onOrBefore));

  Future<FxRate?> _query(
    String foreign,
    String reporting,
    String? maximumDate,
  ) async {
    var query = client
        .from('exchange_rates')
        .select()
        .eq('foreign_currency', foreign)
        .eq('reporting_currency', reporting);
    if (maximumDate != null) query = query.lte('rate_date', maximumDate);
    final rows = await query.order('rate_date', ascending: false).limit(1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return FxRate.fromDecimalString(
      rateDate: DateTime.parse(row['rate_date'] as String),
      foreignCurrency: row['foreign_currency'] as String,
      reportingCurrency: row['reporting_currency'] as String,
      rate: row['rate'].toString(),
      source: row['source'] as String,
      retrievedAt: DateTime.parse(row['retrieved_at'] as String),
      rawObservationDate: DateTime.parse(row['raw_observation_date'] as String),
    );
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
