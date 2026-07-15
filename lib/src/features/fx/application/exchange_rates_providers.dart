import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../domain/models/fx_rate.dart';
import '../../../domain/services/currency_converter.dart';
import '../data/exchange_rates_repository.dart';

final currencyConverterProvider = Provider((_) => const CurrencyConverter());

final exchangeRatesRepositoryProvider = Provider<ExchangeRatesRepository>((
  ref,
) {
  if (ref.watch(supabaseEnabledProvider)) {
    return SupabaseExchangeRatesRepository(ref.watch(supabaseClientProvider));
  }
  return MockExchangeRatesRepository();
});

final latestUsdCadRateProvider = FutureProvider<FxRate?>(
  (ref) => ref
      .watch(exchangeRatesRepositoryProvider)
      .latest(foreignCurrency: 'USD', reportingCurrency: 'CAD'),
);
