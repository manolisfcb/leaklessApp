/// Internal, technical exceptions raised by the data layer.
///
/// Repositories catch backend-specific errors (Supabase, network, …) and
/// rethrow them as one of these so upper layers never depend on a backend's
/// error types (quality rule #5/#7). Map to a user-facing message with
/// [AppFailure].
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

/// Authentication / authorization problems.
class AuthFailureException extends AppException {
  const AuthFailureException(super.message, {super.cause, super.stackTrace});
}

/// Connectivity / timeout problems.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause, super.stackTrace});
}

/// Backend (Supabase/Postgres/RPC) errors.
class ServerException extends AppException {
  const ServerException(super.message, {super.cause, super.stackTrace});
}

/// A requested entity was not found.
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause, super.stackTrace});
}

/// Anything unexpected.
class UnknownException extends AppException {
  const UnknownException(super.message, {super.cause, super.stackTrace});
}
