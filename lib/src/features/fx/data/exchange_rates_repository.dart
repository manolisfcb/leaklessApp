import 'dart:convert';

import 'package:http/http.dart' as http;
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
  SupabaseExchangeRatesRepository(this.client, {http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final SupabaseClient client;
  final http.Client _httpClient;

  @override
  Future<FxRate?> latest({
    required String foreignCurrency,
    required String reportingCurrency,
  }) => _resolve(foreignCurrency, reportingCurrency, DateTime.now());

  @override
  Future<FxRate?> resolve({
    required String foreignCurrency,
    required String reportingCurrency,
    required DateTime onOrBefore,
  }) => _resolve(foreignCurrency, reportingCurrency, onOrBefore);

  Future<FxRate?> _resolve(
    String foreign,
    String reporting,
    DateTime onOrBefore,
  ) async {
    try {
      final cached = await _query(foreign, reporting, _dateOnly(onOrBefore));
      if (cached != null) return cached;
    } catch (_) {
      // The official public feed below is an availability fallback for an
      // empty/unreachable cache. Transaction writes still persist an immutable
      // reporting snapshot, so later market changes cannot rewrite history.
    }
    return _fetchBankOfCanada(foreign, reporting, onOrBefore);
  }

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

  Future<FxRate?> _fetchBankOfCanada(
    String foreign,
    String reporting,
    DateTime onOrBefore,
  ) async {
    if (foreign != 'USD' || reporting != 'CAD') return null;

    final end = DateTime(onOrBefore.year, onOrBefore.month, onOrBefore.day);
    final start = end.subtract(const Duration(days: 14));
    final uri = Uri.https(
      'www.bankofcanada.ca',
      '/valet/observations/FXUSDCAD/json',
      {'start_date': _dateOnly(start), 'end_date': _dateOnly(end)},
    );

    try {
      final response = await _httpClient
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final observations = payload['observations'];
      if (observations is! List) return null;

      for (final raw in observations.reversed) {
        if (raw is! Map<String, dynamic>) continue;
        final dateValue = raw['d'];
        final series = raw['FXUSDCAD'];
        if (dateValue is! String || series is! Map<String, dynamic>) continue;
        final rateValue = series['v']?.toString();
        if (rateValue == null || double.tryParse(rateValue) == null) continue;
        final rateDate = DateTime.tryParse(dateValue);
        if (rateDate == null || rateDate.isAfter(end)) continue;
        return FxRate.fromDecimalString(
          rateDate: rateDate,
          foreignCurrency: foreign,
          reportingCurrency: reporting,
          rate: rateValue,
          source: 'bank_of_canada_direct_fallback',
          retrievedAt: DateTime.now(),
          rawObservationDate: rateDate,
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
