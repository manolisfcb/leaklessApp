import 'package:firebase_core/firebase_core.dart';

import '../logging/app_logger.dart';

/// Initializes Firebase as an infrastructure layer (push, crashlytics,
/// analytics).
///
/// Firebase is **optional** for local development: until `flutterfire configure`
/// has generated `firebase_options.dart` and the native config files, init will
/// fail — we swallow that so the app still boots (the services downstream are
/// no-ops when [FirebaseInitializer.isReady] is false).
abstract final class FirebaseInitializer {
  FirebaseInitializer._();

  static bool _isReady = false;

  /// Whether Firebase initialized successfully and its services may be used.
  static bool get isReady => _isReady;

  /// Attempts to initialize the default Firebase app. Returns success.
  static Future<bool> initialize() async {
    if (_isReady) return true;
    try {
      await Firebase.initializeApp();
      _isReady = true;
      AppLogger.of('Firebase').info('Initialized');
    } catch (error, stack) {
      _isReady = false;
      AppLogger.of('Firebase').warning(
        'Not configured — skipping (run `flutterfire configure`).',
        error,
        stack,
      );
    }
    return _isReady;
  }
}
