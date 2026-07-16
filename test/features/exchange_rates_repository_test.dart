import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leakless/src/features/fx/data/exchange_rates_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'falls back to Bank of Canada when the Supabase cache is empty',
    () async {
      final client = MockClient((request) async {
        if (request.url.host == 'example.supabase.co') {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        expect(request.url.host, 'www.bankofcanada.ca');
        expect(request.url.queryParameters['end_date'], '2026-07-15');
        return http.Response(
          '''{
          "observations": [
            {"d":"2026-07-14","FXUSDCAD":{"v":"1.4067"}},
            {"d":"2026-07-15","FXUSDCAD":{"v":"1.4049"}}
          ]
        }''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final supabase = SupabaseClient(
        'https://example.supabase.co',
        'test-publishable-key',
        httpClient: client,
      );
      addTearDown(supabase.dispose);
      final repository = SupabaseExchangeRatesRepository(
        supabase,
        httpClient: client,
      );

      final rate = await repository.resolve(
        foreignCurrency: 'USD',
        reportingCurrency: 'CAD',
        onOrBefore: DateTime(2026, 7, 15),
      );

      expect(rate, isNotNull);
      expect(rate!.decimalValue, '1.4049');
      expect(rate.rateDate, DateTime(2026, 7, 15));
      expect(rate.source, 'bank_of_canada_direct_fallback');
    },
  );
}
