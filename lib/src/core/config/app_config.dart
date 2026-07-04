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
    required this.geminiApiKey,
    required this.appEnv,
  });

  /// Builds the config from the loaded `.env` (call [Env.load] first).
  factory AppConfig.fromEnv() => AppConfig(
    supabaseUrl: Env.get('SUPABASE_URL'),
    supabaseAnonKey: Env.get('SUPABASE_ANON_KEY'),
    revenueCatKeyIos: Env.get('REVENUECAT_PUBLIC_KEY_IOS'),
    revenueCatKeyAndroid: Env.get('REVENUECAT_PUBLIC_KEY_ANDROID'),
    geminiApiKey: Env.get('GEMINI_API_KEY'),
    appEnv: Env.get('APP_ENV', fallback: 'dev'),
  );

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String revenueCatKeyIos;
  final String revenueCatKeyAndroid;
  final String geminiApiKey;
  final String appEnv;

  /// Whether Supabase credentials are present and the client can be started.
  bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Whether a RevenueCat key exists for the current platform.
  bool get hasRevenueCat => revenueCatKeyForPlatform.isNotEmpty;

  /// Whether a Gemini key is present, enabling receipt photo OCR.
  bool get hasGemini => geminiApiKey.isNotEmpty;

  /// The RevenueCat public key for the running platform (empty if unset).
  String get revenueCatKeyForPlatform {
    if (Platform.isIOS || Platform.isMacOS) return revenueCatKeyIos;
    if (Platform.isAndroid) return revenueCatKeyAndroid;
    return '';
  }

  bool get isProd => appEnv == 'prod';
}
