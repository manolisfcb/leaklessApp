// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navHome => 'Inicio';

  @override
  String get navHistory => 'Historial';

  @override
  String get navBudgets => 'Presupuestos';

  @override
  String get navGoals => 'Metas';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get quickEntryWho => '¿Quién?';

  @override
  String get quickEntryCategory => 'Categoría';

  @override
  String get quickEntryNote => 'Nota';

  @override
  String get quickEntryNoteHint => 'Descripción (ej. comercio)';

  @override
  String get quickEntryPriority => 'Prioridad';

  @override
  String get quickEntrySave => 'Guardar';

  @override
  String get quickEntryScanReceipt => 'Escanear recibo';

  @override
  String get quickEntryScanningReceipt => 'Leyendo recibo…';

  @override
  String get quickEntryTakePhoto => 'Tomar una foto';

  @override
  String get quickEntryPickFromGallery => 'Elegir de la galería';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsProfileFallback => 'Tu perfil';

  @override
  String get settingsHouseholdNameCurrency => 'Nombre y moneda';

  @override
  String get settingsNoHousehold => 'Sin hogar';

  @override
  String get settingsPartner => 'Pareja';

  @override
  String settingsMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '1 miembro',
    );
    return '$_temp0';
  }

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsNotificationsOn => 'Activadas';

  @override
  String get settingsNotificationsOff => 'Desactivadas';

  @override
  String get settingsSubscription => 'Suscripción';

  @override
  String get settingsPremium => 'Premium';

  @override
  String get settingsFree => 'Gratis';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsSignOut => 'Cerrar sesión';

  @override
  String get settingsDeleteAccount => 'Eliminar cuenta';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get transactionTypeIncome => 'Ingreso';

  @override
  String get transactionTypeExpense => 'Gasto';

  @override
  String get transactionTypeTransfer => 'Transferencia';

  @override
  String get priorityNecessity => 'Necesidad';

  @override
  String get priorityLifestyle => 'Estilo de Vida';

  @override
  String get priorityFuture => 'Futuro';

  @override
  String get priorityAnt => 'Hormiga';

  @override
  String get sourceManual => 'Manual';

  @override
  String get sourceBank => 'Banco';

  @override
  String get sourceImport => 'Importado';

  @override
  String get responsibleMe => 'Tú';

  @override
  String get responsiblePartner => 'Pareja';

  @override
  String get responsibleShared => 'Compartido';

  @override
  String get budgetStatusNormal => 'En control';

  @override
  String get budgetStatusWarning => 'Cerca del límite';

  @override
  String get budgetStatusExceeded => 'Límite superado';

  @override
  String get goalStatusActive => 'Activa';

  @override
  String get goalStatusCompleted => 'Completada';

  @override
  String get goalStatusPaused => 'En pausa';

  @override
  String get goalStatusArchived => 'Archivada';

  @override
  String get subscriptionStatusActive => 'Activa';

  @override
  String get subscriptionStatusTrial => 'Prueba';

  @override
  String get subscriptionStatusPaused => 'En pausa';

  @override
  String get subscriptionStatusCanceled => 'Cancelada';
}
