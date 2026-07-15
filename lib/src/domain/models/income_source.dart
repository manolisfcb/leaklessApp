import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/finance_enums.dart';

part 'income_source.freezed.dart';
part 'income_source.g.dart';

@freezed
abstract class IncomeSource with _$IncomeSource {
  const factory IncomeSource({
    required String id,
    required String householdId,
    required String name,
    required String defaultCurrency,
    @Default(IncomeSourceType.other) IncomeSourceType type,
    String? defaultAccountId,
    @Default('briefcase') String iconName,
    String? colorHex,
    @Default(false) bool isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _IncomeSource;

  factory IncomeSource.fromJson(Map<String, dynamic> json) =>
      _$IncomeSourceFromJson(json);
}
