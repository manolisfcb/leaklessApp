import '../../../domain/enums/transaction_enums.dart';
import '../../../domain/models/money.dart';
import '../../../domain/models/transaction.dart';

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
      type: _enumByName(TransactionType.values, row['type'], TransactionType.expense),
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
      categoryId: row['category_id'] as String?,
      responsibleMemberId: row['responsible_member_id'] as String?,
      description: row['description'] as String?,
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
    'category_id': tx.categoryId,
    'responsible_member_id': tx.responsibleMemberId,
    'description': tx.description,
    'occurred_at': tx.occurredAt.toIso8601String(),
  };

  static T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
    final name = raw as String?;
    return values.firstWhere((e) => e.name == name, orElse: () => fallback);
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
