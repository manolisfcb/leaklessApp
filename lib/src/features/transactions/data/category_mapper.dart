import '../../../domain/models/transaction_category.dart';

/// Translates the Supabase `categories` row shape (snake_case) into the domain
/// [TransactionCategory].
///
/// This is the only place that knows the table's column names, keeping the
/// domain backend-agnostic (quality rule #7).
abstract final class CategoryMapper {
  CategoryMapper._();

  static TransactionCategory fromRow(Map<String, dynamic> row) =>
      TransactionCategory(
        id: row['id'] as String,
        name: row['name'] as String,
        iconName: (row['icon_name'] as String?) ?? 'cart',
        householdId: row['household_id'] as String?,
        colorHex: row['color_hex'] as String?,
        isDefault: (row['is_default'] as bool?) ?? false,
        createdAt: _parseDate(row['created_at']),
      );

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
