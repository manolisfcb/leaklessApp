// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navHistory => 'History';

  @override
  String get navBudgets => 'Budgets';

  @override
  String get navGoals => 'Goals';

  @override
  String get navSettings => 'Settings';

  @override
  String get categoryGroceries => 'Groceries';

  @override
  String get categoryDining => 'Dining';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryLeisure => 'Leisure';

  @override
  String get categorySubscriptions => 'Subscriptions';

  @override
  String get categorySavings => 'Savings';

  @override
  String get categoryEssentials => 'Essentials';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categoryEmergencyFund => 'Emergency fund';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryNew => 'New category';

  @override
  String get categoryEdit => 'Edit category';

  @override
  String get categoryNameLabel => 'Name';

  @override
  String get categoryNameHint => 'e.g. Pets';

  @override
  String get categoryNameRequired => 'Enter a name.';

  @override
  String get categoryIconLabel => 'Icon';

  @override
  String get categoryColorLabel => 'Color';

  @override
  String get categoryCreate => 'Create category';

  @override
  String get categorySaveChanges => 'Save changes';

  @override
  String get categoryDefaultBadge => 'Default';

  @override
  String get categoryDeleteTitle => 'Delete category';

  @override
  String categoryDeleteWarning(String name) {
    return '\"$name\" and its budgets will be deleted. Its transactions will remain, without a category.';
  }

  @override
  String get categoriesLoadFailed => 'We couldn\'t load the categories';

  @override
  String get categoriesOperationFailed =>
      'We couldn\'t complete the operation. Please try again.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get quickEntryWho => 'Who?';

  @override
  String get quickEntryCategory => 'Category';

  @override
  String get quickEntryNote => 'Note';

  @override
  String get quickEntryNoteHint => 'Description (e.g. store)';

  @override
  String get quickEntryPriority => 'Priority';

  @override
  String get quickEntrySave => 'Save';

  @override
  String get quickEntryScanReceipt => 'Scan receipt';

  @override
  String get quickEntryScanningReceipt => 'Reading receipt…';

  @override
  String get quickEntryTakePhoto => 'Take a photo';

  @override
  String get quickEntryPickFromGallery => 'Choose from gallery';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProfileFallback => 'Your profile';

  @override
  String get settingsHouseholdNameCurrency => 'Name & currency';

  @override
  String get settingsNoHousehold => 'No household';

  @override
  String get settingsPartner => 'Partner';

  @override
  String settingsMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsOn => 'On';

  @override
  String get settingsNotificationsOff => 'Off';

  @override
  String get settingsCategories => 'Categories';

  @override
  String get settingsSubscription => 'Subscription';

  @override
  String get settingsPremium => 'Premium';

  @override
  String get settingsFree => 'Free';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get languageSystem => 'System';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get transactionTypeIncome => 'Income';

  @override
  String get transactionTypeExpense => 'Expense';

  @override
  String get transactionTypeTransfer => 'Transfer';

  @override
  String get priorityNecessity => 'Necessity';

  @override
  String get priorityLifestyle => 'Lifestyle';

  @override
  String get priorityFuture => 'Future';

  @override
  String get priorityAnt => 'Ant';

  @override
  String get sourceManual => 'Manual';

  @override
  String get sourceBank => 'Bank';

  @override
  String get sourceImport => 'Imported';

  @override
  String get responsibleMe => 'You';

  @override
  String get responsiblePartner => 'Partner';

  @override
  String get responsibleShared => 'Shared';

  @override
  String get budgetStatusNormal => 'On track';

  @override
  String get budgetStatusWarning => 'Near the limit';

  @override
  String get budgetStatusExceeded => 'Over the limit';

  @override
  String get goalStatusActive => 'Active';

  @override
  String get goalStatusCompleted => 'Completed';

  @override
  String get goalStatusPaused => 'Paused';

  @override
  String get goalStatusArchived => 'Archived';

  @override
  String get subscriptionStatusActive => 'Active';

  @override
  String get subscriptionStatusTrial => 'Trial';

  @override
  String get subscriptionStatusPaused => 'Paused';

  @override
  String get subscriptionStatusCanceled => 'Canceled';
}
