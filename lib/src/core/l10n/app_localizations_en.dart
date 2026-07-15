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
  String get navDashboard => 'Dashboard';

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
  String get quickEntryScanSuccess =>
      'Receipt read. Check the details before saving.';

  @override
  String get quickEntryScanEmpty =>
      'We couldn\'t read the receipt. Try another photo or enter it manually.';

  @override
  String get quickEntryScanPhotoAccessDenied =>
      'Allow photo access in Settings to choose an image.';

  @override
  String get quickEntryScanCameraAccessDenied =>
      'Allow camera access in Settings to take a photo.';

  @override
  String get quickEntryScanPickerError =>
      'We couldn\'t open the camera or gallery. Please try again.';

  @override
  String get quickEntryScanNetworkError =>
      'Couldn\'t reach the receipt reader. Check your connection.';

  @override
  String get quickEntryScanRateLimited =>
      'The reader is busy. Wait a few seconds and try again.';

  @override
  String get quickEntryScanUnauthorized => 'Sign in to scan receipts.';

  @override
  String get quickEntryScanInvalidImage =>
      'We couldn\'t process that image. Try another photo.';

  @override
  String get quickEntryScanUnavailable =>
      'The receipt reader is unavailable right now. Try again later.';

  @override
  String get quickEntryScanGenericError =>
      'We couldn\'t read the receipt. Please try again.';

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
  String get settingsBudgets => 'Budgets';

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
  String get budgetAlertsTitle => 'Budget alerts';

  @override
  String get budgetAlertsSubtitle =>
      'You and your partner get a heads-up when the threshold is crossed.';

  @override
  String get budgetAlertThresholdLabel => 'Alert when remaining';

  @override
  String budgetAlertBanner(int percent, String category) {
    return 'Heads up: you\'ve used $percent% of $category this month.';
  }

  @override
  String budgetAlertBannerGeneric(int percent) {
    return 'Heads up: you\'ve used $percent% of a budget this month.';
  }

  @override
  String budgetLimitReachedBanner(String category) {
    return 'You\'ve reached the $category limit this month.';
  }

  @override
  String get budgetLimitReachedBannerGeneric =>
      'You\'ve reached a budget limit this month.';

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

  @override
  String get subscriptionFrequencyWeekly => 'Weekly';

  @override
  String get subscriptionFrequencyMonthly => 'Monthly';

  @override
  String get subscriptionFrequencyYearly => 'Yearly';

  @override
  String get subscriptionsTitle => 'Recurring expenses';

  @override
  String get subscriptionsEmptyTitle => 'No recurring expenses';

  @override
  String get subscriptionsEmptyMessage =>
      'Add your subscriptions and fixed charges to be reminded in time.';

  @override
  String get subscriptionsLoadFailed =>
      'We couldn\'t load your recurring expenses';

  @override
  String get subscriptionsOperationFailed =>
      'We couldn\'t complete the operation. Please try again.';

  @override
  String get subscriptionNew => 'New recurring expense';

  @override
  String get subscriptionEdit => 'Edit recurring expense';

  @override
  String get subscriptionCreate => 'Add';

  @override
  String get subscriptionSaveChanges => 'Save changes';

  @override
  String get subscriptionNameLabel => 'Name';

  @override
  String get subscriptionNameHint => 'e.g. Netflix';

  @override
  String get subscriptionNameRequired => 'Enter a name.';

  @override
  String get subscriptionAmountLabel => 'Amount';

  @override
  String get subscriptionAmountRequired => 'Enter an amount greater than zero.';

  @override
  String get subscriptionFrequencyLabel => 'Frequency';

  @override
  String get subscriptionNextChargeLabel => 'Next charge';

  @override
  String get subscriptionNextChargeNone => 'No date';

  @override
  String get subscriptionNextChargeClear => 'Clear date';

  @override
  String get subscriptionCategoryLabel => 'Category (optional)';

  @override
  String get subscriptionReminderTitle => 'Reminder';

  @override
  String get subscriptionReminderSubtitle =>
      'We\'ll notify you before the charge.';

  @override
  String get subscriptionReminderDaysLabel => 'Notify before';

  @override
  String subscriptionReminderDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: 'Same day',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionDeleteTitle => 'Delete recurring expense';

  @override
  String subscriptionDeleteWarning(String name) {
    return '\"$name\" and its reminder will be deleted.';
  }

  @override
  String get recurringReminderChannelName => 'Charge reminders';

  @override
  String get recurringReminderChannelDescription =>
      'Heads-up before a recurring charge';

  @override
  String get recurringReminderTitle => 'Upcoming charge';

  @override
  String recurringReminderBody(String name) {
    return '$name will be charged soon';
  }

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSaveChanges => 'Save changes';

  @override
  String get commonSignInToContinue => 'Sign in to continue.';

  @override
  String get commonCheckConnection => 'Check your connection and try again.';

  @override
  String get commonInvalidNameMax80 =>
      'Enter a valid name up to 80 characters.';

  @override
  String get commonInvalidCurrency => 'Select a valid currency.';

  @override
  String get commonInvalidEmail => 'Invalid email.';

  @override
  String get authResetPasswordTitle => 'Reset password';

  @override
  String get authSignUpConfirmEmailInfo =>
      'We sent you an email to confirm your account. Open it and come back to sign in.';

  @override
  String get authResetLinkSentInfo =>
      'If the email is registered, we sent a link to reset your password.';

  @override
  String get authCreateAccountTitle => 'Create your account';

  @override
  String get authReviewInvitationTitle => 'Sign in to review your invitation';

  @override
  String get authWelcomeBackTitle => 'Welcome back';

  @override
  String get authPendingInvitationHint =>
      'Use the email the invitation was sent to. We\'ll continue automatically once you sign in.';

  @override
  String get authNameHint => 'Your name';

  @override
  String get authEmailHint => 'Email';

  @override
  String get authPasswordHint => 'Password';

  @override
  String get authConfirmPasswordHint => 'Confirm password';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get authCreateAccountCta => 'Create account';

  @override
  String get authSignInCta => 'Sign in';

  @override
  String get authToggleToSignIn => 'Already have an account? Sign in';

  @override
  String get authToggleToSignUp => 'No account? Sign up';

  @override
  String get authNameRequired => 'Enter your name.';

  @override
  String get authEmailRequired => 'Enter your email.';

  @override
  String get authPasswordRequired => 'Enter your password.';

  @override
  String get authPasswordTooShort => 'At least 6 characters.';

  @override
  String get authPasswordsDontMatch => 'Passwords don\'t match.';

  @override
  String get authForgotPasswordBody =>
      'Enter your email and we\'ll send you a link to create a new password.';

  @override
  String get authSendLink => 'Send link';

  @override
  String get resetPasswordUpdated => 'Password updated.';

  @override
  String get resetPasswordTitle => 'Create a new password';

  @override
  String get resetPasswordBody =>
      'Choose a new password for your account. You\'ll be signed in automatically once you save it.';

  @override
  String get resetPasswordNewLabel => 'New password';

  @override
  String get resetPasswordNewRequired => 'Enter your new password.';

  @override
  String get resetPasswordSave => 'Save password';

  @override
  String get onboardingSlide1Title => 'Spot money leaks';

  @override
  String get onboardingSlide1Body =>
      'Those small, sneaky expenses that slip by unnoticed. leakless makes them visible so you regain control.';

  @override
  String get onboardingSlide2Title => 'Track spending together';

  @override
  String get onboardingSlide2Body =>
      'A shared, real-time ledger. When one of you spends, you both know instantly.';

  @override
  String get onboardingSlide3Title => 'Save together with clear goals';

  @override
  String get onboardingSlide3Body =>
      'Set goals, watch the liquid progress fill up, and celebrate every contribution toward the future you want.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingNext => 'Next';

  @override
  String get householdSetupPartnerEmailInvalid =>
      'Enter a valid email for your partner.';

  @override
  String householdSetupInvitationFailed(String error) {
    return 'We saved the household, but couldn\'t create the invitation. $error';
  }

  @override
  String get householdSetupTitle => 'Set up household';

  @override
  String get householdSetupPreparing => 'Preparing your household…';

  @override
  String get householdSetupLoadErrorTitle => 'We couldn\'t load your household';

  @override
  String get householdSetupNoHouseholdTitle =>
      'Your account doesn\'t have a household yet';

  @override
  String get householdSetupNoHouseholdMessage =>
      'We won\'t show financial data until we recover a valid household.';

  @override
  String get householdSetupWaitingOwnerTitle => 'Waiting for the owner';

  @override
  String get householdSetupWaitingOwnerMessage =>
      'The person who created this household must complete the name and currency. We\'ll update this once they\'re done.';

  @override
  String get householdSetupHeroTitle => 'Let\'s make this household yours';

  @override
  String get householdSetupHeroSubtitle =>
      'Set up the shared basics. You can adjust them later.';

  @override
  String get householdNameLabel => 'Household name';

  @override
  String get householdNameHint => 'Our home';

  @override
  String get householdNameRequired => 'Enter a name for the household.';

  @override
  String get householdCurrencyLabel => 'Primary currency';

  @override
  String get householdCurrencyNote =>
      'The currency can only change while the household has no saved amounts.';

  @override
  String get householdSetupStep2Title => 'Starter categories';

  @override
  String get householdSetupStep2Subtitle =>
      'These categories are ready to record expenses.';

  @override
  String get householdSetupStep3Title => 'Your partner';

  @override
  String get householdSetupStep3Subtitle =>
      'The invitation is optional. You can do it later from Settings.';

  @override
  String get householdPartnerEmailLabel => 'Your partner\'s email';

  @override
  String get householdPartnerEmailHint => 'partner@email.com';

  @override
  String get householdSetupSaveAndInvite => 'Save and invite';

  @override
  String get householdSetupContinueWithoutInvite => 'Continue without inviting';

  @override
  String get categoriesReviewLoadError =>
      'We couldn\'t load the categories. Retry before continuing.';

  @override
  String get categoriesReviewEmpty =>
      'We couldn\'t find any starter categories.';

  @override
  String get householdSetupErrorNotOwner =>
      'Only the person who created this household can set it up.';

  @override
  String get householdSetupErrorCurrencyLocked =>
      'This household already has amounts. Changing the currency could reinterpret them, so we\'re keeping the current currency.';

  @override
  String get householdSetupErrorGeneric =>
      'We couldn\'t save the household. Try again.';

  @override
  String get invitationShareSubject => 'Invitation to our leakless household';

  @override
  String invitationShareText(String link, String code) {
    return 'Join our household on leakless.\n\n$link\n\nIf the link doesn\'t open, paste this code:\n$code';
  }

  @override
  String get invitationShareFailed => 'We couldn\'t open the share menu.';

  @override
  String get invitationsTitle => 'Invite your partner';

  @override
  String get invitationsNoHousehold =>
      'We couldn\'t find an active household to invite to.';

  @override
  String get invitationsNotOwner =>
      'Only the person who created this household can send invitations.';

  @override
  String get invitationEmailRequired => 'Enter their email.';

  @override
  String get invitationCreate => 'Create invitation';

  @override
  String get invitationLinkCopied => 'Link copied.';

  @override
  String get invitationCodeCopied => 'Code copied.';

  @override
  String get invitationHaveCode => 'I have an invitation code';

  @override
  String get invitationsIntroTitleFallback => 'Share the household';

  @override
  String get invitationsIntroSubtitle =>
      'Generate a one-time link. It only works with the email you specify.';

  @override
  String invitationExpiresOn(String date) {
    return 'Expires on $date';
  }

  @override
  String get invitationTitle => 'Invitation';

  @override
  String get invitationShare => 'Share invitation';

  @override
  String get invitationCopyLink => 'Copy link';

  @override
  String get invitationCopyCode => 'Copy code';

  @override
  String get invitationRevoke => 'Revoke invitation';

  @override
  String get invitationNoLongerShareable =>
      'This code can no longer be shared.';

  @override
  String get invitationStatusPending => 'Pending';

  @override
  String get invitationStatusAccepted => 'Accepted';

  @override
  String get invitationStatusCancelled => 'Revoked';

  @override
  String get invitationStatusExpired => 'Expired';

  @override
  String get invitationCodeInvalidFormat =>
      'The code must have 64 hexadecimal characters.';

  @override
  String get invitationExpiredMessage => 'The invitation has expired.';

  @override
  String get invitationCancelledMessage => 'The invitation was revoked.';

  @override
  String get invitationAlreadyUsedMessage =>
      'This invitation has already been used.';

  @override
  String get invitationPersistenceFailed =>
      'Keep the app open: we couldn\'t securely save the attempt.';

  @override
  String get invitationOpenFailed => 'We couldn\'t open this invitation.';

  @override
  String get invitationSuccessHeroTitle => 'You\'re now connected';

  @override
  String get invitationHeroTitle => 'One household, shared by two';

  @override
  String get invitationPasteCodeTitle => 'Paste your code';

  @override
  String get invitationPasteCodeSubtitle =>
      'You can open the link or paste the code you were given here.';

  @override
  String get invitationCodeFieldHint => '64-character code';

  @override
  String get invitationReview => 'Review invitation';

  @override
  String get invitationHouseholdFallback => 'Shared household';

  @override
  String invitationInviterInvited(String inviter) {
    return '$inviter invited you to share this household.';
  }

  @override
  String get invitationInviterFallback => 'Your partner';

  @override
  String invitationValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get invitationAcceptJoin => 'Accept and join';

  @override
  String get invitationNotNow => 'Not now';

  @override
  String get invitationUseAnotherAccount => 'Use another account';

  @override
  String get invitationDiscard => 'Discard invitation';

  @override
  String get invitationAlreadyMember =>
      'You already belonged to this household.';

  @override
  String get invitationAcceptedSuccess =>
      'The invitation was accepted. You can now see your shared finances.';

  @override
  String get invitationGoHome => 'Go to home';

  @override
  String get profileImageTooLarge => 'The image is too large. Try another one.';

  @override
  String get profileUpdated => 'Profile updated.';

  @override
  String get profileChangeAvatarTitle => 'Change avatar';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profileLoading => 'Loading your profile…';

  @override
  String get profileLoadErrorTitle => 'We couldn\'t load your profile';

  @override
  String get profileNoProfileTitle => 'No profile';

  @override
  String get profileNoProfileMessage => 'Sign in again to edit your profile.';

  @override
  String get profileNameLabel => 'Display name';

  @override
  String get profileNameHint => 'How your partner sees you';

  @override
  String get profileNameRequired => 'Enter a display name.';

  @override
  String get profileCurrencyLabel => 'Currency';

  @override
  String get profileAvatarFailed => 'We couldn\'t use that image. Try again.';

  @override
  String get profileErrorGeneric => 'We couldn\'t save the changes. Try again.';

  @override
  String get pickerErrorPhotoAccessDenied =>
      'Allow photo access in Settings to choose an avatar.';

  @override
  String get pickerErrorCameraAccessDenied =>
      'Allow camera access in Settings to take a photo.';

  @override
  String get pickerErrorGeneric =>
      'We couldn\'t open the image picker. Try again.';

  @override
  String get dashboardLoading => 'Loading your dashboard…';

  @override
  String get dashboardLoadErrorTitle => 'We couldn\'t load the dashboard';

  @override
  String get dashboardLoadErrorMessage => 'Try again in a moment.';

  @override
  String get dashboardAvailableBalance => 'Available balance';

  @override
  String get dashboardRecentActivity => 'Recent activity';

  @override
  String get dashboardSeeAll => 'See all';

  @override
  String get dashboardSavingsRate => 'Real savings rate';

  @override
  String get dashboardRecurringExpenses => 'Recurring expenses';

  @override
  String get dashboardLimitAlerts => 'Limit alerts';

  @override
  String get dashboardSavingsRateShort => 'savings rate';

  @override
  String dashboardLeak(String amount) {
    return 'Leak $amount';
  }

  @override
  String get transactionsLoadError => 'We couldn\'t load the history';

  @override
  String get transactionsEmptyTitle => 'No transactions';

  @override
  String get transactionsEmptyMessage =>
      'Adjust the filters or record your first expense.';

  @override
  String get transactionsFilterUncategorized => 'Uncategorized';

  @override
  String get transactionFallbackTitle => 'Transaction';

  @override
  String get errorAuthSession => 'We couldn\'t verify your session.';

  @override
  String get errorNetwork => 'Check your internet connection.';

  @override
  String get errorNotFound => 'We couldn\'t find what you were looking for.';

  @override
  String get errorServer => 'Something went wrong on the server. Try again.';

  @override
  String get errorUnexpected => 'An unexpected error occurred.';

  @override
  String get authErrorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Confirm your email before signing in. Check your inbox.';

  @override
  String get authErrorEmailExists =>
      'An account with this email already exists. Sign in.';

  @override
  String get authErrorWeakPassword =>
      'The password is too weak. Use at least 6 characters.';

  @override
  String get authErrorSamePassword =>
      'The new password must be different from the previous one.';

  @override
  String get authErrorInvalidEmail => 'The email isn\'t valid.';

  @override
  String get authErrorSignupDisabled => 'Sign-up is disabled for now.';

  @override
  String get authErrorRateLimit =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get authErrorGeneric =>
      'We couldn\'t complete the operation. Try again.';

  @override
  String get authErrorUnexpected => 'An unexpected error occurred. Try again.';

  @override
  String get invitationErrorInvalidEmail => 'Enter a valid email.';

  @override
  String get invitationErrorInvalidExpiry =>
      'The invitation duration isn\'t valid.';

  @override
  String get invitationErrorCannotInviteSelf =>
      'You can\'t invite your own email.';

  @override
  String get invitationErrorNotOwner =>
      'Only the person who created this household can invite.';

  @override
  String get invitationErrorAlreadyMember =>
      'That person already belongs to this household.';

  @override
  String get invitationErrorInvalidToken =>
      'The invitation link or code isn\'t valid.';

  @override
  String get invitationErrorEmailMismatch =>
      'This invitation was sent to a different email. Use that account to continue.';

  @override
  String get invitationErrorNotFound => 'We couldn\'t find this invitation.';

  @override
  String get invitationErrorAcceptedCannotCancel =>
      'An accepted invitation can no longer be revoked.';

  @override
  String get invitationErrorHouseholdNotEmpty =>
      'Your current household has data. We can\'t move it automatically.';

  @override
  String get invitationErrorProfileNotFound =>
      'We couldn\'t find your profile. Try again.';

  @override
  String get invitationErrorGeneric =>
      'We couldn\'t complete the invitation. Try again.';

  @override
  String get currencyCAD => 'Canadian dollar';

  @override
  String get currencyUSD => 'US dollar';

  @override
  String get currencyEUR => 'Euro';

  @override
  String get currencyMXN => 'Mexican peso';

  @override
  String get currencyCOP => 'Colombian peso';

  @override
  String get currencyARS => 'Argentine peso';

  @override
  String get currencyCLP => 'Chilean peso';

  @override
  String get currencyPEN => 'Peruvian sol';

  @override
  String get currencyBRL => 'Brazilian real';

  @override
  String get currencyGBP => 'Pound sterling';

  @override
  String get currencyJPY => 'Japanese yen';

  @override
  String get currencyCHF => 'Swiss franc';

  @override
  String get insightsTitle => 'Dashboard';

  @override
  String get insightsLoading => 'Loading your stats…';

  @override
  String get insightsErrorTitle => 'We couldn’t load your stats';

  @override
  String get insightsErrorMessage => 'Check your connection and try again.';

  @override
  String get insightsRetry => 'Retry';

  @override
  String get insightsEmptyTitle => 'No expenses yet';

  @override
  String get insightsEmptyMessage =>
      'Log your first expense to see this month’s stats.';

  @override
  String get insightsEmptyAction => 'Log an expense';

  @override
  String get insightsMonthSummaryTitle => 'This month';

  @override
  String get insightsSpentLabel => 'Spent this month';

  @override
  String insightsOfBudget(String budget) {
    return 'of $budget';
  }

  @override
  String insightsBudgetUsed(int percent) {
    return '$percent% used';
  }

  @override
  String insightsRemaining(String amount) {
    return '$amount left';
  }

  @override
  String insightsOverBudgetBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String get insightsNoBudgetNote =>
      'You haven’t set a budget this month yet. Create one to track your pace.';

  @override
  String get insightsCreateBudget => 'Create budget';

  @override
  String get insightsStatusOnTrack => 'You’re right on track with your budget.';

  @override
  String get insightsStatusAhead => 'You’re under your expected pace. Nice!';

  @override
  String get insightsStatusAtRisk => 'You’re spending faster than planned.';

  @override
  String get insightsStatusOver => 'You’ve gone over this month’s budget.';

  @override
  String get insightsPaceTitle => 'Spending pace';

  @override
  String get insightsPaceExpected => 'Expected by today';

  @override
  String get insightsPaceActual => 'Spent by today';

  @override
  String insightsPaceAhead(String amount) {
    return 'You’re $amount under pace.';
  }

  @override
  String insightsPaceBehind(String amount) {
    return 'You’re $amount over pace.';
  }

  @override
  String get insightsPaceOnPace => 'Right on the expected pace.';

  @override
  String insightsPaceReduce(String amount) {
    return 'Trim $amount to close within budget.';
  }

  @override
  String get insightsCategoriesTitle => 'Spending by category';

  @override
  String insightsCategoryShare(int percent) {
    return '$percent% of total';
  }

  @override
  String get insightsCategoryUnnamed => 'Category';

  @override
  String insightsCategoryRemaining(String amount) {
    return '$amount left';
  }

  @override
  String insightsCategoryOverBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String get insightsPieTitle => 'Spending by category';

  @override
  String get insightsPieOthers => 'Others';

  @override
  String get insightsPieCenterLabel => 'spent';

  @override
  String get insightsRunawayTitle => 'Categories out of control';

  @override
  String insightsRunawayBadge(int percent) {
    return '+$percent%';
  }

  @override
  String insightsRunawayCompare(String average) {
    return '3-month average: $average';
  }

  @override
  String get insightsTrendTitle => 'Historical comparison';

  @override
  String get insightsTrendVsPreviousLabel => 'Previous month';

  @override
  String get insightsTrendVsAverageLabel => '3-month average';

  @override
  String insightsTrendChangeUp(int percent) {
    return '$percent% more';
  }

  @override
  String insightsTrendChangeDown(int percent) {
    return '$percent% less';
  }

  @override
  String get insightsTrendChangeStable => 'Similar';

  @override
  String get insightsTrendNoPreviousMonth =>
      'No data for the previous month yet.';

  @override
  String get insightsProjectionTitle => 'End-of-month projection';

  @override
  String get insightsProjectionInsufficientData =>
      'We need a few more days of this month to project your close.';

  @override
  String get insightsProjectionLabel => 'Estimated by month end';

  @override
  String insightsProjectionOverBudget(String amount) {
    return 'You\'d go over budget by $amount.';
  }

  @override
  String get insightsProjectionWithinBudget =>
      'You\'d close the month within budget.';

  @override
  String get insightsDailyTitle => 'Daily spending';

  @override
  String get insightsDailyAverageLabel => 'Daily average';

  @override
  String get insightsDailyMostExpensiveLabel => 'Priciest day';

  @override
  String get insightsDailyNoSpendLabel => 'Days without spending';

  @override
  String insightsDailyNoSpendValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: '0 days',
    );
    return '$_temp0';
  }

  @override
  String get insightsWeekdayTitle => 'Weekly pattern';

  @override
  String get insightsWeekdayMostExpensiveLabel => 'Highest-spend day';

  @override
  String get insightsWeekdayLeastExpensiveLabel => 'Lowest-spend day';

  @override
  String get insightsLastActivityTitle => 'Last activity by category';

  @override
  String get insightsLastActivityToday => 'Today';

  @override
  String get insightsLastActivityYesterday => 'Yesterday';

  @override
  String insightsLastActivityDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get insightsUncategorizedTitle => 'Uncategorized';

  @override
  String insightsUncategorizedMessage(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
    );
    return '$_temp0 with no category this month, totaling $amount.';
  }

  @override
  String get insightsUncategorizedAction => 'Categorize now';

  @override
  String get insightsRecommendationsTitle => 'Recommendations';

  @override
  String insightsRecommendationReduceCategory(String amount, String category) {
    return 'To close the month on budget, trim about $amount from $category.';
  }

  @override
  String insightsRecommendationRunaway(String category) {
    return '$category is spending well above usual this month. Worth a look.';
  }

  @override
  String get insightsRecommendationAllOnTrack =>
      'You\'re doing great this month! Keep it up.';

  @override
  String get quickEntryTitle => 'Quick entry';
}
