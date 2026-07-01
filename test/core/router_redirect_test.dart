import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/core/prefs/prefs_providers.dart';
import 'package:leakless/src/core/router/app_router.dart';
import 'package:leakless/src/core/router/app_routes.dart';
import 'package:leakless/src/core/theme/theme.dart';
import 'package:leakless/src/features/auth/application/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mirrors the real [LeaklessApp]: a ConsumerWidget that *watches* routerProvider.
class _TestApp extends ConsumerWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(0.8)),
        child: child!,
      ),
    );
  }
}

void main() {
  testWidgets('signing in redirects from /auth to the dashboard', (
    tester,
  ) async {
    // Onboarding already completed → app should sit on /auth, not onboarding.
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const _TestApp()),
    );
    await tester.pumpAndSettle();

    final router = container.read(routerProvider);

    // Signed out + onboarding done → we should be on /auth.
    expect(router.routerDelegate.currentConfiguration.uri.path, AppRoutes.auth);

    // Perform a live, interactive sign-in (FakeAuthRepository, Supabase off).
    await container
        .read(authControllerProvider.notifier)
        .signIn('demo@leakless.app', 'demo1234');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The auth state change should drive the router to the dashboard.
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.dashboard,
    );
  });
}
