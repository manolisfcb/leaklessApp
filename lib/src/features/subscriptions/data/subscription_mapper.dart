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
      frequency: _enumByName(
        SubscriptionFrequency.values,
        row['frequency'],
        SubscriptionFrequency.monthly,
      ),
      nextChargeAt: _parseDate(row['next_charge_at']),
      categoryId: row['category_id'] as String?,
      accountId: row['account_id'] as String?,
      estimatedReportingAmount: _moneyOrNull(
        row['estimated_reporting_amount'],
        row['reporting_currency'] as String?,
      ),
      exchangeRateDate: _parseDate(row['exchange_rate_date']),
      reminderEnabled: (row['reminder_enabled'] as bool?) ?? false,
      reminderDaysBefore: (row['reminder_days_before'] as num?)?.toInt() ?? 1,
      createdAt: _parseDate(row['created_at']),
      updatedAt: _parseDate(row['updated_at']),
    );
  }

  static Map<String, dynamic> toInsert(SubscriptionItem item) => {
    'household_id': item.householdId,
    ...toUpdate(item),
  };

  static Map<String, dynamic> toUpdate(SubscriptionItem item) => {
    'name': item.name,
    'amount': item.amount.major,
    'currency': item.amount.currency,
    'status': item.status.name,
    'frequency': item.frequency.name,
    'next_charge_at': item.nextChargeAt?.toUtc().toIso8601String(),
    'category_id': item.categoryId,
    'account_id': item.accountId,
    'estimated_reporting_amount': item.estimatedReportingAmount?.major,
    'reporting_currency': item.estimatedReportingAmount?.currency,
    'exchange_rate_date': item.exchangeRateDate?.toIso8601String().split('T').first,
    'reminder_enabled': item.reminderEnabled,
    'reminder_days_before': item.reminderDaysBefore,
  };

  static T _enumByName<T extends Enum>(
    List<T> values,
    Object? raw,
    T fallback,
  ) {
    final name = raw as String?;
    return values.firstWhere((e) => e.name == name, orElse: () => fallback);
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static Money? _moneyOrNull(Object? raw, String? currency) {
    if (raw == null || currency == null) return null;
    final value = raw is num ? raw : num.tryParse(raw.toString());
    return value == null ? null : Money.fromMajor(value, currency: currency);
  }
}
