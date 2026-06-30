import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_initializer.dart';
import '../logging/app_logger.dart';

/// Crash & error reporting, backed by Firebase Crashlytics.
///
/// All methods are safe no-ops when Firebase is not configured, so the UI never
/// needs to know whether reporting is active (quality rule #5/#6).
class CrashReporter {
  CrashReporter();

  bool get _enabled => FirebaseInitializer.isReady && !kDebugMode;

  /// Wires Flutter & platform error handlers to Crashlytics. Call in bootstrap
  /// (after Firebase init) from within the same error zone.
  void installErrorHandlers() {
    if (!_enabled) return;
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack, fatal: true);
      return true;
    };
  }

  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    AppLogger.of('Crash').severe('$error', error, stack);
    if (!_enabled) return;
    await FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
  }

  Future<void> setUserId(String? id) async {
    if (!_enabled || id == null) return;
    await FirebaseCrashlytics.instance.setUserIdentifier(id);
  }

  Future<void> log(String message) async {
    if (!_enabled) return;
    await FirebaseCrashlytics.instance.log(message);
  }
}
