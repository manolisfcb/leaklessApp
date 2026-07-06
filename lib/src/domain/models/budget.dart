import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/finance_enums.dart';
import 'money.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

/// A monthly spending limit for a category within a household.
///
/// [spent] is denormalized for fast dashboard reads; the source of truth is the
/// sum of the period's transactions, recomputed server-side.
///
/// [alertThresholdPct] is the *spent* percentage that fires an alert
/// (80 = alert at 80% consumed); the UI presents it as remaining
/// (100 − threshold).
@freezed
abstract class Budget with _$Budget {
  const factory Budget({
    required String id,
    required String householdId,
    required String categoryId,
    required Money limit,
    @Default(Money.zero) Money spent,
    required DateTime periodStart,
    @Default(true) bool alertEnabled,
    @Default(80) int alertThresholdPct,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Budget;
  const Budget._();

  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);

  /// Spent / limit, clamped at 0 (returns 0 when there is no limit).
  double get ratio {
    if (limit.minorUnits <= 0) return 0;
    return spent.minorUnits / limit.minorUnits;
  }

  /// Percentage 0..100+ for display.
  double get percent => ratio * 100;

  BudgetStatus get status => BudgetStatus.fromRatio(ratio);

  Money get remaining =>
      limit.copyWith(minorUnits: limit.minorUnits - spent.minorUnits);
}
