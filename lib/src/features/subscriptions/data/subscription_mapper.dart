import '../../../domain/enums/finance_enums.dart';
import '../../../domain/models/money.dart';
import '../../../domain/models/subscription_item.dart';

/// Translates between the Supabase `subscriptions` row shape (snake_case, amount
/// as a numeric major value) and the domain [SubscriptionItem].
///
/// This is the only place that knows the table's column names, keeping the
/// domain backend-agnostic (quality rule #7). `SubscriptionStatus.name`
/// deliberately matches the DB string values (see the migration's CHECK).
abstract final class SubscriptionMapper {
  SubscriptionMapper._();

  static SubscriptionItem fromRow(Map<String, dynamic> row) {
    final currency = (row['currency'] as String?) ?? 'USD';
    final amount = (row['amount'] as num).toDouble();
    return SubscriptionItem(
      id: row['id'] as String,
      householdId: row['household_id'] as String,
      name: row['name'] as String,
      amount: Money.fromMajor(amount, currency: currency),
      status: _enumByName(
        SubscriptionStatus.values,
        row['status'],
        SubscriptionStatus.active,
      ),
      nextChargeAt: _parseDate(row['next_charge_at']),
      categoryId: row['category_id'] as String?,
      createdAt: _parseDate(row['created_at']),
      updatedAt: _parseDate(row['updated_at']),
    );
  }

  static T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
    final name = raw as String?;
    return values.firstWhere((e) => e.name == name, orElse: () => fallback);
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
