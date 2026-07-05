import '../../../domain/enums/finance_enums.dart';
import '../../../domain/models/goal.dart';
import '../../../domain/models/money.dart';

/// Translates between the Supabase `goals` row shape (snake_case, amounts as
/// numeric major values) and the domain [Goal].
///
/// This is the only place that knows the table's column names, keeping the
/// domain backend-agnostic (quality rule #7). `GoalStatus.name` deliberately
/// matches the DB string values (see the migration's CHECK constraint).
abstract final class GoalMapper {
  GoalMapper._();

  static Map<String, dynamic> toInsert(Goal goal) => {
    'household_id': goal.householdId,
    'name': goal.name,
    'target_amount': goal.target.major,
    'currency': goal.target.currency,
    'deadline': _dateOnly(goal.deadline),
  };

  static Map<String, dynamic> toUpdate(Goal goal) => {
    'name': goal.name,
    'target_amount': goal.target.major,
    'currency': goal.target.currency,
    'deadline': _dateOnly(goal.deadline),
  };

  static Goal fromRow(Map<String, dynamic> row) {
    final currency = (row['currency'] as String?) ?? 'USD';
    final target = (row['target_amount'] as num).toDouble();
    final saved = (row['saved_amount'] as num?)?.toDouble() ?? 0;
    return Goal(
      id: row['id'] as String,
      householdId: row['household_id'] as String,
      name: row['name'] as String,
      target: Money.fromMajor(target, currency: currency),
      saved: Money.fromMajor(saved, currency: currency),
      status: _enumByName(GoalStatus.values, row['status'], GoalStatus.active),
      deadline: _parseDate(row['deadline']),
      createdAt: _parseDate(row['created_at']),
      updatedAt: _parseDate(row['updated_at']),
    );
  }

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

  static String? _dateOnly(DateTime? value) =>
      value?.toIso8601String().split('T').first;
}
