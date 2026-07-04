import 'package:freezed_annotation/freezed_annotation.dart';

part 'household.freezed.dart';
part 'household.g.dart';

/// A shared financial space for a couple/family — the unit everything else
/// (transactions, budgets, goals) belongs to.
@freezed
abstract class Household with _$Household {
  const factory Household({
    required String id,
    required String name,
    required String ownerId,
    @Default('USD') String currency,
    @Default(false) bool setupCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Household;

  factory Household.fromJson(Map<String, dynamic> json) =>
      _$HouseholdFromJson(json);
}
