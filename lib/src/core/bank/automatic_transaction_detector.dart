import 'bank_message_parser.dart';
import 'bank_notification_parser.dart';
import 'parsed_bank_transaction.dart';

/// Orchestrates the future "zero-friction" automatic capture: it feeds raw bank
/// SMS / notifications through the parsers and yields candidate transactions for
/// one-tap confirmation.
///
/// FUTURE PHASE — wired with no-op parsers today. It deliberately requests no
/// sensitive OS permissions; that work belongs to a later, opt-in phase.
class AutomaticTransactionDetector {
  AutomaticTransactionDetector({
    BankMessageParser messageParser = const NoopBankMessageParser(),
    BankNotificationParser notificationParser =
        const NoopBankNotificationParser(),
  }) : _messageParser = messageParser,
       _notificationParser = notificationParser;

  final BankMessageParser _messageParser;
  final BankNotificationParser _notificationParser;

  ParsedBankTransaction? fromSms(String message) =>
      _messageParser.parse(message);

  ParsedBankTransaction? fromNotification({
    required String title,
    required String body,
  }) =>
      _notificationParser.parse(title: title, body: body);
}
