import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// App-wide logging setup built on `package:logging`.
///
/// Use `AppLogger.of('Feature')` to get a named logger. In release builds the
/// level is raised so debug noise is dropped.
abstract final class AppLogger {
  AppLogger._();

  static bool _initialized = false;

  /// Configures the root logger. Call once during bootstrap.
  static void init() {
    if (_initialized) return;
    _initialized = true;
    Logger.root.level = kReleaseMode ? Level.WARNING : Level.ALL;
    Logger.root.onRecord.listen((record) {
      developer.log(
        record.message,
        time: record.time,
        level: record.level.value,
        name: record.loggerName,
        error: record.error,
        stackTrace: record.stackTrace,
      );
    });
  }

  /// A named logger for a feature/component.
  static Logger of(String name) => Logger(name);
}
