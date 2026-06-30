import 'app_exception.dart';

/// A user-facing, localizable description of something that went wrong.
///
/// Controllers convert caught [AppException]s (or any error) into an
/// [AppFailure] so the UI shows friendly copy instead of raw exceptions.
class AppFailure {
  const AppFailure(this.message);

  final String message;

  /// Maps a thrown [error] to a friendly message.
  factory AppFailure.from(Object error) {
    if (error is AuthFailureException) {
      return const AppFailure('No pudimos verificar tu sesión.');
    }
    if (error is NetworkException) {
      return const AppFailure('Revisa tu conexión a internet.');
    }
    if (error is NotFoundException) {
      return const AppFailure('No encontramos lo que buscabas.');
    }
    if (error is ServerException) {
      return const AppFailure('Algo falló en el servidor. Inténtalo de nuevo.');
    }
    return const AppFailure('Ocurrió un error inesperado.');
  }

  @override
  String toString() => message;
}
