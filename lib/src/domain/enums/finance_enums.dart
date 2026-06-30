import 'package:json_annotation/json_annotation.dart';

/// Budget consumption state. Derived from spent/limit ratio but stored/typed so
/// the UI (tube color, alert borders) maps directly.
enum BudgetStatus {
  @JsonValue('normal')
  normal,
  @JsonValue('warning')
  warning, // >= 75%
  @JsonValue('exceeded')
  exceeded; // >= 100%

  String get label => switch (this) {
    BudgetStatus.normal => 'En control',
    BudgetStatus.warning => 'Cerca del límite',
    BudgetStatus.exceeded => 'Límite superado',
  };

  /// Maps a spent/limit [ratio] to its status (75% / 100% thresholds).
  static BudgetStatus fromRatio(double ratio) {
    if (ratio >= 1.0) return BudgetStatus.exceeded;
    if (ratio >= 0.75) return BudgetStatus.warning;
    return BudgetStatus.normal;
  }
}

/// Lifecycle of a savings goal.
enum GoalStatus {
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('paused')
  paused,
  @JsonValue('archived')
  archived;

  String get label => switch (this) {
    GoalStatus.active => 'Activa',
    GoalStatus.completed => 'Completada',
    GoalStatus.paused => 'En pausa',
    GoalStatus.archived => 'Archivada',
  };
}

/// State of a detected recurring subscription.
enum SubscriptionStatus {
  @JsonValue('active')
  active,
  @JsonValue('trial')
  trial,
  @JsonValue('paused')
  paused,
  @JsonValue('canceled')
  canceled;

  String get label => switch (this) {
    SubscriptionStatus.active => 'Activa',
    SubscriptionStatus.trial => 'Prueba',
    SubscriptionStatus.paused => 'En pausa',
    SubscriptionStatus.canceled => 'Cancelada',
  };
}
