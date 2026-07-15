import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/finance_enums.dart';
import 'money.dart';

part 'subscription_item.freezed.dart';
part 'subscription_item.g.dart';

/// A recurring subscription detected for the household (Netflix, gym, …).
@freezed
abstract class SubscriptionItem with _$SubscriptionItem {
  const factory SubscriptionItem({
    required String id,
    required String householdId,
    required String name,
    required Money amount,
    @Default(SubscriptionStatus.active) SubscriptionStatus status,
    @Default(SubscriptionFrequency.monthly) SubscriptionFrequency frequency,
    DateTime? nextChargeAt,
    String? categoryId,
    String? accountId,
    Money? estimatedReportingAmount,
    DateTime? exchangeRateDate,
    @Default(false) bool reminderEnabled,
    @Default(1) int reminderDaysBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _SubscriptionItem;

  factory SubscriptionItem.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionItemFromJson(json);
}
