/// Centralized route names & paths for `go_router` (quality rule #13: no
/// scattered magic strings for navigation).
abstract final class AppRoutes {
  AppRoutes._();

  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String resetPassword = '/reset-password';

  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String insights = '/insights';
  static const String budgets = '/budgets';
  static const String goals = '/goals';
  static const String settings = '/settings';
  static const String categories = '/settings/categories';
  static const String subscriptions = '/settings/subscriptions';
  static const String accounts = '/settings/accounts';
  static const String incomeSources = '/settings/income-sources';
  static const String profileEdit = '/profile/edit';
  static const String householdSetup = '/household/setup';
  static const String householdConfiguration = '/household/configuration';
  static const String householdInvitations = '/household/invitations';
  static const String invitation = '/invite';

  /// Quick-entry is presented as a modal sheet but also has a route for deep
  /// links / push actions.
  static const String quickEntry = '/quick-entry';

  /// Route names (used with `context.goNamed`).
  static const String onboardingName = 'onboarding';
  static const String authName = 'auth';
  static const String resetPasswordName = 'reset-password';
  static const String dashboardName = 'dashboard';
  static const String transactionsName = 'transactions';
  static const String insightsName = 'insights';
  static const String budgetsName = 'budgets';
  static const String goalsName = 'goals';
  static const String settingsName = 'settings';
  static const String categoriesName = 'categories';
  static const String subscriptionsName = 'subscriptions';
  static const String accountsName = 'accounts';
  static const String incomeSourcesName = 'income-sources';
  static const String profileEditName = 'profile-edit';
  static const String householdSetupName = 'household-setup';
  static const String householdConfigurationName = 'household-configuration';
  static const String householdInvitationsName = 'household-invitations';
  static const String invitationName = 'invitation';
  static const String quickEntryName = 'quick-entry';
}
