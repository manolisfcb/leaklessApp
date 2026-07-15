import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's [SharedPreferences] instance.
///
/// Overridden in bootstrap with the loaded instance (so reads are synchronous
/// everywhere). Reading it before bootstrap throws a clear error.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError(
    'sharedPreferencesProvider must be overridden in bootstrap.',
  );
});
