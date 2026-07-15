import '../../../domain/enums/finance_enums.dart';
import '../../../domain/models/income_source.dart';

abstract final class IncomeSourceMapper {
  static IncomeSource fromRow(Map<String, dynamic> row) => IncomeSource(
    id: row['id'] as String,
    householdId: row['household_id'] as String,
    name: row['name'] as String,
    defaultCurrency: row['default_currency'] as String,
    type: IncomeSourceType.values.firstWhere(
      (value) => value.name == row['type'],
      orElse: () => IncomeSourceType.other,
    ),
    defaultAccountId: row['default_account_id'] as String?,
    iconName: (row['icon_name'] as String?) ?? 'briefcase',
    colorHex: row['color_hex'] as String?,
    isArchived: (row['is_archived'] as bool?) ?? false,
    createdAt: _date(row['created_at']),
    updatedAt: _date(row['updated_at']),
  );

  static Map<String, dynamic> toRow(IncomeSource source) => {
    'household_id': source.householdId,
    'name': source.name.trim(),
    'type': source.type.name,
    'default_currency': source.defaultCurrency,
    'default_account_id': source.defaultAccountId,
    'icon_name': source.iconName,
    'color_hex': source.colorHex,
    'is_archived': source.isArchived,
  };

  static DateTime? _date(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;
}
