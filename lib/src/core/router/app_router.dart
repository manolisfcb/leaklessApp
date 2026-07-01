import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/app_user.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/budgets/presentation/budgets_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/goals/presentation/goals_screen.dart';
import '../../features/onboarding/application/onboarding_providers.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/quick_entry/presentation/quick_entry_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import 'app_routes.dart';
import 'app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Rebuilds the router's redirect when auth or onboarding state changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _authSubscription = _ref
        .read(authRepositoryProvider)
        .authStateChanges()
        .listen((_) => notifyListeners());
    _ref.listen(onboardingCompletedProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
  late final StreamSubscription<AppUser?> _authSubscription;

  @override
  void dispose() {
    unawaited(_authSubscription.cancel());
    super.dispose();
  }
}

/// The app's [GoRouter]. Redirects enforce: onboarding → auth → app.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    refreshListenable: refresh,
    redirect: (context, state) {
      final onboardingDone = ref.read(onboardingCompletedProvider);
      final signedIn = ref.read(authRepositoryProvider).currentUser != null;
      final location = state.matchedLocation;
      final atOnboarding = location == AppRoutes.onboarding;
      final atAuth = location == AppRoutes.auth;

      if (!onboardingDone) return atOnboarding ? null : AppRoutes.onboarding;
      if (!signedIn) return atAuth ? null : AppRoutes.auth;
      if (atOnboarding || atAuth) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRoutes.onboardingName,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        name: AppRoutes.authName,
        builder: (_, _) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.quickEntry,
        name: AppRoutes.quickEntryName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const QuickEntryScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                name: AppRoutes.dashboardName,
                builder: (_, _) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.transactions,
                name: AppRoutes.transactionsName,
                builder: (_, _) => const TransactionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.budgets,
                name: AppRoutes.budgetsName,
                builder: (_, _) => const BudgetsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.goals,
                name: AppRoutes.goalsName,
                builder: (_, _) => const GoalsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                name: AppRoutes.settingsName,
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
