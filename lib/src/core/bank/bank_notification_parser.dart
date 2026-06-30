import 'parsed_bank_transaction.dart';

/// Parses a bank **push notification** (title/body) into a
/// [ParsedBankTransaction].
///
/// FUTURE PHASE — interface only. No notification-listener permission is
/// requested at this stage.
abstract interface class BankNotificationParser {
  ParsedBankTransaction? parse({required String title, required String body});
}

/// Placeholder implementation; always returns `null` for now.
class NoopBankNotificationParser implements BankNotificationParser {
  const NoopBankNotificationParser();

  @override
  ParsedBankTransaction? parse({required String title, required String body}) {
    // TODO(automation/phase-1): parse bank push notifications.
    return null;
  }
}
