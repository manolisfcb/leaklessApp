import '../../domain/enums/enums.dart';
import 'app_localizations.dart';

/// Localized display names for domain enums.
///
/// These supersede the hardcoded Spanish `.label` getters on the enums
/// themselves, which will be removed once every call site migrates to l10n.
/// Widgets should call them as `type.localizedLabel(context.l10n)`.
extension TransactionTypeLabelX on TransactionType {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    TransactionType.income => l10n.transactionTypeIncome,
    TransactionType.expense => l10n.transactionTypeExpense,
    TransactionType.transfer => l10n.transactionTypeTransfer,
  };
}

extension TransactionPriorityLabelX on TransactionPriority {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    TransactionPriority.necessity => l10n.priorityNecessity,
    TransactionPriority.lifestyle => l10n.priorityLifestyle,
    TransactionPriority.future => l10n.priorityFuture,
    TransactionPriority.ant => l10n.priorityAnt,
  };
}

extension TransactionSourceLabelX on TransactionSource {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    TransactionSource.manual => l10n.sourceManual,
    TransactionSource.plaid => l10n.sourceBank,
    TransactionSource.import => l10n.sourceImport,
  };
}

extension ResponsibleTypeLabelX on ResponsibleType {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    ResponsibleType.me => l10n.responsibleMe,
    ResponsibleType.partner => l10n.responsiblePartner,
    ResponsibleType.shared => l10n.responsibleShared,
  };
}

extension BudgetStatusLabelX on BudgetStatus {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    BudgetStatus.normal => l10n.budgetStatusNormal,
    BudgetStatus.warning => l10n.budgetStatusWarning,
    BudgetStatus.exceeded => l10n.budgetStatusExceeded,
  };
}

extension GoalStatusLabelX on GoalStatus {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    GoalStatus.active => l10n.goalStatusActive,
    GoalStatus.completed => l10n.goalStatusCompleted,
    GoalStatus.paused => l10n.goalStatusPaused,
    GoalStatus.archived => l10n.goalStatusArchived,
  };
}

extension SubscriptionStatusLabelX on SubscriptionStatus {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    SubscriptionStatus.active => l10n.subscriptionStatusActive,
    SubscriptionStatus.trial => l10n.subscriptionStatusTrial,
    SubscriptionStatus.paused => l10n.subscriptionStatusPaused,
    SubscriptionStatus.canceled => l10n.subscriptionStatusCanceled,
  };
}

extension SubscriptionFrequencyLabelX on SubscriptionFrequency {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    SubscriptionFrequency.weekly => l10n.subscriptionFrequencyWeekly,
    SubscriptionFrequency.monthly => l10n.subscriptionFrequencyMonthly,
    SubscriptionFrequency.yearly => l10n.subscriptionFrequencyYearly,
  };
}
