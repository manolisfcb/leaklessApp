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

  /// No description provided for @navDashboard.
  ///
  /// In es, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

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

  /// No description provided for @settingsBudgets.
  ///
  /// In es, this message translates to:
  /// **'Presupuestos'**
  String get settingsBudgets;

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

  /// No description provided for @subscriptionFrequencyWeekly.
  ///
  /// In es, this message translates to:
  /// **'Semanal'**
  String get subscriptionFrequencyWeekly;

  /// No description provided for @subscriptionFrequencyMonthly.
  ///
  /// In es, this message translates to:
  /// **'Mensual'**
  String get subscriptionFrequencyMonthly;

  /// No description provided for @subscriptionFrequencyYearly.
  ///
  /// In es, this message translates to:
  /// **'Anual'**
  String get subscriptionFrequencyYearly;

  /// No description provided for @subscriptionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Gastos recurrentes'**
  String get subscriptionsTitle;

  /// No description provided for @subscriptionsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin gastos recurrentes'**
  String get subscriptionsEmptyTitle;

  /// No description provided for @subscriptionsEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Agrega tus suscripciones y cobros fijos para recordarlos a tiempo.'**
  String get subscriptionsEmptyMessage;

  /// No description provided for @subscriptionsLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar los gastos recurrentes'**
  String get subscriptionsLoadFailed;

  /// No description provided for @subscriptionsOperationFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar la operación. Inténtalo de nuevo.'**
  String get subscriptionsOperationFailed;

  /// No description provided for @subscriptionNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo gasto recurrente'**
  String get subscriptionNew;

  /// No description provided for @subscriptionEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar gasto recurrente'**
  String get subscriptionEdit;

  /// No description provided for @subscriptionCreate.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get subscriptionCreate;

  /// No description provided for @subscriptionSaveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get subscriptionSaveChanges;

  /// No description provided for @subscriptionNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get subscriptionNameLabel;

  /// No description provided for @subscriptionNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Netflix'**
  String get subscriptionNameHint;

  /// No description provided for @subscriptionNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un nombre.'**
  String get subscriptionNameRequired;

  /// No description provided for @subscriptionAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get subscriptionAmountLabel;

  /// No description provided for @subscriptionAmountRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un monto mayor que cero.'**
  String get subscriptionAmountRequired;

  /// No description provided for @subscriptionFrequencyLabel.
  ///
  /// In es, this message translates to:
  /// **'Frecuencia'**
  String get subscriptionFrequencyLabel;

  /// No description provided for @subscriptionNextChargeLabel.
  ///
  /// In es, this message translates to:
  /// **'Próximo cobro'**
  String get subscriptionNextChargeLabel;

  /// No description provided for @subscriptionNextChargeNone.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha'**
  String get subscriptionNextChargeNone;

  /// No description provided for @subscriptionNextChargeClear.
  ///
  /// In es, this message translates to:
  /// **'Quitar fecha'**
  String get subscriptionNextChargeClear;

  /// No description provided for @subscriptionCategoryLabel.
  ///
  /// In es, this message translates to:
  /// **'Categoría (opcional)'**
  String get subscriptionCategoryLabel;

  /// No description provided for @subscriptionReminderTitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio'**
  String get subscriptionReminderTitle;

  /// No description provided for @subscriptionReminderSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Te avisamos antes del cobro.'**
  String get subscriptionReminderSubtitle;

  /// No description provided for @subscriptionReminderDaysLabel.
  ///
  /// In es, this message translates to:
  /// **'Avisar antes'**
  String get subscriptionReminderDaysLabel;

  /// How many days before the charge the local reminder fires
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{El mismo día} =1{1 día} other{{count} días}}'**
  String subscriptionReminderDays(int count);

  /// No description provided for @subscriptionDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar gasto recurrente'**
  String get subscriptionDeleteTitle;

  /// Confirmation body when deleting a recurring subscription
  ///
  /// In es, this message translates to:
  /// **'Se eliminará \"{name}\" y su recordatorio.'**
  String subscriptionDeleteWarning(String name);

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

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// No description provided for @commonSaveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get commonSaveChanges;

  /// No description provided for @commonSignInToContinue.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para continuar.'**
  String get commonSignInToContinue;

  /// No description provided for @commonCheckConnection.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get commonCheckConnection;

  /// No description provided for @commonInvalidNameMax80.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre válido de hasta 80 caracteres.'**
  String get commonInvalidNameMax80;

  /// No description provided for @commonInvalidCurrency.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una moneda válida.'**
  String get commonInvalidCurrency;

  /// No description provided for @commonInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo no válido.'**
  String get commonInvalidEmail;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Restablecer contraseña'**
  String get authResetPasswordTitle;

  /// No description provided for @authSignUpConfirmEmailInfo.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un correo para confirmar tu cuenta. Ábrelo y vuelve para iniciar sesión.'**
  String get authSignUpConfirmEmailInfo;

  /// No description provided for @authResetLinkSentInfo.
  ///
  /// In es, this message translates to:
  /// **'Si el correo está registrado, te enviamos un enlace para restablecer tu contraseña.'**
  String get authResetLinkSentInfo;

  /// No description provided for @authCreateAccountTitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta'**
  String get authCreateAccountTitle;

  /// No description provided for @authReviewInvitationTitle.
  ///
  /// In es, this message translates to:
  /// **'Entra para revisar tu invitación'**
  String get authReviewInvitationTitle;

  /// No description provided for @authWelcomeBackTitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido de vuelta'**
  String get authWelcomeBackTitle;

  /// No description provided for @authPendingInvitationHint.
  ///
  /// In es, this message translates to:
  /// **'Usa el correo al que enviaron la invitación. Continuaremos automáticamente al entrar.'**
  String get authPendingInvitationHint;

  /// No description provided for @authNameHint.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre'**
  String get authNameHint;

  /// No description provided for @authEmailHint.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get authEmailHint;

  /// No description provided for @authPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authPasswordHint;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get authConfirmPasswordHint;

  /// No description provided for @authForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get authForgotPassword;

  /// No description provided for @authCreateAccountCta.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get authCreateAccountCta;

  /// No description provided for @authSignInCta.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get authSignInCta;

  /// No description provided for @authToggleToSignIn.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Inicia sesión'**
  String get authToggleToSignIn;

  /// No description provided for @authToggleToSignUp.
  ///
  /// In es, this message translates to:
  /// **'¿Sin cuenta? Regístrate'**
  String get authToggleToSignUp;

  /// No description provided for @authNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu nombre.'**
  String get authNameRequired;

  /// No description provided for @authEmailRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu correo.'**
  String get authEmailRequired;

  /// No description provided for @authPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu contraseña.'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres.'**
  String get authPasswordTooShort;

  /// No description provided for @authPasswordsDontMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden.'**
  String get authPasswordsDontMatch;

  /// No description provided for @authForgotPasswordBody.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu correo y te enviaremos un enlace para crear una nueva contraseña.'**
  String get authForgotPasswordBody;

  /// No description provided for @authSendLink.
  ///
  /// In es, this message translates to:
  /// **'Enviar enlace'**
  String get authSendLink;

  /// No description provided for @resetPasswordUpdated.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada.'**
  String get resetPasswordUpdated;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Crea una nueva contraseña'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordBody.
  ///
  /// In es, this message translates to:
  /// **'Elige una contraseña nueva para tu cuenta. Al guardarla entrarás automáticamente.'**
  String get resetPasswordBody;

  /// No description provided for @resetPasswordNewLabel.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get resetPasswordNewLabel;

  /// No description provided for @resetPasswordNewRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu nueva contraseña.'**
  String get resetPasswordNewRequired;

  /// No description provided for @resetPasswordSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar contraseña'**
  String get resetPasswordSave;

  /// No description provided for @onboardingSlide1Title.
  ///
  /// In es, this message translates to:
  /// **'Detecta las fugas de dinero'**
  String get onboardingSlide1Title;

  /// No description provided for @onboardingSlide1Body.
  ///
  /// In es, this message translates to:
  /// **'Esos pequeños gastos hormiga que se escapan sin darte cuenta. leakless los hace visibles para que recuperes el control.'**
  String get onboardingSlide1Body;

  /// No description provided for @onboardingSlide2Title.
  ///
  /// In es, this message translates to:
  /// **'Controlen los gastos en pareja'**
  String get onboardingSlide2Title;

  /// No description provided for @onboardingSlide2Body.
  ///
  /// In es, this message translates to:
  /// **'Un libro de cuentas compartido y en tiempo real. Si uno gasta, ambos lo saben al instante.'**
  String get onboardingSlide2Body;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In es, this message translates to:
  /// **'Ahorren juntos con metas claras'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Body.
  ///
  /// In es, this message translates to:
  /// **'Definan metas, vean el progreso líquido llenarse y celebren cada aporte hacia el futuro que quieren.'**
  String get onboardingSlide3Body;

  /// No description provided for @onboardingSkip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get onboardingSkip;

  /// No description provided for @onboardingStart.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get onboardingStart;

  /// No description provided for @onboardingNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get onboardingNext;

  /// No description provided for @householdSetupPartnerEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Escribe un correo válido para tu pareja.'**
  String get householdSetupPartnerEmailInvalid;

  /// Shown when the household saved but the partner invitation could not be created
  ///
  /// In es, this message translates to:
  /// **'Guardamos el hogar, pero no pudimos crear la invitación. {error}'**
  String householdSetupInvitationFailed(String error);

  /// No description provided for @householdSetupTitle.
  ///
  /// In es, this message translates to:
  /// **'Configurar hogar'**
  String get householdSetupTitle;

  /// No description provided for @householdSetupPreparing.
  ///
  /// In es, this message translates to:
  /// **'Preparando tu hogar…'**
  String get householdSetupPreparing;

  /// No description provided for @householdSetupLoadErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu hogar'**
  String get householdSetupLoadErrorTitle;

  /// No description provided for @householdSetupNoHouseholdTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta aún no tiene hogar'**
  String get householdSetupNoHouseholdTitle;

  /// No description provided for @householdSetupNoHouseholdMessage.
  ///
  /// In es, this message translates to:
  /// **'No mostraremos datos financieros hasta recuperar un hogar válido.'**
  String get householdSetupNoHouseholdMessage;

  /// No description provided for @householdSetupWaitingOwnerTitle.
  ///
  /// In es, this message translates to:
  /// **'Esperando al owner'**
  String get householdSetupWaitingOwnerTitle;

  /// No description provided for @householdSetupWaitingOwnerMessage.
  ///
  /// In es, this message translates to:
  /// **'Quien creó este hogar debe completar el nombre y la moneda. Actualizaremos este estado cuando termine.'**
  String get householdSetupWaitingOwnerMessage;

  /// No description provided for @householdSetupHeroTitle.
  ///
  /// In es, this message translates to:
  /// **'Hagamos suyo este hogar'**
  String get householdSetupHeroTitle;

  /// No description provided for @householdSetupHeroSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Configura la base compartida. Podrás ajustarla más tarde.'**
  String get householdSetupHeroSubtitle;

  /// No description provided for @householdNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del hogar'**
  String get householdNameLabel;

  /// No description provided for @householdNameHint.
  ///
  /// In es, this message translates to:
  /// **'Nuestra casa'**
  String get householdNameHint;

  /// No description provided for @householdNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre para el hogar.'**
  String get householdNameRequired;

  /// No description provided for @householdCurrencyLabel.
  ///
  /// In es, this message translates to:
  /// **'Moneda principal'**
  String get householdCurrencyLabel;

  /// No description provided for @householdCurrencyNote.
  ///
  /// In es, this message translates to:
  /// **'La moneda sólo puede cambiar mientras el hogar no tenga importes guardados.'**
  String get householdCurrencyNote;

  /// No description provided for @householdSetupStep2Title.
  ///
  /// In es, this message translates to:
  /// **'Categorías iniciales'**
  String get householdSetupStep2Title;

  /// No description provided for @householdSetupStep2Subtitle.
  ///
  /// In es, this message translates to:
  /// **'Estas categorías ya están listas para registrar gastos.'**
  String get householdSetupStep2Subtitle;

  /// No description provided for @householdSetupStep3Title.
  ///
  /// In es, this message translates to:
  /// **'Tu pareja'**
  String get householdSetupStep3Title;

  /// No description provided for @householdSetupStep3Subtitle.
  ///
  /// In es, this message translates to:
  /// **'La invitación es opcional. Podrás retomarla desde Ajustes.'**
  String get householdSetupStep3Subtitle;

  /// No description provided for @householdPartnerEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo de tu pareja'**
  String get householdPartnerEmailLabel;

  /// No description provided for @householdPartnerEmailHint.
  ///
  /// In es, this message translates to:
  /// **'pareja@correo.com'**
  String get householdPartnerEmailHint;

  /// No description provided for @householdSetupSaveAndInvite.
  ///
  /// In es, this message translates to:
  /// **'Guardar e invitar'**
  String get householdSetupSaveAndInvite;

  /// No description provided for @householdSetupContinueWithoutInvite.
  ///
  /// In es, this message translates to:
  /// **'Continuar sin invitar'**
  String get householdSetupContinueWithoutInvite;

  /// No description provided for @categoriesReviewLoadError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar las categorías. Reintenta antes de continuar.'**
  String get categoriesReviewLoadError;

  /// No description provided for @categoriesReviewEmpty.
  ///
  /// In es, this message translates to:
  /// **'No encontramos categorías iniciales.'**
  String get categoriesReviewEmpty;

  /// No description provided for @householdSetupErrorNotOwner.
  ///
  /// In es, this message translates to:
  /// **'Sólo quien creó este hogar puede configurarlo.'**
  String get householdSetupErrorNotOwner;

  /// No description provided for @householdSetupErrorCurrencyLocked.
  ///
  /// In es, this message translates to:
  /// **'Este hogar ya tiene importes. Cambiar la moneda podría reinterpretarlos, así que conservamos la moneda actual.'**
  String get householdSetupErrorCurrencyLocked;

  /// No description provided for @householdSetupErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar el hogar. Inténtalo de nuevo.'**
  String get householdSetupErrorGeneric;

  /// No description provided for @invitationShareSubject.
  ///
  /// In es, this message translates to:
  /// **'Invitación a nuestro hogar en leakless'**
  String get invitationShareSubject;

  /// Share-sheet body when inviting a partner
  ///
  /// In es, this message translates to:
  /// **'Únete a nuestro hogar en leakless.\n\n{link}\n\nSi el enlace no abre, pega este código:\n{code}'**
  String invitationShareText(String link, String code);

  /// No description provided for @invitationShareFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir el menú para compartir.'**
  String get invitationShareFailed;

  /// No description provided for @invitationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Invitar a tu pareja'**
  String get invitationsTitle;

  /// No description provided for @invitationsNoHousehold.
  ///
  /// In es, this message translates to:
  /// **'No encontramos un hogar activo para invitar.'**
  String get invitationsNoHousehold;

  /// No description provided for @invitationsNotOwner.
  ///
  /// In es, this message translates to:
  /// **'Sólo quien creó este hogar puede enviar invitaciones.'**
  String get invitationsNotOwner;

  /// No description provided for @invitationEmailRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe su correo.'**
  String get invitationEmailRequired;

  /// No description provided for @invitationCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear invitación'**
  String get invitationCreate;

  /// No description provided for @invitationLinkCopied.
  ///
  /// In es, this message translates to:
  /// **'Enlace copiado.'**
  String get invitationLinkCopied;

  /// No description provided for @invitationCodeCopied.
  ///
  /// In es, this message translates to:
  /// **'Código copiado.'**
  String get invitationCodeCopied;

  /// No description provided for @invitationHaveCode.
  ///
  /// In es, this message translates to:
  /// **'Tengo un código de invitación'**
  String get invitationHaveCode;

  /// No description provided for @invitationsIntroTitleFallback.
  ///
  /// In es, this message translates to:
  /// **'Compartir el hogar'**
  String get invitationsIntroTitleFallback;

  /// No description provided for @invitationsIntroSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Genera un enlace de un solo uso. Sólo funcionará con el correo que indiques.'**
  String get invitationsIntroSubtitle;

  /// When a shared invitation expires
  ///
  /// In es, this message translates to:
  /// **'Vence el {date}'**
  String invitationExpiresOn(String date);

  /// No description provided for @invitationTitle.
  ///
  /// In es, this message translates to:
  /// **'Invitación'**
  String get invitationTitle;

  /// No description provided for @invitationShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir invitación'**
  String get invitationShare;

  /// No description provided for @invitationCopyLink.
  ///
  /// In es, this message translates to:
  /// **'Copiar enlace'**
  String get invitationCopyLink;

  /// No description provided for @invitationCopyCode.
  ///
  /// In es, this message translates to:
  /// **'Copiar código'**
  String get invitationCopyCode;

  /// No description provided for @invitationRevoke.
  ///
  /// In es, this message translates to:
  /// **'Revocar invitación'**
  String get invitationRevoke;

  /// No description provided for @invitationNoLongerShareable.
  ///
  /// In es, this message translates to:
  /// **'Este código ya no se puede compartir.'**
  String get invitationNoLongerShareable;

  /// No description provided for @invitationStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get invitationStatusPending;

  /// No description provided for @invitationStatusAccepted.
  ///
  /// In es, this message translates to:
  /// **'Aceptada'**
  String get invitationStatusAccepted;

  /// No description provided for @invitationStatusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Revocada'**
  String get invitationStatusCancelled;

  /// No description provided for @invitationStatusExpired.
  ///
  /// In es, this message translates to:
  /// **'Vencida'**
  String get invitationStatusExpired;

  /// No description provided for @invitationCodeInvalidFormat.
  ///
  /// In es, this message translates to:
  /// **'El código debe tener 64 caracteres hexadecimales.'**
  String get invitationCodeInvalidFormat;

  /// No description provided for @invitationExpiredMessage.
  ///
  /// In es, this message translates to:
  /// **'La invitación ha vencido.'**
  String get invitationExpiredMessage;

  /// No description provided for @invitationCancelledMessage.
  ///
  /// In es, this message translates to:
  /// **'La invitación fue revocada.'**
  String get invitationCancelledMessage;

  /// No description provided for @invitationAlreadyUsedMessage.
  ///
  /// In es, this message translates to:
  /// **'Esta invitación ya fue utilizada.'**
  String get invitationAlreadyUsedMessage;

  /// No description provided for @invitationPersistenceFailed.
  ///
  /// In es, this message translates to:
  /// **'Mantén la app abierta: no pudimos guardar el intento de forma segura.'**
  String get invitationPersistenceFailed;

  /// No description provided for @invitationOpenFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir esta invitación.'**
  String get invitationOpenFailed;

  /// No description provided for @invitationSuccessHeroTitle.
  ///
  /// In es, this message translates to:
  /// **'Ya están conectados'**
  String get invitationSuccessHeroTitle;

  /// No description provided for @invitationHeroTitle.
  ///
  /// In es, this message translates to:
  /// **'Un hogar, entre dos'**
  String get invitationHeroTitle;

  /// No description provided for @invitationPasteCodeTitle.
  ///
  /// In es, this message translates to:
  /// **'Pega tu código'**
  String get invitationPasteCodeTitle;

  /// No description provided for @invitationPasteCodeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Puedes abrir el enlace o pegar aquí el código que te compartieron.'**
  String get invitationPasteCodeSubtitle;

  /// No description provided for @invitationCodeFieldHint.
  ///
  /// In es, this message translates to:
  /// **'Código de 64 caracteres'**
  String get invitationCodeFieldHint;

  /// No description provided for @invitationReview.
  ///
  /// In es, this message translates to:
  /// **'Revisar invitación'**
  String get invitationReview;

  /// No description provided for @invitationHouseholdFallback.
  ///
  /// In es, this message translates to:
  /// **'Hogar compartido'**
  String get invitationHouseholdFallback;

  /// Preview subtitle naming who sent the invitation
  ///
  /// In es, this message translates to:
  /// **'{inviter} te invitó a compartir este hogar.'**
  String invitationInviterInvited(String inviter);

  /// No description provided for @invitationInviterFallback.
  ///
  /// In es, this message translates to:
  /// **'Tu pareja'**
  String get invitationInviterFallback;

  /// Invitation validity deadline in the recipient preview
  ///
  /// In es, this message translates to:
  /// **'Válida hasta {date}'**
  String invitationValidUntil(String date);

  /// No description provided for @invitationAcceptJoin.
  ///
  /// In es, this message translates to:
  /// **'Aceptar y unirme'**
  String get invitationAcceptJoin;

  /// No description provided for @invitationNotNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get invitationNotNow;

  /// No description provided for @invitationUseAnotherAccount.
  ///
  /// In es, this message translates to:
  /// **'Usar otra cuenta'**
  String get invitationUseAnotherAccount;

  /// No description provided for @invitationDiscard.
  ///
  /// In es, this message translates to:
  /// **'Descartar invitación'**
  String get invitationDiscard;

  /// No description provided for @invitationAlreadyMember.
  ///
  /// In es, this message translates to:
  /// **'Ya pertenecías a este hogar.'**
  String get invitationAlreadyMember;

  /// No description provided for @invitationAcceptedSuccess.
  ///
  /// In es, this message translates to:
  /// **'La invitación fue aceptada. Ya pueden ver sus finanzas compartidas.'**
  String get invitationAcceptedSuccess;

  /// No description provided for @invitationGoHome.
  ///
  /// In es, this message translates to:
  /// **'Ir al inicio'**
  String get invitationGoHome;

  /// No description provided for @profileImageTooLarge.
  ///
  /// In es, this message translates to:
  /// **'La imagen es demasiado grande. Prueba con otra.'**
  String get profileImageTooLarge;

  /// No description provided for @profileUpdated.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado.'**
  String get profileUpdated;

  /// No description provided for @profileChangeAvatarTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar avatar'**
  String get profileChangeAvatarTitle;

  /// No description provided for @profileEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get profileEditTitle;

  /// No description provided for @profileLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando tu perfil…'**
  String get profileLoading;

  /// No description provided for @profileLoadErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu perfil'**
  String get profileLoadErrorTitle;

  /// No description provided for @profileNoProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin perfil'**
  String get profileNoProfileTitle;

  /// No description provided for @profileNoProfileMessage.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión de nuevo para editar tu perfil.'**
  String get profileNoProfileMessage;

  /// No description provided for @profileNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre visible'**
  String get profileNameLabel;

  /// No description provided for @profileNameHint.
  ///
  /// In es, this message translates to:
  /// **'Cómo te ve tu pareja'**
  String get profileNameHint;

  /// No description provided for @profileNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre visible.'**
  String get profileNameRequired;

  /// No description provided for @profileCurrencyLabel.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get profileCurrencyLabel;

  /// No description provided for @profileAvatarFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos usar esa imagen. Inténtalo de nuevo.'**
  String get profileAvatarFailed;

  /// No description provided for @profileErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar los cambios. Inténtalo de nuevo.'**
  String get profileErrorGeneric;

  /// No description provided for @pickerErrorPhotoAccessDenied.
  ///
  /// In es, this message translates to:
  /// **'Permite el acceso a tus fotos desde Ajustes para elegir un avatar.'**
  String get pickerErrorPhotoAccessDenied;

  /// No description provided for @pickerErrorCameraAccessDenied.
  ///
  /// In es, this message translates to:
  /// **'Permite el acceso a la cámara desde Ajustes para tomar una foto.'**
  String get pickerErrorCameraAccessDenied;

  /// No description provided for @pickerErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir el selector de imágenes. Inténtalo de nuevo.'**
  String get pickerErrorGeneric;

  /// No description provided for @dashboardLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando tu panel…'**
  String get dashboardLoading;

  /// No description provided for @dashboardLoadErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar el panel'**
  String get dashboardLoadErrorTitle;

  /// No description provided for @dashboardLoadErrorMessage.
  ///
  /// In es, this message translates to:
  /// **'Inténtalo de nuevo en un momento.'**
  String get dashboardLoadErrorMessage;

  /// No description provided for @dashboardAvailableBalance.
  ///
  /// In es, this message translates to:
  /// **'Balance disponible'**
  String get dashboardAvailableBalance;

  /// No description provided for @dashboardRecentActivity.
  ///
  /// In es, this message translates to:
  /// **'Actividad reciente'**
  String get dashboardRecentActivity;

  /// No description provided for @dashboardSeeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todo'**
  String get dashboardSeeAll;

  /// No description provided for @dashboardSavingsRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa de ahorro real'**
  String get dashboardSavingsRate;

  /// No description provided for @dashboardRecurringExpenses.
  ///
  /// In es, this message translates to:
  /// **'Gastos recurrentes'**
  String get dashboardRecurringExpenses;

  /// No description provided for @dashboardLimitAlerts.
  ///
  /// In es, this message translates to:
  /// **'Alertas de límites'**
  String get dashboardLimitAlerts;

  /// No description provided for @dashboardSavingsRateShort.
  ///
  /// In es, this message translates to:
  /// **'tasa de ahorro'**
  String get dashboardSavingsRateShort;

  /// Amber chip over the hydrometer showing the month's leak amount
  ///
  /// In es, this message translates to:
  /// **'Fuga {amount}'**
  String dashboardLeak(String amount);

  /// No description provided for @transactionsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar el historial'**
  String get transactionsLoadError;

  /// No description provided for @transactionsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin movimientos'**
  String get transactionsEmptyTitle;

  /// No description provided for @transactionsEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Ajusta los filtros o registra tu primer gasto.'**
  String get transactionsEmptyMessage;

  /// No description provided for @transactionsFilterUncategorized.
  ///
  /// In es, this message translates to:
  /// **'Sin categorizar'**
  String get transactionsFilterUncategorized;

  /// No description provided for @transactionFallbackTitle.
  ///
  /// In es, this message translates to:
  /// **'Movimiento'**
  String get transactionFallbackTitle;

  /// No description provided for @errorAuthSession.
  ///
  /// In es, this message translates to:
  /// **'No pudimos verificar tu sesión.'**
  String get errorAuthSession;

  /// No description provided for @errorNetwork.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión a internet.'**
  String get errorNetwork;

  /// No description provided for @errorNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos lo que buscabas.'**
  String get errorNotFound;

  /// No description provided for @errorServer.
  ///
  /// In es, this message translates to:
  /// **'Algo falló en el servidor. Inténtalo de nuevo.'**
  String get errorServer;

  /// No description provided for @errorUnexpected.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error inesperado.'**
  String get errorUnexpected;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailNotConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu correo antes de iniciar sesión. Revisa tu bandeja de entrada.'**
  String get authErrorEmailNotConfirmed;

  /// No description provided for @authErrorEmailExists.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una cuenta con este correo. Inicia sesión.'**
  String get authErrorEmailExists;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es muy débil. Usa al menos 6 caracteres.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorSamePassword.
  ///
  /// In es, this message translates to:
  /// **'La nueva contraseña debe ser distinta a la anterior.'**
  String get authErrorSamePassword;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'El correo no es válido.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorSignupDisabled.
  ///
  /// In es, this message translates to:
  /// **'El registro está deshabilitado por ahora.'**
  String get authErrorSignupDisabled;

  /// No description provided for @authErrorRateLimit.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Espera un momento e inténtalo de nuevo.'**
  String get authErrorRateLimit;

  /// No description provided for @authErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar la operación. Inténtalo de nuevo.'**
  String get authErrorGeneric;

  /// No description provided for @authErrorUnexpected.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error inesperado. Inténtalo de nuevo.'**
  String get authErrorUnexpected;

  /// No description provided for @invitationErrorInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Escribe un correo válido.'**
  String get invitationErrorInvalidEmail;

  /// No description provided for @invitationErrorInvalidExpiry.
  ///
  /// In es, this message translates to:
  /// **'La duración de la invitación no es válida.'**
  String get invitationErrorInvalidExpiry;

  /// No description provided for @invitationErrorCannotInviteSelf.
  ///
  /// In es, this message translates to:
  /// **'No puedes invitar tu propio correo.'**
  String get invitationErrorCannotInviteSelf;

  /// No description provided for @invitationErrorNotOwner.
  ///
  /// In es, this message translates to:
  /// **'Sólo quien creó este hogar puede invitar.'**
  String get invitationErrorNotOwner;

  /// No description provided for @invitationErrorAlreadyMember.
  ///
  /// In es, this message translates to:
  /// **'Esa persona ya pertenece a este hogar.'**
  String get invitationErrorAlreadyMember;

  /// No description provided for @invitationErrorInvalidToken.
  ///
  /// In es, this message translates to:
  /// **'El enlace o código de invitación no es válido.'**
  String get invitationErrorInvalidToken;

  /// No description provided for @invitationErrorEmailMismatch.
  ///
  /// In es, this message translates to:
  /// **'Esta invitación fue enviada a otro correo. Usa esa cuenta para continuar.'**
  String get invitationErrorEmailMismatch;

  /// No description provided for @invitationErrorNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos esta invitación.'**
  String get invitationErrorNotFound;

  /// No description provided for @invitationErrorAcceptedCannotCancel.
  ///
  /// In es, this message translates to:
  /// **'Una invitación aceptada ya no se puede revocar.'**
  String get invitationErrorAcceptedCannotCancel;

  /// No description provided for @invitationErrorHouseholdNotEmpty.
  ///
  /// In es, this message translates to:
  /// **'Tu hogar actual contiene datos. No podemos moverlos automáticamente.'**
  String get invitationErrorHouseholdNotEmpty;

  /// No description provided for @invitationErrorProfileNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos tu perfil. Inténtalo de nuevo.'**
  String get invitationErrorProfileNotFound;

  /// No description provided for @invitationErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar la invitación. Inténtalo de nuevo.'**
  String get invitationErrorGeneric;

  /// No description provided for @currencyCAD.
  ///
  /// In es, this message translates to:
  /// **'Dólar canadiense'**
  String get currencyCAD;

  /// No description provided for @currencyUSD.
  ///
  /// In es, this message translates to:
  /// **'Dólar estadounidense'**
  String get currencyUSD;

  /// No description provided for @currencyEUR.
  ///
  /// In es, this message translates to:
  /// **'Euro'**
  String get currencyEUR;

  /// No description provided for @currencyMXN.
  ///
  /// In es, this message translates to:
  /// **'Peso mexicano'**
  String get currencyMXN;

  /// No description provided for @currencyCOP.
  ///
  /// In es, this message translates to:
  /// **'Peso colombiano'**
  String get currencyCOP;

  /// No description provided for @currencyARS.
  ///
  /// In es, this message translates to:
  /// **'Peso argentino'**
  String get currencyARS;

  /// No description provided for @currencyCLP.
  ///
  /// In es, this message translates to:
  /// **'Peso chileno'**
  String get currencyCLP;

  /// No description provided for @currencyPEN.
  ///
  /// In es, this message translates to:
  /// **'Sol peruano'**
  String get currencyPEN;

  /// No description provided for @currencyBRL.
  ///
  /// In es, this message translates to:
  /// **'Real brasileño'**
  String get currencyBRL;

  /// No description provided for @currencyGBP.
  ///
  /// In es, this message translates to:
  /// **'Libra esterlina'**
  String get currencyGBP;

  /// No description provided for @currencyJPY.
  ///
  /// In es, this message translates to:
  /// **'Yen japonés'**
  String get currencyJPY;

  /// No description provided for @currencyCHF.
  ///
  /// In es, this message translates to:
  /// **'Franco suizo'**
  String get currencyCHF;

  /// No description provided for @insightsTitle.
  ///
  /// In es, this message translates to:
  /// **'Dashboard'**
  String get insightsTitle;

  /// No description provided for @insightsLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando tus estadísticas…'**
  String get insightsLoading;

  /// No description provided for @insightsErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus estadísticas'**
  String get insightsErrorTitle;

  /// No description provided for @insightsErrorMessage.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get insightsErrorMessage;

  /// No description provided for @insightsRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get insightsRetry;

  /// No description provided for @insightsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay gastos'**
  String get insightsEmptyTitle;

  /// No description provided for @insightsEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Registra tu primer gasto para ver tus estadísticas del mes.'**
  String get insightsEmptyMessage;

  /// No description provided for @insightsEmptyAction.
  ///
  /// In es, this message translates to:
  /// **'Registrar un gasto'**
  String get insightsEmptyAction;

  /// No description provided for @insightsMonthSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen del mes'**
  String get insightsMonthSummaryTitle;

  /// No description provided for @insightsSpentLabel.
  ///
  /// In es, this message translates to:
  /// **'Gastado este mes'**
  String get insightsSpentLabel;

  /// Shows the total monthly budget next to what has been spent
  ///
  /// In es, this message translates to:
  /// **'de {budget}'**
  String insightsOfBudget(String budget);

  /// Percentage of the total monthly budget consumed
  ///
  /// In es, this message translates to:
  /// **'{percent}% usado'**
  String insightsBudgetUsed(int percent);

  /// Remaining amount of the monthly budget
  ///
  /// In es, this message translates to:
  /// **'Te queda {amount}'**
  String insightsRemaining(String amount);

  /// How much the month is over its total budget
  ///
  /// In es, this message translates to:
  /// **'Te pasaste por {amount}'**
  String insightsOverBudgetBy(String amount);

  /// No description provided for @insightsNoBudgetNote.
  ///
  /// In es, this message translates to:
  /// **'Aún no defines un presupuesto este mes. Crea uno para seguir tu ritmo.'**
  String get insightsNoBudgetNote;

  /// No description provided for @insightsCreateBudget.
  ///
  /// In es, this message translates to:
  /// **'Crear presupuesto'**
  String get insightsCreateBudget;

  /// No description provided for @insightsStatusOnTrack.
  ///
  /// In es, this message translates to:
  /// **'Vas al día con tu presupuesto.'**
  String get insightsStatusOnTrack;

  /// No description provided for @insightsStatusAhead.
  ///
  /// In es, this message translates to:
  /// **'Vas por debajo del ritmo previsto. ¡Bien!'**
  String get insightsStatusAhead;

  /// No description provided for @insightsStatusAtRisk.
  ///
  /// In es, this message translates to:
  /// **'Estás gastando más rápido de lo previsto.'**
  String get insightsStatusAtRisk;

  /// No description provided for @insightsStatusOver.
  ///
  /// In es, this message translates to:
  /// **'Superaste tu presupuesto del mes.'**
  String get insightsStatusOver;

  /// No description provided for @insightsPaceTitle.
  ///
  /// In es, this message translates to:
  /// **'Ritmo de gasto'**
  String get insightsPaceTitle;

  /// No description provided for @insightsPaceExpected.
  ///
  /// In es, this message translates to:
  /// **'Esperado a hoy'**
  String get insightsPaceExpected;

  /// No description provided for @insightsPaceActual.
  ///
  /// In es, this message translates to:
  /// **'Gastado a hoy'**
  String get insightsPaceActual;

  /// The month is spending below the linear budget pace
  ///
  /// In es, this message translates to:
  /// **'Vas {amount} por debajo del ritmo.'**
  String insightsPaceAhead(String amount);

  /// The month is spending above the linear budget pace
  ///
  /// In es, this message translates to:
  /// **'Vas {amount} por encima del ritmo.'**
  String insightsPaceBehind(String amount);

  /// No description provided for @insightsPaceOnPace.
  ///
  /// In es, this message translates to:
  /// **'Justo en el ritmo previsto.'**
  String get insightsPaceOnPace;

  /// Amount to trim to close the month within budget
  ///
  /// In es, this message translates to:
  /// **'Reduce {amount} para cerrar dentro del presupuesto.'**
  String insightsPaceReduce(String amount);

  /// No description provided for @insightsCategoriesTitle.
  ///
  /// In es, this message translates to:
  /// **'Gasto por categoría'**
  String get insightsCategoriesTitle;

  /// A category's share of the month's total spend
  ///
  /// In es, this message translates to:
  /// **'{percent}% del total'**
  String insightsCategoryShare(int percent);

  /// No description provided for @insightsCategoryUnnamed.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get insightsCategoryUnnamed;

  /// No description provided for @insightsRunawayTitle.
  ///
  /// In es, this message translates to:
  /// **'Categorías fuera de control'**
  String get insightsRunawayTitle;

  /// Badge showing how far a category is over its recent average
  ///
  /// In es, this message translates to:
  /// **'+{percent}%'**
  String insightsRunawayBadge(int percent);

  /// The category's recent average spend shown for comparison
  ///
  /// In es, this message translates to:
  /// **'Promedio de 3 meses: {average}'**
  String insightsRunawayCompare(String average);

  /// No description provided for @insightsTrendTitle.
  ///
  /// In es, this message translates to:
  /// **'Comparativo histórico'**
  String get insightsTrendTitle;

  /// No description provided for @insightsTrendVsPreviousLabel.
  ///
  /// In es, this message translates to:
  /// **'Mes anterior'**
  String get insightsTrendVsPreviousLabel;

  /// No description provided for @insightsTrendVsAverageLabel.
  ///
  /// In es, this message translates to:
  /// **'Promedio 3 meses'**
  String get insightsTrendVsAverageLabel;

  /// Spend increased by this percentage vs the comparison point
  ///
  /// In es, this message translates to:
  /// **'{percent}% más'**
  String insightsTrendChangeUp(int percent);

  /// Spend decreased by this percentage vs the comparison point
  ///
  /// In es, this message translates to:
  /// **'{percent}% menos'**
  String insightsTrendChangeDown(int percent);

  /// No description provided for @insightsTrendChangeStable.
  ///
  /// In es, this message translates to:
  /// **'Similar'**
  String get insightsTrendChangeStable;

  /// No description provided for @insightsTrendNoPreviousMonth.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay datos del mes anterior.'**
  String get insightsTrendNoPreviousMonth;

  /// No description provided for @insightsProjectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Proyección de cierre'**
  String get insightsProjectionTitle;

  /// No description provided for @insightsProjectionInsufficientData.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos unos días más de este mes para poder proyectar tu cierre.'**
  String get insightsProjectionInsufficientData;

  /// No description provided for @insightsProjectionLabel.
  ///
  /// In es, this message translates to:
  /// **'Estimado a fin de mes'**
  String get insightsProjectionLabel;

  /// Projected amount over the total monthly budget
  ///
  /// In es, this message translates to:
  /// **'Superarías tu presupuesto por {amount}.'**
  String insightsProjectionOverBudget(String amount);

  /// No description provided for @insightsProjectionWithinBudget.
  ///
  /// In es, this message translates to:
  /// **'Cerrarías el mes dentro de tu presupuesto.'**
  String get insightsProjectionWithinBudget;

  /// No description provided for @insightsDailyTitle.
  ///
  /// In es, this message translates to:
  /// **'Gasto diario'**
  String get insightsDailyTitle;

  /// No description provided for @insightsDailyAverageLabel.
  ///
  /// In es, this message translates to:
  /// **'Promedio diario'**
  String get insightsDailyAverageLabel;

  /// No description provided for @insightsDailyMostExpensiveLabel.
  ///
  /// In es, this message translates to:
  /// **'Día más caro'**
  String get insightsDailyMostExpensiveLabel;

  /// No description provided for @insightsDailyNoSpendLabel.
  ///
  /// In es, this message translates to:
  /// **'Días sin gasto'**
  String get insightsDailyNoSpendLabel;

  /// Number of days this month with no spending
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{0 días} =1{1 día} other{{count} días}}'**
  String insightsDailyNoSpendValue(int count);

  /// No description provided for @insightsWeekdayTitle.
  ///
  /// In es, this message translates to:
  /// **'Patrón semanal'**
  String get insightsWeekdayTitle;

  /// No description provided for @insightsWeekdayMostExpensiveLabel.
  ///
  /// In es, this message translates to:
  /// **'Día con más gasto'**
  String get insightsWeekdayMostExpensiveLabel;

  /// No description provided for @insightsWeekdayLeastExpensiveLabel.
  ///
  /// In es, this message translates to:
  /// **'Día con menos gasto'**
  String get insightsWeekdayLeastExpensiveLabel;

  /// No description provided for @insightsLastActivityTitle.
  ///
  /// In es, this message translates to:
  /// **'Última actividad por categoría'**
  String get insightsLastActivityTitle;

  /// No description provided for @insightsLastActivityToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get insightsLastActivityToday;

  /// No description provided for @insightsLastActivityYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get insightsLastActivityYesterday;

  /// How many days ago a category's last transaction happened
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Hace 1 día} other{Hace {count} días}}'**
  String insightsLastActivityDaysAgo(int count);

  /// No description provided for @insightsUncategorizedTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin categorizar'**
  String get insightsUncategorizedTitle;

  /// Count and total amount of this month's expenses with no category
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 gasto} other{{count} gastos}} sin categoría este mes, por {amount}.'**
  String insightsUncategorizedMessage(int count, String amount);

  /// No description provided for @insightsUncategorizedAction.
  ///
  /// In es, this message translates to:
  /// **'Categorizar ahora'**
  String get insightsUncategorizedAction;

  /// No description provided for @insightsRecommendationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Recomendaciones'**
  String get insightsRecommendationsTitle;

  /// Suggests trimming spend in the top category to avoid overshooting the total budget
  ///
  /// In es, this message translates to:
  /// **'Para cerrar el mes dentro de presupuesto, reduce unos {amount} en {category}.'**
  String insightsRecommendationReduceCategory(String amount, String category);

  /// Flags a category spending well above its recent average
  ///
  /// In es, this message translates to:
  /// **'{category} está gastando bastante más de lo habitual este mes. Vale la pena revisarlo.'**
  String insightsRecommendationRunaway(String category);

  /// No description provided for @insightsRecommendationAllOnTrack.
  ///
  /// In es, this message translates to:
  /// **'¡Vas muy bien este mes! Sigue así.'**
  String get insightsRecommendationAllOnTrack;

  /// No description provided for @quickEntryTitle.
  ///
  /// In es, this message translates to:
  /// **'Registro rápido'**
  String get quickEntryTitle;
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
