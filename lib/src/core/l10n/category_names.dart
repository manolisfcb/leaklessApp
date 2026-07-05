import '../../domain/models/transaction_category.dart';
import 'app_localizations.dart';

/// Localizes seeded categories by their stable slug and preserves custom names.
String categoryDisplayName(
  TransactionCategory category,
  AppLocalizations l10n,
) => switch (category.slug) {
  'groceries' => l10n.categoryGroceries,
  'dining' => l10n.categoryDining,
  'transport' => l10n.categoryTransport,
  'leisure' => l10n.categoryLeisure,
  'subscriptions' => l10n.categorySubscriptions,
  'savings' => l10n.categorySavings,
  'essentials' => l10n.categoryEssentials,
  'education' => l10n.categoryEducation,
  'emergency_fund' => l10n.categoryEmergencyFund,
  'health' => l10n.categoryHealth,
  _ => category.name,
};
