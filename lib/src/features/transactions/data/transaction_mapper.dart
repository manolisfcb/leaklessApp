import '../../../domain/enums/transaction_enums.dart';
import '../../../domain/models/money.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/fx_rate.dart';

/// Translates between the Supabase `transactions` row shape (snake_case, amount
/// as a numeric major value) and the domain [Transaction].
///
/// This is the only place that knows the table's column names, keeping the
/// domain backend-agnostic (quality rule #7). Enum `.name`s deliberately match
/// the DB string values (see the migration).
abstract final class TransactionMapper {
  TransactionMapper._();

  static Transaction fromRow(Map<String, dynamic> row) {
    final currency = (row['currency'] as String?) ?? 'USD';
    final amount = (row['amount'] as num).toDouble();
    return Transaction(
      id: row['id'] as String,
      householdId: row['household_id'] as String,
      amount: Money.fromMajor(amount, currency: currency),
      type: _enumByName(
        TransactionType.values,
        row['type'],
        TransactionType.expense,
      ),
      priority: _enumByName(
        TransactionPriority.values,
        row['priority'],
        TransactionPriority.necessity,
      ),
      responsible: _enumByName(
        ResponsibleType.values,
        row['responsible_type'],
        ResponsibleType.shared,
      ),
      source: _enumByName(
        TransactionSource.values,
        row['source'],
        TransactionSource.manual,
      ),
      status: _enumByName(
        TransactionStatus.values,
        row['status'],
        TransactionStatus.confirmed,
      ),
      externalId: row['external_id'] as String?,
      accountId: row['account_id'] as String?,
      incomeSourceId: row['income_source_id'] as String?,
      categoryId: row['category_id'] as String?,
      responsibleMemberId: row['responsible_member_id'] as String?,
      description: row['description'] as String?,
      reportingAmount: _moneyOrNull(
        row['amount_reporting'],
        row['reporting_currency'] as String?,
      ),
      exchangeRateScaled: _scaledRate(row['exchange_rate_to_reporting']),
      exchangeRateDate: _parseDate(row['exchange_rate_date']),
      exchangeRateSource: row['exchange_rate_source'] as String?,
      exchangeRateEstimated:
          (row['exchange_rate_source'] as String?)?.contains('fallback') ??
          false,
      transferGroupId: row['transfer_group_id'] as String?,
      transferDirection: _nullableEnumByName(
        TransferDirection.values,
        row['transfer_direction'],
      ),
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      createdAt: _parseDate(row['created_at']),
      updatedAt: _parseDate(row['updated_at']),
    );
  }

  /// Row for an insert. `id`/timestamps are left to the DB defaults.
  static Map<String, dynamic> toInsert(Transaction tx) => {
    'household_id': tx.householdId,
    'amount': tx.amount.major,
    'currency': tx.amount.currency,
    'type': tx.type.name,
    'priority': tx.priority.name,
    'responsible_type': tx.responsible.name,
    'source': tx.source.name,
    'status': tx.status.name,
    // external_id stays null for manual entries; the aggregator sync sets it.
    if (tx.externalId != null) 'external_id': tx.externalId,
    if (tx.accountId != null) 'account_id': tx.accountId,
    if (tx.incomeSourceId != null) 'income_source_id': tx.incomeSourceId,
    'category_id': tx.categoryId,
    'responsible_member_id': tx.responsibleMemberId,
    'description': tx.description,
    'occurred_at': tx.occurredAt.toIso8601String(),
    if (tx.reportingAmount != null) ...{
      'reporting_currency': tx.reportingAmount!.currency,
      'amount_reporting': tx.reportingAmount!.major,
    },
    if (tx.exchangeRateScaled != null)
      'exchange_rate_to_reporting': tx.exchangeRateScaled! / FxRate.scale,
    if (tx.exchangeRateDate != null)
      'exchange_rate_date': _dateOnly(tx.exchangeRateDate!),
    if (tx.exchangeRateSource != null)
      'exchange_rate_source': tx.exchangeRateSource,
    if (tx.transferGroupId != null) 'transfer_group_id': tx.transferGroupId,
    if (tx.transferDirection != null)
      'transfer_direction': tx.transferDirection!.name,
  };

  static Money? _moneyOrNull(Object? raw, String? currency) {
    if (raw == null || currency == null) return null;
    final value = raw is num ? raw : num.tryParse(raw.toString());
    return value == null ? null : Money.fromMajor(value, currency: currency);
  }

  static int? _scaledRate(Object? raw) {
    if (raw == null) return null;
    final value = raw.toString();
    try {
      return FxRate.fromDecimalString(
        rateDate: DateTime(2000),
        foreignCurrency: 'USD',
        reportingCurrency: 'CAD',
        rate: value,
        source: 'mapper',
        retrievedAt: DateTime(2000),
      ).scaledRate;
    } on FormatException {
      return null;
    }
  }

  static T? _nullableEnumByName<T extends Enum>(List<T> values, Object? raw) {
    final name = raw as String?;
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

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
}
