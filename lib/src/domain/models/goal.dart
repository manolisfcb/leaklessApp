import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/finance_enums.dart';
import 'money.dart';

part 'goal.freezed.dart';
part 'goal.g.dart';

/// A shared savings goal (the "translucent chest" from the design).
@freezed
abstract class Goal with _$Goal {
  const factory Goal({
    required String id,
    required String householdId,
    required String name,
    required Money target,
    @Default(Money.zero) Money saved,
    @Default(GoalStatus.active) GoalStatus status,
    DateTime? deadline,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Goal;
  const Goal._();

  factory Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);

  /// Saved / target, clamped to 0..1.
  double get progress {
    if (target.minorUnits <= 0) return 0;
    return (saved.minorUnits / target.minorUnits).clamp(0, 1).toDouble();
  }

  bool get isCompleted =>
      status == GoalStatus.completed || saved.minorUnits >= target.minorUnits;

  Money get remaining {
    final diff = target.minorUnits - saved.minorUnits;
    return target.copyWith(minorUnits: diff < 0 ? 0 : diff);
  }
}
