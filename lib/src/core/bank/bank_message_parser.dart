import 'parsed_bank_transaction.dart';

/// Parses a bank **SMS** into a [ParsedBankTransaction].
///
/// FUTURE PHASE — see the automation roadmap in `flutter_app_design.md`. The
/// interface lives here now so the rest of the app can depend on it, but no SMS
/// permissions are requested yet (privacy first).
abstract interface class BankMessageParser {
  ParsedBankTransaction? parse(String message);
}

/// Placeholder implementation. Returns `null` (no auto-detection) until the
/// SMS-reading phase is built. Real regex/NLP parsing goes here.
class NoopBankMessageParser implements BankMessageParser {
  const NoopBankMessageParser();

  @override
  ParsedBankTransaction? parse(String message) {
    // TODO(automation/phase-1): parse merchant, amount and card from bank SMS.
    return null;
  }
}
