import '../../../domain/enums/finance_enums.dart';
import '../../../domain/models/financial_account.dart';
import '../../../domain/models/money.dart';

abstract final class AccountMapper {
  static FinancialAccount fromRow(Map<String, dynamic> row) {
    final currency = row['currency'] as String;
    return FinancialAccount(
      id: row['id'] as String,
      householdId: row['household_id'] as String,
      name: row['name'] as String,
      currency: currency,
      openingBalance: Money.fromMajor(
        row['opening_balance'] as num,
        currency: currency,
      ),
      openingBalanceAt: DateTime.parse(row['opening_balance_at'] as String),
      kind: _kind(row['kind']),
      balanceNature: row['balance_nature'] == 'liability'
          ? BalanceNature.liability
          : BalanceNature.asset,
      iconName: (row['icon_name'] as String?) ?? 'bank',
      colorHex: row['color_hex'] as String?,
      isDefault: (row['is_default'] as bool?) ?? false,
      isArchived: (row['is_archived'] as bool?) ?? false,
      createdAt: _date(row['created_at']),
      updatedAt: _date(row['updated_at']),
    );
  }

  static Map<String, dynamic> toRow(FinancialAccount account) => {
    'household_id': account.householdId,
    'name': account.name.trim(),
    'currency': account.currency,
    'kind': _kindName(account.kind),
    'balance_nature': account.balanceNature.name,
    'opening_balance': account.openingBalance.major,
    'opening_balance_at': account.openingBalanceAt.toUtc().toIso8601String(),
    'icon_name': account.iconName,
    'color_hex': account.colorHex,
    'is_default': account.isDefault,
    'is_archived': account.isArchived,
  };

  static AccountKind _kind(Object? raw) => AccountKind.values.firstWhere(
    (value) => _kindName(value) == raw,
    orElse: () => AccountKind.other,
  );

  static String _kindName(AccountKind kind) => switch (kind) {
    AccountKind.creditCard => 'credit_card',
    _ => kind.name,
  };

  static DateTime? _date(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;
}
