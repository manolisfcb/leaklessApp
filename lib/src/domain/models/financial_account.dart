import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/finance_enums.dart';
import 'money.dart';

part 'financial_account.freezed.dart';
part 'financial_account.g.dart';

@freezed
abstract class FinancialAccount with _$FinancialAccount {
  const factory FinancialAccount({
    required String id,
    required String householdId,
    required String name,
    required String currency,
    required Money openingBalance,
    required DateTime openingBalanceAt,
    @Default(AccountKind.checking) AccountKind kind,
    @Default(BalanceNature.asset) BalanceNature balanceNature,
    @Default('bank') String iconName,
    String? colorHex,
    @Default(false) bool isDefault,
    @Default(false) bool isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _FinancialAccount;

  factory FinancialAccount.fromJson(Map<String, dynamic> json) =>
      _$FinancialAccountFromJson(json);
}
