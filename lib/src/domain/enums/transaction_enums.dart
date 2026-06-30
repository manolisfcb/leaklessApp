import 'package:json_annotation/json_annotation.dart';

/// Whether a transaction adds or removes money.
enum TransactionType {
  @JsonValue('income')
  income,
  @JsonValue('expense')
  expense,
  @JsonValue('transfer')
  transfer;

  String get label => switch (this) {
    TransactionType.income => 'Ingreso',
    TransactionType.expense => 'Gasto',
    TransactionType.transfer => 'Transferencia',
  };
}

/// The "intention" behind a spend — the core of leakless's leak detection.
///
/// `ant` (gasto hormiga) are the small, frequent, easy-to-miss purchases the
/// product is built to surface.
enum TransactionPriority {
  @JsonValue('necessity')
  necessity,
  @JsonValue('lifestyle')
  lifestyle,
  @JsonValue('future')
  future,
  @JsonValue('ant')
  ant;

  String get label => switch (this) {
    TransactionPriority.necessity => 'Necesidad',
    TransactionPriority.lifestyle => 'Estilo de Vida',
    TransactionPriority.future => 'Futuro',
    TransactionPriority.ant => 'Hormiga',
  };
}

/// Who is responsible for a transaction within the household.
enum ResponsibleType {
  @JsonValue('me')
  me,
  @JsonValue('partner')
  partner,
  @JsonValue('shared')
  shared;

  String get label => switch (this) {
    ResponsibleType.me => 'Tú',
    ResponsibleType.partner => 'Pareja',
    ResponsibleType.shared => 'Compartido',
  };
}
