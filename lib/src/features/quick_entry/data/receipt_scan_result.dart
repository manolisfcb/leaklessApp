import '../../../domain/models/money.dart';

/// The structured data extracted from a receipt photo by [ReceiptScanService].
///
/// Every field is optional: OCR is best-effort, so the Quick Entry form only
/// prefills what came back and leaves the user to complete or correct the rest.
class ReceiptScanResult {
  const ReceiptScanResult({
    this.amount,
    this.description,
    this.occurredAt,
    this.categoryName,
  });

  /// Total charged on the receipt, already in the household currency.
  final Money? amount;

  /// A short human label — usually the merchant name.
  final String? description;

  /// When the purchase happened, if the receipt showed a date.
  final DateTime? occurredAt;

  /// A category name suggested by the model, matched against the household's
  /// own categories by the caller (never trusted as an id).
  final String? categoryName;

  /// True when nothing usable was extracted, so the UI can tell the user the
  /// scan came back empty instead of silently doing nothing.
  bool get isEmpty =>
      amount == null &&
      (description == null || description!.isEmpty) &&
      occurredAt == null &&
      (categoryName == null || categoryName!.isEmpty);
}
