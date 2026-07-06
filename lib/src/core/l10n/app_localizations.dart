import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get navHistory;

  /// No description provided for @navBudgets.
  ///
  /// In es, this message translates to:
  /// **'Presupuestos'**
  String get navBudgets;

  /// No description provided for @navGoals.
  ///
  /// In es, this message translates to:
  /// **'Metas'**
  String get navGoals;

  /// No description provided for @navSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get navSettings;

  /// No description provided for @categoryGroceries.
  ///
  /// In es, this message translates to:
  /// **'Supermercado'**
  String get categoryGroceries;

  /// No description provided for @categoryDining.
  ///
  /// In es, this message translates to:
  /// **'Restaurantes'**
  String get categoryDining;

  /// No description provided for @categoryTransport.
  ///
  /// In es, this message translates to:
  /// **'Transporte'**
  String get categoryTransport;

  /// No description provided for @categoryLeisure.
  ///
  /// In es, this message translates to:
  /// **'Ocio'**
  String get categoryLeisure;

  /// No description provided for @categorySubscriptions.
  ///
  /// In es, this message translates to:
  /// **'Suscripciones'**
  String get categorySubscriptions;

  /// No description provided for @categorySavings.
  ///
  /// In es, this message translates to:
  /// **'Ahorro'**
  String get categorySavings;

  /// No description provided for @categoryEssentials.
  ///
  /// In es, this message translates to:
  /// **'Gastos esenciales'**
  String get categoryEssentials;

  /// No description provided for @categoryEducation.
  ///
  /// In es, this message translates to:
  /// **'Estudios'**
  String get categoryEducation;

  /// No description provided for @categoryEmergencyFund.
  ///
  /// In es, this message translates to:
  /// **'Reserva de emergencia'**
  String get categoryEmergencyFund;

  /// No description provided for @categoryHealth.
  ///
  /// In es, this message translates to:
  /// **'Salud'**
  String get categoryHealth;

  /// No description provided for @categoryNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva categoría'**
  String get categoryNew;

  /// No description provided for @categoryEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar categoría'**
  String get categoryEdit;

  /// No description provided for @categoryNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get categoryNameLabel;

  /// No description provided for @categoryNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Mascotas'**
  String get categoryNameHint;

  /// No description provided for @categoryNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un nombre.'**
  String get categoryNameRequired;

  /// No description provided for @categoryIconLabel.
  ///
  /// In es, this message translates to:
  /// **'Ícono'**
  String get categoryIconLabel;

  /// No description provided for @categoryColorLabel.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get categoryColorLabel;

  /// No description provided for @categoryCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear categoría'**
  String get categoryCreate;

  /// No description provided for @categorySaveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get categorySaveChanges;

  /// No description provided for @categoryDefaultBadge.
  ///
  /// In es, this message translates to:
  /// **'Predeterminada'**
  String get categoryDefaultBadge;

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar categoría'**
  String get categoryDeleteTitle;

  /// Confirmation body when deleting a custom category; budgets cascade, transactions keep but lose the category
  ///
  /// In es, this message translates to:
  /// **'Se eliminará \"{name}\" y también sus presupuestos. Sus transacciones quedarán sin categoría.'**
  String categoryDeleteWarning(String name);

  /// No description provided for @categoriesLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar las categorías'**
  String get categoriesLoadFailed;

  /// No description provided for @categoriesOperationFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar la operación. Inténtalo de nuevo.'**
  String get categoriesOperationFailed;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get commonDelete;

  /// No description provided for @quickEntryWho.
  ///
  /// In es, this message translates to:
  /// **'¿Quién?'**
  String get quickEntryWho;

  /// No description provided for @quickEntryCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get quickEntryCategory;

  /// No description provided for @quickEntryNote.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get quickEntryNote;

  /// No description provided for @quickEntryNoteHint.
  ///
  /// In es, this message translates to:
  /// **'Descripción (ej. comercio)'**
  String get quickEntryNoteHint;

  /// No description provided for @quickEntryPriority.
  ///
  /// In es, this message translates to:
  /// **'Prioridad'**
  String get quickEntryPriority;

  /// No description provided for @quickEntrySave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get quickEntrySave;

  /// No description provided for @quickEntryScanReceipt.
  ///
  /// In es, this message translates to:
  /// **'Escanear recibo'**
  String get quickEntryScanReceipt;

  /// No description provided for @quickEntryScanningReceipt.
  ///
  /// In es, this message translates to:
  /// **'Leyendo recibo…'**
  String get quickEntryScanningReceipt;

  /// No description provided for @quickEntryTakePhoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar una foto'**
  String get quickEntryTakePhoto;

  /// No description provided for @quickEntryPickFromGallery.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get quickEntryPickFromGallery;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @settingsProfileFallback.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil'**
  String get settingsProfileFallback;

  /// No description provided for @settingsHouseholdNameCurrency.
  ///
  /// In es, this message translates to:
  /// **'Nombre y moneda'**
  String get settingsHouseholdNameCurrency;

  /// No description provided for @settingsNoHousehold.
  ///
  /// In es, this message translates to:
  /// **'Sin hogar'**
  String get settingsNoHousehold;

  /// No description provided for @settingsPartner.
  ///
  /// In es, this message translates to:
  /// **'Pareja'**
  String get settingsPartner;

  /// How many people belong to the household
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 miembro} other{{count} miembros}}'**
  String settingsMembersCount(int count);

  /// No description provided for @settingsNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsOn.
  ///
  /// In es, this message translates to:
  /// **'Activadas'**
  String get settingsNotificationsOn;

  /// No description provided for @settingsNotificationsOff.
  ///
  /// In es, this message translates to:
  /// **'Desactivadas'**
  String get settingsNotificationsOff;

  /// No description provided for @settingsCategories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get settingsCategories;

  /// No description provided for @settingsSubscription.
  ///
  /// In es, this message translates to:
  /// **'Suscripción'**
  String get settingsSubscription;

  /// No description provided for @settingsPremium.
  ///
  /// In es, this message translates to:
  /// **'Premium'**
  String get settingsPremium;

  /// No description provided for @settingsFree.
  ///
  /// In es, this message translates to:
  /// **'Gratis'**
  String get settingsFree;

  /// No description provided for @settingsLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// No description provided for @settingsSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settingsSignOut;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get settingsDeleteAccount;

  /// Follow the device language. Language names themselves are endonyms and identical across locales.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get languageSystem;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languagePortuguese.
  ///
  /// In es, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// No description provided for @transactionTypeIncome.
  ///
  /// In es, this message translates to:
  /// **'Ingreso'**
  String get transactionTypeIncome;

  /// No description provided for @transactionTypeExpense.
  ///
  /// In es, this message translates to:
  /// **'Gasto'**
  String get transactionTypeExpense;

  /// No description provided for @transactionTypeTransfer.
  ///
  /// In es, this message translates to:
  /// **'Transferencia'**
  String get transactionTypeTransfer;

  /// No description provided for @priorityNecessity.
  ///
  /// In es, this message translates to:
  /// **'Necesidad'**
  String get priorityNecessity;

  /// No description provided for @priorityLifestyle.
  ///
  /// In es, this message translates to:
  /// **'Estilo de Vida'**
  String get priorityLifestyle;

  /// No description provided for @priorityFuture.
  ///
  /// In es, this message translates to:
  /// **'Futuro'**
  String get priorityFuture;

  /// "Gasto hormiga": small, frequent, easy-to-miss purchases — the product's core concept
  ///
  /// In es, this message translates to:
  /// **'Hormiga'**
  String get priorityAnt;

  /// No description provided for @sourceManual.
  ///
  /// In es, this message translates to:
  /// **'Manual'**
  String get sourceManual;

  /// No description provided for @sourceBank.
  ///
  /// In es, this message translates to:
  /// **'Banco'**
  String get sourceBank;

  /// No description provided for @sourceImport.
  ///
  /// In es, this message translates to:
  /// **'Importado'**
  String get sourceImport;

  /// No description provided for @responsibleMe.
  ///
  /// In es, this message translates to:
  /// **'Tú'**
  String get responsibleMe;

  /// No description provided for @responsiblePartner.
  ///
  /// In es, this message translates to:
  /// **'Pareja'**
  String get responsiblePartner;

  /// No description provided for @responsibleShared.
  ///
  /// In es, this message translates to:
  /// **'Compartido'**
  String get responsibleShared;

  /// No description provided for @budgetStatusNormal.
  ///
  /// In es, this message translates to:
  /// **'En control'**
  String get budgetStatusNormal;

  /// No description provided for @budgetStatusWarning.
  ///
  /// In es, this message translates to:
  /// **'Cerca del límite'**
  String get budgetStatusWarning;

  /// No description provided for @budgetStatusExceeded.
  ///
  /// In es, this message translates to:
  /// **'Límite superado'**
  String get budgetStatusExceeded;

  /// No description provided for @budgetAlertsTitle.
  ///
  /// In es, this message translates to:
  /// **'Alertas de presupuesto'**
  String get budgetAlertsTitle;

  /// No description provided for @budgetAlertsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Te avisamos a ti y a tu pareja al cruzar el umbral.'**
  String get budgetAlertsSubtitle;

  /// No description provided for @budgetAlertThresholdLabel.
  ///
  /// In es, this message translates to:
  /// **'Avisar cuando quede'**
  String get budgetAlertThresholdLabel;

  /// In-app banner after an expense crosses the budget alert threshold
  ///
  /// In es, this message translates to:
  /// **'Ojo: llevas {percent}% de {category} este mes.'**
  String budgetAlertBanner(int percent, String category);

  /// Threshold banner fallback when the category cannot be resolved
  ///
  /// In es, this message translates to:
  /// **'Ojo: llevas {percent}% de un presupuesto este mes.'**
  String budgetAlertBannerGeneric(int percent);

  /// In-app banner when a budget reaches 100%
  ///
  /// In es, this message translates to:
  /// **'Alcanzaste el límite de {category} este mes.'**
  String budgetLimitReachedBanner(String category);

  /// No description provided for @budgetLimitReachedBannerGeneric.
  ///
  /// In es, this message translates to:
  /// **'Alcanzaste el límite de un presupuesto este mes.'**
  String get budgetLimitReachedBannerGeneric;

  /// No description provided for @goalStatusActive.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get goalStatusActive;

  /// No description provided for @goalStatusCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get goalStatusCompleted;

  /// No description provided for @goalStatusPaused.
  ///
  /// In es, this message translates to:
  /// **'En pausa'**
  String get goalStatusPaused;

  /// No description provided for @goalStatusArchived.
  ///
  /// In es, this message translates to:
  /// **'Archivada'**
  String get goalStatusArchived;

  /// No description provided for @subscriptionStatusActive.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get subscriptionStatusActive;

  /// No description provided for @subscriptionStatusTrial.
  ///
  /// In es, this message translates to:
  /// **'Prueba'**
  String get subscriptionStatusTrial;

  /// No description provided for @subscriptionStatusPaused.
  ///
  /// In es, this message translates to:
  /// **'En pausa'**
  String get subscriptionStatusPaused;

  /// No description provided for @subscriptionStatusCanceled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get subscriptionStatusCanceled;

  /// No description provided for @recurringReminderChannelName.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios de cobros'**
  String get recurringReminderChannelName;

  /// No description provided for @recurringReminderChannelDescription.
  ///
  /// In es, this message translates to:
  /// **'Avisos antes de un cobro recurrente'**
  String get recurringReminderChannelDescription;

  /// No description provided for @recurringReminderTitle.
  ///
  /// In es, this message translates to:
  /// **'Cobro próximo'**
  String get recurringReminderTitle;

  /// Local notification body reminding of an upcoming recurring charge
  ///
  /// In es, this message translates to:
  /// **'{name} se cobra pronto'**
  String recurringReminderBody(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
