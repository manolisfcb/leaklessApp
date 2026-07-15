import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/env.dart';
import 'core/core_providers.dart';
import 'core/firebase/firebase_initializer.dart';
import 'core/logging/app_logger.dart';
import 'core/notifications/notification_providers.dart';
import 'core/prefs/prefs_providers.dart';
import 'core/purchases/purchases_providers.dart';
import 'core/supabase/supabase_providers.dart';

/// Initializes every cross-cutting service, builds the Riverpod container with
/// the resolved overrides, then runs the app inside a guarded zone so uncaught
/// errors reach the crash reporter.
Future<void> bootstrap() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      AppLogger.init();

      await Env.load();
      final config = AppConfig.fromEnv();

      // Date symbols for every supported language; the app sets
      // Intl.defaultLocale from the resolved locale (see LeaklessApp.builder).
      for (final locale in ['es', 'en', 'pt']) {
        await initializeDateFormatting(locale, null);
      }

      final prefs = await SharedPreferences.getInstance();
      final supabaseReady = await initializeSupabase(config);
      await FirebaseInitializer.initialize();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          supabaseEnabledProvider.overrideWithValue(supabaseReady),
          if (supabaseReady)
            supabaseClientProvider.overrideWithValue(Supabase.instance.client),
        ],
      );

      // Optional infra — all safe no-ops until configured.
      container.read(crashReporterProvider).installErrorHandlers();
      unawaited(container.read(notificationServiceProvider).initialize());
      unawaited(container.read(purchasesServiceProvider).configure());

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const LeaklessApp(),
        ),
      );
    },
    (error, stack) =>
        AppLogger.of('bootstrap').severe('Uncaught zone error', error, stack),
  );
}
