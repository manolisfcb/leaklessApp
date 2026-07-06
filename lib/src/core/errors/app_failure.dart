import '../l10n/app_localizations.dart';
import 'app_exception.dart';

/// A user-facing, localizable description of something that went wrong.
///
/// Controllers convert caught [AppException]s (or any error) into an
/// [AppFailure] so the UI shows friendly copy instead of raw exceptions.
class AppFailure {
  const AppFailure(this.message);

  final String message;

  /// Maps a thrown [error] to a friendly, localized message.
  factory AppFailure.from(Object error, AppLocalizations l10n) {
    if (error is AuthFailureException) {
      return AppFailure(l10n.errorAuthSession);
    }
    if (error is NetworkException) {
      return AppFailure(l10n.errorNetwork);
    }
    if (error is NotFoundException) {
      return AppFailure(l10n.errorNotFound);
    }
    if (error is ServerException) {
      return AppFailure(l10n.errorServer);
    }
    return AppFailure(l10n.errorUnexpected);
  }

  @override
  String toString() => message;
}
