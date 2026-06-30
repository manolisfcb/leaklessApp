import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_category.freezed.dart';
part 'transaction_category.g.dart';

/// A spending/income category. [iconName] and [colorHex] are stored as plain
/// data so the domain stays UI-framework agnostic; presentation maps them to
/// real [IconData]/[Color] values.
@freezed
abstract class TransactionCategory with _$TransactionCategory {
  const factory TransactionCategory({
    required String id,
    required String name,
    required String iconName,
    String? householdId,
    String? colorHex,
    @Default(false) bool isDefault,
    DateTime? createdAt,
  }) = _TransactionCategory;

  factory TransactionCategory.fromJson(Map<String, dynamic> json) =>
      _$TransactionCategoryFromJson(json);
}
