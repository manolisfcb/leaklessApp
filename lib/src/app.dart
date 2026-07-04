import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/theme.dart';
import 'features/auth/application/session_guard.dart';

/// Root widget: wires the router, theme and localization.
class LeaklessApp extends ConsumerWidget {
  const LeaklessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the session guard alive: clears user/household-scoped caches on any
    // account change so no session ever sees the previous user's data.
    ref.watch(sessionGuardProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'leakless',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
