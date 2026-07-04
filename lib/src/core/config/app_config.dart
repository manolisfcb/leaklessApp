import 'dart:io' show Platform;

import 'env.dart';

/// Runtime configuration, resolved once from the environment (`.env`).
///
/// Centralizes every external key/URL so nothing is hardcoded (quality rule
/// #15) and so features can guard themselves with the `has*` flags when a
/// backend has not been wired yet.
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.revenueCatKeyIos,
    required this.revenueCatKeyAndroid,
    required this.receiptScanEnabled,
    required this.appEnv,
  });

  /// Builds the config from the loaded `.env` (call [Env.load] first).
  factory AppConfig.fromEnv() => AppConfig(
    supabaseUrl: Env.get('SUPABASE_URL'),
    supabaseAnonKey: Env.get('SUPABASE_ANON_KEY'),
    revenueCatKeyIos: Env.get('REVENUECAT_PUBLIC_KEY_IOS'),
    revenueCatKeyAndroid: Env.get('REVENUECAT_PUBLIC_KEY_ANDROID'),
    // Off by default: receipt OCR needs the `scan-receipt` Edge Function
    // deployed and its `GEMINI_API_KEY` secret set (server-side). Flip this on
    // only once that's in place — the Gemini key never lives in the app.
    receiptScanEnabled:
        Env.get('RECEIPT_SCAN_ENABLED').toLowerCase() == 'true',
    appEnv: Env.get('APP_ENV', fallback: 'dev'),
  );

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String revenueCatKeyIos;
  final String revenueCatKeyAndroid;

  /// Whether receipt photo OCR (via the server-side Edge Function) is enabled.
  final bool receiptScanEnabled;

  final String appEnv;

  /// Whether Supabase credentials are present and the client can be started.
  bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Whether a RevenueCat key exists for the current platform.
  bool get hasRevenueCat => revenueCatKeyForPlatform.isNotEmpty;

  /// The RevenueCat public key for the running platform (empty if unset).
  String get revenueCatKeyForPlatform {
    if (Platform.isIOS || Platform.isMacOS) return revenueCatKeyIos;
    if (Platform.isAndroid) return revenueCatKeyAndroid;
    return '';
  }

  bool get isProd => appEnv == 'prod';
}
