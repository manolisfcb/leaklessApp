import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'core/l10n/l10n.dart';
import 'core/notifications/local_reminder_scheduler.dart';
import 'core/notifications/push_token_registrar.dart';
import 'core/prefs/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme.dart';
import 'features/auth/application/session_guard.dart';

/// Root widget: wires the router, theme and localization.
class LeaklessApp extends ConsumerStatefulWidget {
  const LeaklessApp({super.key});

  @override
  ConsumerState<LeaklessApp> createState() => _LeaklessAppState();
}

class _LeaklessAppState extends ConsumerState<LeaklessApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // On resume, re-reconcile local reminders: charges that lapsed while the
    // app was backgrounded get advanced and rescheduled without a server.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(reminderSyncControllerProvider).resync(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the session guard alive: clears user/household-scoped caches on any
    // account change so no session ever sees the previous user's data.
    ref.watch(sessionGuardProvider);
    // Keep the device push token registered for the signed-in account.
    ref.watch(pushTokenRegistrarProvider);
    // Keep local recurring-charge reminders in sync with the subscriptions.
    ref.watch(reminderSyncControllerProvider);
    final router = ref.watch(routerProvider);
    final localeOverride = ref.watch(localeControllerProvider);
    return MaterialApp.router(
      title: 'leakless',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      // Null follows the device language; Spanish (listed first) is the
      // fallback when that language isn't supported.
      locale: localeOverride,
      supportedLocales: const [Locale('es'), Locale('en'), Locale('pt')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) {
        // Keep bare DateFormat()/NumberFormat() calls in the resolved
        // language; date symbols for all three are loaded in bootstrap.
        Intl.defaultLocale = Localizations.localeOf(context).languageCode;
        return child!;
      },
    );
  }
}
