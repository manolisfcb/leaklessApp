import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/transaction_enums.dart';
import 'money.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

/// A single financial movement registered in a household.
@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String householdId,
    required Money amount,
    required TransactionType type,
    required TransactionPriority priority,
    required ResponsibleType responsible,
    required DateTime occurredAt,
    @Default(TransactionSource.manual) TransactionSource source,
    @Default(TransactionStatus.confirmed) TransactionStatus status,
    String? externalId,
    String? accountId,
    String? incomeSourceId,
    String? categoryId,
    String? responsibleMemberId,
    String? description,
    Money? reportingAmount,
    int? exchangeRateScaled,
    DateTime? exchangeRateDate,
    String? exchangeRateSource,
    @Default(false) bool exchangeRateEstimated,
    String? transferGroupId,
    TransferDirection? transferDirection,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Transaction;
  const Transaction._();

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
  bool get isTransfer => type == TransactionType.transfer;

  /// "Ant" expenses (gastos hormiga) are the micro-leaks leakless hunts for.
  bool get isAntLeak =>
      type == TransactionType.expense && priority == TransactionPriority.ant;

  /// Signed amount: expenses are negative, income positive.
  Money get signedAmount => isExpense
      ? amount.absolute.copyWith(minorUnits: -amount.absolute.minorUnits)
      : amount.absolute;
}
