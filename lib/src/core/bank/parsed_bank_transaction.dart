/// The raw result of parsing a bank SMS/notification, before it becomes a
/// domain `Transaction` (which needs household/category context).
class ParsedBankTransaction {
  const ParsedBankTransaction({
    required this.amountMinorUnits,
    required this.currency,
    this.merchant,
    this.cardLast4,
    this.rawText,
  });

  final int amountMinorUnits;
  final String currency;
  final String? merchant;
  final String? cardLast4;
  final String? rawText;
}
