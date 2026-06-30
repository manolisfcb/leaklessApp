import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Thin wrapper over `flutter_dotenv` so the rest of the app reads config
/// through one place and never crashes when `.env` is missing.
///
/// No secrets are hardcoded here (quality rule #15); values come from `.env`
/// (see `.env.example`).
abstract final class Env {
  Env._();

  /// Loads `.env`. Safe to call when the file is absent (e.g. CI / fresh
  /// clone) — it simply leaves every key empty, so the app still boots and
  /// backend calls stay guarded by the `AppConfig.has*` flags.
  static Future<void> load() async {
    try {
      await dotenv.load(mergeWith: const {});
    } catch (_) {
      // No `.env` bundled; continue with empty config.
    }
  }

  /// Reads [key], returning [fallback] when unset or empty.
  static String get(String key, {String fallback = ''}) {
    try {
      final value = dotenv.maybeGet(key);
      if (value == null || value.isEmpty) return fallback;
      return value;
    } catch (_) {
      return fallback;
    }
  }
}
