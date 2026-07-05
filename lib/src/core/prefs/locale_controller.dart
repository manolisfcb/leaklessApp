import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs_providers.dart';

/// The user's manual language override; `null` means "follow the system".
final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

/// Persists the language chosen in Settings so it survives restarts.
class LocaleController extends Notifier<Locale?> {
  static const _prefsKey = 'app_locale';

  @override
  Locale? build() {
    final code = ref.watch(sharedPreferencesProvider).getString(_prefsKey);
    return code == null ? null : Locale(code);
  }

  /// Sets the app language, or clears the override when [locale] is null.
  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }
}
