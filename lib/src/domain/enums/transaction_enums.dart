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

/// Where a transaction came from.
///
/// v1 only produces [manual] entries. [plaid] (bank aggregation) and [import]
/// (CSV/statement) are wired through the data model now so the aggregator work
/// later is a drop-in — see `20260704180000_transaction_source.sql`.
enum TransactionSource {
  @JsonValue('manual')
  manual,
  @JsonValue('plaid')
  plaid,
  @JsonValue('import')
  import;

  String get label => switch (this) {
    TransactionSource.manual => 'Manual',
    TransactionSource.plaid => 'Banco',
    TransactionSource.import => 'Importado',
  };

  /// True when the movement was captured automatically (not hand-entered).
  bool get isAutomatic => this != TransactionSource.manual;
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
