import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../logging/app_logger.dart';

/// Initializes the Supabase SDK if credentials are present.
///
/// Returns `true` when the client is ready. When Supabase is not configured the
/// app still runs against mock repositories (quality rule: app must compile and
/// run before the backend is wired).
Future<bool> initializeSupabase(AppConfig config) async {
  if (!config.hasSupabase) {
    AppLogger.of('Supabase').info('Skipped init: SUPABASE_* not set in .env');
    return false;
  }
  await Supabase.initialize(
    url: config.supabaseUrl,
    // The legacy "anon key" is Supabase's publishable key; the env var keeps the
    // familiar name. `anonKey` is deprecated in favor of `publishableKey`.
    // ignore: deprecated_member_use
    anonKey: config.supabaseAnonKey,
  );
  return true;
}

/// The live [SupabaseClient].
///
/// Overridden in bootstrap with the real instance once [initializeSupabase]
/// succeeds. Reading it before initialization throws a clear error so misuse is
/// caught immediately.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  throw StateError(
    'SupabaseClient is not available. Set SUPABASE_URL / SUPABASE_ANON_KEY in '
    '.env and ensure bootstrap called initializeSupabase().',
  );
});

/// Whether Supabase is configured & initialized. Overridden in bootstrap.
final supabaseEnabledProvider = Provider<bool>((ref) => false);
