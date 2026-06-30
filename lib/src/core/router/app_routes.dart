/// Centralized route names & paths for `go_router` (quality rule #13: no
/// scattered magic strings for navigation).
abstract final class AppRoutes {
  AppRoutes._();

  static const String onboarding = '/onboarding';
  static const String auth = '/auth';

  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String budgets = '/budgets';
  static const String goals = '/goals';
  static const String settings = '/settings';

  /// Quick-entry is presented as a modal sheet but also has a route for deep
  /// links / push actions.
  static const String quickEntry = '/quick-entry';

  /// Route names (used with `context.goNamed`).
  static const String onboardingName = 'onboarding';
  static const String authName = 'auth';
  static const String dashboardName = 'dashboard';
  static const String transactionsName = 'transactions';
  static const String budgetsName = 'budgets';
  static const String goalsName = 'goals';
  static const String settingsName = 'settings';
  static const String quickEntryName = 'quick-entry';
}
