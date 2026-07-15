import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/core/prefs/prefs_providers.dart';
import 'package:leakless/src/core/router/app_router.dart';
import 'package:leakless/src/core/router/app_routes.dart';
import 'package:leakless/src/core/theme/theme.dart';
import 'package:leakless/src/domain/models/household.dart';
import 'package:leakless/src/features/auth/application/auth_controller.dart';
import 'package:leakless/src/features/auth/application/auth_providers.dart';
import 'package:leakless/src/features/auth/application/password_recovery_controller.dart';
import 'package:leakless/src/features/auth/data/auth_repository.dart';
import 'package:leakless/src/features/budgets/presentation/budgets_screen.dart';
import 'package:leakless/src/features/household/application/household_providers.dart';
import 'package:leakless/src/features/household/application/invitation_intent_controller.dart';
import 'package:leakless/src/features/insights/presentation/insights_screen.dart';
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
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        invitationIntentStoreProvider.overrideWithValue(
          _MemoryInvitationIntentStore(),
        ),
      ],
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

  testWidgets(
    'insights owns the old budgets tab slot and budgets keeps its path '
    'as a top-level route with a back stack',
    (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          invitationIntentStoreProvider.overrideWithValue(
            _MemoryInvitationIntentStore(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const _TestApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);

      await container
          .read(authControllerProvider.notifier)
          .signIn('demo@leakless.app', 'demo1234');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The shell tab that used to host budgets now shows the insights
      // placeholder.
      router.go(AppRoutes.insights);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.insights,
      );
      expect(find.byType(InsightsScreen), findsOneWidget);

      // A budget_alert / limit_reached push still deep-links to /budgets,
      // which now sits above the shell and can pop back. Imperative pushes
      // don't update currentConfiguration.uri, so assert on the widget tree.
      unawaited(router.push<void>(AppRoutes.budgets));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(BudgetsScreen), findsOneWidget);
      expect(router.canPop(), isTrue);

      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(BudgetsScreen), findsNothing);
      expect(find.byType(InsightsScreen), findsOneWidget);
    },
  );

  testWidgets(
    'a signed-in owner must configure the household before the dashboard',
    (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          invitationIntentStoreProvider.overrideWithValue(
            _MemoryInvitationIntentStore(),
          ),
          currentHouseholdProvider.overrideWith(
            (ref) async => const Household(
              id: 'starter',
              name: 'Nuestra casa',
              ownerId: 'demo-me',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const _TestApp(),
        ),
      );
      await tester.pumpAndSettle();

      await container
          .read(authControllerProvider.notifier)
          .signIn('owner@leakless.app', 'demo1234');
      await tester.pumpAndSettle();

      expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        AppRoutes.householdSetup,
      );
    },
  );

  testWidgets(
    'a password-recovery session is pinned to the reset screen, not the dashboard',
    (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          invitationIntentStoreProvider.overrideWithValue(
            _MemoryInvitationIntentStore(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const _TestApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);

      // Opening the recovery deep link establishes a session AND flags recovery.
      final auth = container.read(authRepositoryProvider) as FakeAuthRepository;
      auth.emitPasswordRecovery();
      await tester.pumpAndSettle();

      // Signed in, but must not have reached the dashboard.
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.resetPassword,
      );

      // Saving a new password clears recovery; the router redirects onward.
      final saved = await container
          .read(resetPasswordControllerProvider.notifier)
          .submit('newpass123');
      expect(saved, isTrue);
      // Not pumpAndSettle: the onward screen may hold a perpetual loader.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        isNot(AppRoutes.resetPassword),
      );
    },
  );

  testWidgets(
    'an invite survives auth and its token is stripped from the URL',
    (tester) async {
      const token =
          'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();
      final store = _MemoryInvitationIntentStore();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          invitationIntentStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const _TestApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);

      router.go('${AppRoutes.invitation}?token=$token');
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.auth,
      );
      expect(store.value, token);

      await container
          .read(authControllerProvider.notifier)
          .signIn('demo@leakless.app', 'demo1234');
      await tester.pumpAndSettle();

      final uri = router.routerDelegate.currentConfiguration.uri;
      expect(uri.path, AppRoutes.invitation);
      expect(uri.queryParameters, isEmpty);
    },
  );
}

class _MemoryInvitationIntentStore implements InvitationIntentStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;

  @override
  Future<void> clear() async => value = null;
}
