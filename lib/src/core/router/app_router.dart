import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/app_user.dart';
import '../../domain/models/household_invitation.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/budgets/presentation/budgets_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/goals/presentation/goals_screen.dart';
import '../../features/household/application/household_providers.dart';
import '../../features/household/application/invitation_intent_controller.dart';
import '../../features/household/application/invitation_links.dart';
import '../../features/household/presentation/household_invitations_screen.dart';
import '../../features/household/presentation/household_setup_screen.dart';
import '../../features/household/presentation/invitation_screen.dart';
import '../../features/onboarding/application/onboarding_providers.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_edit_screen.dart';
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
    _ref.listen(
      invitationIntentControllerProvider,
      (_, _) => notifyListeners(),
    );
    _ref.listen(householdSetupStateProvider, (_, _) => notifyListeners());
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
      final incomingToken = InvitationLinks.tokenFromUri(state.uri);
      if (incomingToken != null) {
        unawaited(
          ref
              .read(invitationIntentControllerProvider.notifier)
              .capture(incomingToken),
        );
      }

      final onboardingDone = ref.read(onboardingCompletedProvider);
      final signedIn = ref.read(authRepositoryProvider).currentUser != null;
      final pendingInvitation =
          incomingToken ?? ref.read(invitationIntentControllerProvider).token;
      final location = state.matchedLocation;
      final atOnboarding = location == AppRoutes.onboarding;
      final atAuth = location == AppRoutes.auth;
      final atInvitation = location == AppRoutes.invitation;
      final atHouseholdSetup = location == AppRoutes.householdSetup;

      if (!onboardingDone) return atOnboarding ? null : AppRoutes.onboarding;
      if (!signedIn) return atAuth ? null : AppRoutes.auth;
      if (incomingToken != null) return AppRoutes.invitation;
      if (pendingInvitation != null && !atInvitation) {
        return AppRoutes.invitation;
      }

      final setup = ref.read(householdSetupStateProvider).asData?.value;
      final householdReady =
          setup == HouseholdSetupState.readySolo ||
          setup == HouseholdSetupState.readyShared;
      if (!householdReady) {
        return atHouseholdSetup ? null : AppRoutes.householdSetup;
      }
      if (atHouseholdSetup || atOnboarding || atAuth) {
        return AppRoutes.dashboard;
      }
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
      GoRoute(
        path: AppRoutes.householdSetup,
        name: AppRoutes.householdSetupName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const HouseholdSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.householdConfiguration,
        name: AppRoutes.householdConfigurationName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const HouseholdSetupScreen(isOnboarding: false),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        name: AppRoutes.profileEditName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: AppRoutes.invitation,
        name: AppRoutes.invitationName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const InvitationScreen(),
      ),
      GoRoute(
        path: AppRoutes.householdInvitations,
        name: AppRoutes.householdInvitationsName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => HouseholdInvitationsScreen(
          initialInvitation: state.extra is HouseholdInvitation
              ? state.extra! as HouseholdInvitation
              : null,
        ),
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
