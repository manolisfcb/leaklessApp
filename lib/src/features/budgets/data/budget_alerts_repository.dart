import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../domain/models/budget.dart';
import 'budget_mapper.dart';

/// Dedupe ledger for fired budget alerts (`budget_alert_events`).
///
/// Both the local watcher and the budget-alert Edge Function insert into the
/// same table with "ignore duplicates" semantics, so each threshold notifies
/// at most once per (budget, month) no matter how many devices/paths race.
abstract interface class BudgetAlertsRepository {
  /// Records that [thresholdPct] fired for [budget]'s month.
  ///
  /// Returns true only when this call created the event — i.e. no other
  /// device or the Edge Function recorded it first — so the caller only
  /// surfaces an alert it actually owns.
  Future<bool> tryRecordAlert({
    required Budget budget,
    required int thresholdPct,
  });
}

/// In-memory ledger with the same once-per-threshold semantics.
class MockBudgetAlertsRepository implements BudgetAlertsRepository {
  final _recorded = <String>{};

  @override
  Future<bool> tryRecordAlert({
    required Budget budget,
    required int thresholdPct,
  }) async => _recorded.add(
    '${budget.id}|'
    '${BudgetMapper.formatMonthStart(budget.periodStart)}|'
    '$thresholdPct',
  );
}

/// Supabase-backed ledger; the unique constraint on
/// (budget_id, period_start, threshold_pct) is the dedupe mechanism.
class SupabaseBudgetAlertsRepository implements BudgetAlertsRepository {
  SupabaseBudgetAlertsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<bool> tryRecordAlert({
    required Budget budget,
    required int thresholdPct,
  }) async {
    try {
      // ignoreDuplicates turns the conflicting insert into a no-op that
      // returns no rows, so a non-empty result means "we fired first".
      final rows = await _client
          .from('budget_alert_events')
          .upsert({
            'household_id': budget.householdId,
            'budget_id': budget.id,
            'period_start': BudgetMapper.formatMonthStart(budget.periodStart),
            'threshold_pct': thresholdPct,
          }, onConflict: 'budget_id,period_start,threshold_pct', ignoreDuplicates: true)
          .select('id');
      return rows.isNotEmpty;
    } catch (e, s) {
      throw ServerException(
        'Failed to record budget alert',
        cause: e,
        stackTrace: s,
      );
    }
  }
}
