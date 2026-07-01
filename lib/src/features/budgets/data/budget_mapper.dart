import '../../../domain/models/budget.dart';
import '../../../domain/models/money.dart';

/// Translates between the Supabase `budgets` row shape (snake_case, amounts as
/// numeric major values) and the domain [Budget].
///
/// This is the only place that knows the table's column names, keeping the
/// domain backend-agnostic (quality rule #7). `spent` is read as the
/// denormalized column for now (see [Budget.spent]); recomputing it server-side
/// is a separate task.
abstract final class BudgetMapper {
  BudgetMapper._();

  static Budget fromRow(Map<String, dynamic> row) {
    final currency = (row['currency'] as String?) ?? 'USD';
    final limit = (row['amount_limit'] as num).toDouble();
    final spent = (row['spent'] as num?)?.toDouble() ?? 0;
    return Budget(
      id: row['id'] as String,
      householdId: row['household_id'] as String,
      categoryId: row['category_id'] as String,
      limit: Money.fromMajor(limit, currency: currency),
      spent: Money.fromMajor(spent, currency: currency),
      periodStart: DateTime.parse(row['period_start'] as String),
      createdAt: _parseDate(row['created_at']),
      updatedAt: _parseDate(row['updated_at']),
    );
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
