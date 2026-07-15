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
  String get navDashboard => 'Dashboard';

  @override
  String get navGoals => 'Metas';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get categoryGroceries => 'Supermercado';

  @override
  String get categoryDining => 'Restaurantes';

  @override
  String get categoryTransport => 'Transporte';

  @override
  String get categoryLeisure => 'Ocio';

  @override
  String get categorySubscriptions => 'Suscripciones';

  @override
  String get categorySavings => 'Ahorro';

  @override
  String get categoryEssentials => 'Gastos esenciales';

  @override
  String get categoryEducation => 'Estudios';

  @override
  String get categoryEmergencyFund => 'Reserva de emergencia';

  @override
  String get categoryHealth => 'Salud';

  @override
  String get categoryNew => 'Nueva categoría';

  @override
  String get categoryEdit => 'Editar categoría';

  @override
  String get categoryNameLabel => 'Nombre';

  @override
  String get categoryNameHint => 'Ej. Mascotas';

  @override
  String get categoryNameRequired => 'Ingresa un nombre.';

  @override
  String get categoryIconLabel => 'Ícono';

  @override
  String get categoryColorLabel => 'Color';

  @override
  String get categoryCreate => 'Crear categoría';

  @override
  String get categorySaveChanges => 'Guardar cambios';

  @override
  String get categoryDefaultBadge => 'Predeterminada';

  @override
  String get categoryDeleteTitle => 'Eliminar categoría';

  @override
  String categoryDeleteWarning(String name) {
    return 'Se eliminará \"$name\" y también sus presupuestos. Sus transacciones quedarán sin categoría.';
  }

  @override
  String get categoriesLoadFailed => 'No pudimos cargar las categorías';

  @override
  String get categoriesOperationFailed =>
      'No pudimos completar la operación. Inténtalo de nuevo.';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Eliminar';

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
  String get quickEntrySaveError =>
      'No pudimos guardar el gasto. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get quickEntryScanReceipt => 'Escanear recibo';

  @override
  String get quickEntryScanningReceipt => 'Leyendo recibo…';

  @override
  String get quickEntryTakePhoto => 'Tomar una foto';

  @override
  String get quickEntryPickFromGallery => 'Elegir de la galería';

  @override
  String get quickEntryScanSuccess =>
      'Recibo leído. Revisa los datos antes de guardar.';

  @override
  String get quickEntryScanEmpty =>
      'No pudimos leer el recibo. Prueba con otra foto o escríbelo.';

  @override
  String get quickEntryScanPhotoAccessDenied =>
      'Permite el acceso a tus fotos desde Ajustes para elegir una imagen.';

  @override
  String get quickEntryScanCameraAccessDenied =>
      'Permite el acceso a la cámara desde Ajustes para tomar una foto.';

  @override
  String get quickEntryScanPickerError =>
      'No pudimos abrir la cámara o la galería. Inténtalo de nuevo.';

  @override
  String get quickEntryScanNetworkError =>
      'Sin conexión con el servicio de lectura. Revisa tu internet.';

  @override
  String get quickEntryScanRateLimited =>
      'Servicio ocupado. Espera unos segundos y reintenta.';

  @override
  String get quickEntryScanUnauthorized =>
      'Inicia sesión para escanear recibos.';

  @override
  String get quickEntryScanInvalidImage =>
      'No pudimos procesar esa imagen. Prueba con otra foto.';

  @override
  String get quickEntryScanUnavailable =>
      'El lector de recibos no está disponible ahora. Inténtalo más tarde.';

  @override
  String get quickEntryScanGenericError =>
      'No pudimos leer el recibo. Inténtalo de nuevo.';

  @override
  String get transactionDeleteTitle => 'Eliminar movimiento';

  @override
  String get transactionDeleteMessage =>
      'Este movimiento se eliminará definitivamente y los totales se recalcularán.';

  @override
  String get transactionDeleteSuccess => 'Movimiento eliminado.';

  @override
  String get transactionDeleteError =>
      'No pudimos eliminar el movimiento. Inténtalo de nuevo.';

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
  String get settingsCategories => 'Categorías';

  @override
  String get settingsBudgets => 'Presupuestos';

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
  String get budgetAlertsTitle => 'Alertas de presupuesto';

  @override
  String get budgetAlertsSubtitle =>
      'Te avisamos a ti y a tu pareja al cruzar el umbral.';

  @override
  String get budgetAlertThresholdLabel => 'Avisar cuando quede';

  @override
  String budgetAlertBanner(int percent, String category) {
    return 'Ojo: llevas $percent% de $category este mes.';
  }

  @override
  String budgetAlertBannerGeneric(int percent) {
    return 'Ojo: llevas $percent% de un presupuesto este mes.';
  }

  @override
  String budgetLimitReachedBanner(String category) {
    return 'Alcanzaste el límite de $category este mes.';
  }

  @override
  String get budgetLimitReachedBannerGeneric =>
      'Alcanzaste el límite de un presupuesto este mes.';

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

  @override
  String get subscriptionFrequencyWeekly => 'Semanal';

  @override
  String get subscriptionFrequencyMonthly => 'Mensual';

  @override
  String get subscriptionFrequencyYearly => 'Anual';

  @override
  String get subscriptionsTitle => 'Gastos recurrentes';

  @override
  String get subscriptionsEmptyTitle => 'Sin gastos recurrentes';

  @override
  String get subscriptionsEmptyMessage =>
      'Agrega tus suscripciones y cobros fijos para recordarlos a tiempo.';

  @override
  String get subscriptionsLoadFailed =>
      'No pudimos cargar los gastos recurrentes';

  @override
  String get subscriptionsOperationFailed =>
      'No pudimos completar la operación. Inténtalo de nuevo.';

  @override
  String get subscriptionNew => 'Nuevo gasto recurrente';

  @override
  String get subscriptionEdit => 'Editar gasto recurrente';

  @override
  String get subscriptionCreate => 'Agregar';

  @override
  String get subscriptionSaveChanges => 'Guardar cambios';

  @override
  String get subscriptionNameLabel => 'Nombre';

  @override
  String get subscriptionNameHint => 'Ej. Netflix';

  @override
  String get subscriptionNameRequired => 'Ingresa un nombre.';

  @override
  String get subscriptionAmountLabel => 'Monto';

  @override
  String get subscriptionAmountRequired => 'Ingresa un monto mayor que cero.';

  @override
  String get subscriptionFrequencyLabel => 'Frecuencia';

  @override
  String get subscriptionNextChargeLabel => 'Próximo cobro';

  @override
  String get subscriptionNextChargeNone => 'Sin fecha';

  @override
  String get subscriptionNextChargeClear => 'Quitar fecha';

  @override
  String get subscriptionCategoryLabel => 'Categoría (opcional)';

  @override
  String get subscriptionReminderTitle => 'Recordatorio';

  @override
  String get subscriptionReminderSubtitle => 'Te avisamos antes del cobro.';

  @override
  String get subscriptionReminderDaysLabel => 'Avisar antes';

  @override
  String subscriptionReminderDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
      zero: 'El mismo día',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionDeleteTitle => 'Eliminar gasto recurrente';

  @override
  String subscriptionDeleteWarning(String name) {
    return 'Se eliminará \"$name\" y su recordatorio.';
  }

  @override
  String get recurringReminderChannelName => 'Recordatorios de cobros';

  @override
  String get recurringReminderChannelDescription =>
      'Avisos antes de un cobro recurrente';

  @override
  String get recurringReminderTitle => 'Cobro próximo';

  @override
  String recurringReminderBody(String name) {
    return '$name se cobra pronto';
  }

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonSaveChanges => 'Guardar cambios';

  @override
  String get commonSignInToContinue => 'Inicia sesión para continuar.';

  @override
  String get commonCheckConnection =>
      'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get commonInvalidNameMax80 =>
      'Escribe un nombre válido de hasta 80 caracteres.';

  @override
  String get commonInvalidCurrency => 'Selecciona una moneda válida.';

  @override
  String get commonInvalidEmail => 'Correo no válido.';

  @override
  String get authResetPasswordTitle => 'Restablecer contraseña';

  @override
  String get authSignUpConfirmEmailInfo =>
      'Te enviamos un correo para confirmar tu cuenta. Ábrelo y vuelve para iniciar sesión.';

  @override
  String get authResetLinkSentInfo =>
      'Si el correo está registrado, te enviamos un enlace para restablecer tu contraseña.';

  @override
  String get authCreateAccountTitle => 'Crea tu cuenta';

  @override
  String get authReviewInvitationTitle => 'Entra para revisar tu invitación';

  @override
  String get authWelcomeBackTitle => 'Bienvenido de vuelta';

  @override
  String get authPendingInvitationHint =>
      'Usa el correo al que enviaron la invitación. Continuaremos automáticamente al entrar.';

  @override
  String get authNameHint => 'Tu nombre';

  @override
  String get authEmailHint => 'Correo electrónico';

  @override
  String get authPasswordHint => 'Contraseña';

  @override
  String get authConfirmPasswordHint => 'Confirmar contraseña';

  @override
  String get authForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get authCreateAccountCta => 'Crear cuenta';

  @override
  String get authSignInCta => 'Iniciar sesión';

  @override
  String get authToggleToSignIn => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get authToggleToSignUp => '¿Sin cuenta? Regístrate';

  @override
  String get authNameRequired => 'Escribe tu nombre.';

  @override
  String get authEmailRequired => 'Escribe tu correo.';

  @override
  String get authPasswordRequired => 'Escribe tu contraseña.';

  @override
  String get authPasswordTooShort => 'Mínimo 6 caracteres.';

  @override
  String get authPasswordsDontMatch => 'Las contraseñas no coinciden.';

  @override
  String get authForgotPasswordBody =>
      'Escribe tu correo y te enviaremos un enlace para crear una nueva contraseña.';

  @override
  String get authSendLink => 'Enviar enlace';

  @override
  String get resetPasswordUpdated => 'Contraseña actualizada.';

  @override
  String get resetPasswordTitle => 'Crea una nueva contraseña';

  @override
  String get resetPasswordBody =>
      'Elige una contraseña nueva para tu cuenta. Al guardarla entrarás automáticamente.';

  @override
  String get resetPasswordNewLabel => 'Nueva contraseña';

  @override
  String get resetPasswordNewRequired => 'Escribe tu nueva contraseña.';

  @override
  String get resetPasswordSave => 'Guardar contraseña';

  @override
  String get onboardingSlide1Title => 'Detecta las fugas de dinero';

  @override
  String get onboardingSlide1Body =>
      'Esos pequeños gastos hormiga que se escapan sin darte cuenta. leakless los hace visibles para que recuperes el control.';

  @override
  String get onboardingSlide2Title => 'Controlen los gastos en pareja';

  @override
  String get onboardingSlide2Body =>
      'Un libro de cuentas compartido y en tiempo real. Si uno gasta, ambos lo saben al instante.';

  @override
  String get onboardingSlide3Title => 'Ahorren juntos con metas claras';

  @override
  String get onboardingSlide3Body =>
      'Definan metas, vean el progreso líquido llenarse y celebren cada aporte hacia el futuro que quieren.';

  @override
  String get onboardingSkip => 'Saltar';

  @override
  String get onboardingStart => 'Comenzar';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get householdSetupPartnerEmailInvalid =>
      'Escribe un correo válido para tu pareja.';

  @override
  String householdSetupInvitationFailed(String error) {
    return 'Guardamos el hogar, pero no pudimos crear la invitación. $error';
  }

  @override
  String get householdSetupTitle => 'Configurar hogar';

  @override
  String get householdSetupPreparing => 'Preparando tu hogar…';

  @override
  String get householdSetupLoadErrorTitle => 'No pudimos cargar tu hogar';

  @override
  String get householdSetupNoHouseholdTitle => 'Tu cuenta aún no tiene hogar';

  @override
  String get householdSetupNoHouseholdMessage =>
      'No mostraremos datos financieros hasta recuperar un hogar válido.';

  @override
  String get householdSetupWaitingOwnerTitle => 'Esperando al owner';

  @override
  String get householdSetupWaitingOwnerMessage =>
      'Quien creó este hogar debe completar el nombre y la moneda. Actualizaremos este estado cuando termine.';

  @override
  String get householdSetupHeroTitle => 'Hagamos suyo este hogar';

  @override
  String get householdSetupHeroSubtitle =>
      'Configura la base compartida. Podrás ajustarla más tarde.';

  @override
  String get householdNameLabel => 'Nombre del hogar';

  @override
  String get householdNameHint => 'Nuestra casa';

  @override
  String get householdNameRequired => 'Escribe un nombre para el hogar.';

  @override
  String get householdCurrencyLabel => 'Moneda principal';

  @override
  String get householdCurrencyNote =>
      'La moneda sólo puede cambiar mientras el hogar no tenga importes guardados.';

  @override
  String get householdSetupStep2Title => 'Categorías iniciales';

  @override
  String get householdSetupStep2Subtitle =>
      'Estas categorías ya están listas para registrar gastos.';

  @override
  String get householdSetupStep3Title => 'Tu pareja';

  @override
  String get householdSetupStep3Subtitle =>
      'La invitación es opcional. Podrás retomarla desde Ajustes.';

  @override
  String get householdPartnerEmailLabel => 'Correo de tu pareja';

  @override
  String get householdPartnerEmailHint => 'pareja@correo.com';

  @override
  String get householdSetupSaveAndInvite => 'Guardar e invitar';

  @override
  String get householdSetupContinueWithoutInvite => 'Continuar sin invitar';

  @override
  String get categoriesReviewLoadError =>
      'No pudimos cargar las categorías. Reintenta antes de continuar.';

  @override
  String get categoriesReviewEmpty => 'No encontramos categorías iniciales.';

  @override
  String get householdSetupErrorNotOwner =>
      'Sólo quien creó este hogar puede configurarlo.';

  @override
  String get householdSetupErrorCurrencyLocked =>
      'Este hogar ya tiene importes. Cambiar la moneda podría reinterpretarlos, así que conservamos la moneda actual.';

  @override
  String get householdSetupErrorGeneric =>
      'No pudimos guardar el hogar. Inténtalo de nuevo.';

  @override
  String get invitationShareSubject => 'Invitación a nuestro hogar en leakless';

  @override
  String invitationShareText(String link, String code) {
    return 'Únete a nuestro hogar en leakless.\n\n$link\n\nSi el enlace no abre, pega este código:\n$code';
  }

  @override
  String get invitationShareFailed =>
      'No pudimos abrir el menú para compartir.';

  @override
  String get invitationsTitle => 'Invitar a tu pareja';

  @override
  String get invitationsNoHousehold =>
      'No encontramos un hogar activo para invitar.';

  @override
  String get invitationsNotOwner =>
      'Sólo quien creó este hogar puede enviar invitaciones.';

  @override
  String get invitationEmailRequired => 'Escribe su correo.';

  @override
  String get invitationCreate => 'Crear invitación';

  @override
  String get invitationLinkCopied => 'Enlace copiado.';

  @override
  String get invitationCodeCopied => 'Código copiado.';

  @override
  String get invitationHaveCode => 'Tengo un código de invitación';

  @override
  String get invitationsIntroTitleFallback => 'Compartir el hogar';

  @override
  String get invitationsIntroSubtitle =>
      'Genera un enlace de un solo uso. Sólo funcionará con el correo que indiques.';

  @override
  String invitationExpiresOn(String date) {
    return 'Vence el $date';
  }

  @override
  String get invitationTitle => 'Invitación';

  @override
  String get invitationShare => 'Compartir invitación';

  @override
  String get invitationCopyLink => 'Copiar enlace';

  @override
  String get invitationCopyCode => 'Copiar código';

  @override
  String get invitationRevoke => 'Revocar invitación';

  @override
  String get invitationNoLongerShareable =>
      'Este código ya no se puede compartir.';

  @override
  String get invitationStatusPending => 'Pendiente';

  @override
  String get invitationStatusAccepted => 'Aceptada';

  @override
  String get invitationStatusCancelled => 'Revocada';

  @override
  String get invitationStatusExpired => 'Vencida';

  @override
  String get invitationCodeInvalidFormat =>
      'El código debe tener 64 caracteres hexadecimales.';

  @override
  String get invitationExpiredMessage => 'La invitación ha vencido.';

  @override
  String get invitationCancelledMessage => 'La invitación fue revocada.';

  @override
  String get invitationAlreadyUsedMessage =>
      'Esta invitación ya fue utilizada.';

  @override
  String get invitationPersistenceFailed =>
      'Mantén la app abierta: no pudimos guardar el intento de forma segura.';

  @override
  String get invitationOpenFailed => 'No pudimos abrir esta invitación.';

  @override
  String get invitationSuccessHeroTitle => 'Ya están conectados';

  @override
  String get invitationHeroTitle => 'Un hogar, entre dos';

  @override
  String get invitationPasteCodeTitle => 'Pega tu código';

  @override
  String get invitationPasteCodeSubtitle =>
      'Puedes abrir el enlace o pegar aquí el código que te compartieron.';

  @override
  String get invitationCodeFieldHint => 'Código de 64 caracteres';

  @override
  String get invitationReview => 'Revisar invitación';

  @override
  String get invitationHouseholdFallback => 'Hogar compartido';

  @override
  String invitationInviterInvited(String inviter) {
    return '$inviter te invitó a compartir este hogar.';
  }

  @override
  String get invitationInviterFallback => 'Tu pareja';

  @override
  String invitationValidUntil(String date) {
    return 'Válida hasta $date';
  }

  @override
  String get invitationAcceptJoin => 'Aceptar y unirme';

  @override
  String get invitationNotNow => 'Ahora no';

  @override
  String get invitationUseAnotherAccount => 'Usar otra cuenta';

  @override
  String get invitationDiscard => 'Descartar invitación';

  @override
  String get invitationAlreadyMember => 'Ya pertenecías a este hogar.';

  @override
  String get invitationAcceptedSuccess =>
      'La invitación fue aceptada. Ya pueden ver sus finanzas compartidas.';

  @override
  String get invitationGoHome => 'Ir al inicio';

  @override
  String get profileImageTooLarge =>
      'La imagen es demasiado grande. Prueba con otra.';

  @override
  String get profileUpdated => 'Perfil actualizado.';

  @override
  String get profileChangeAvatarTitle => 'Cambiar avatar';

  @override
  String get profileEditTitle => 'Editar perfil';

  @override
  String get profileLoading => 'Cargando tu perfil…';

  @override
  String get profileLoadErrorTitle => 'No pudimos cargar tu perfil';

  @override
  String get profileNoProfileTitle => 'Sin perfil';

  @override
  String get profileNoProfileMessage =>
      'Inicia sesión de nuevo para editar tu perfil.';

  @override
  String get profileNameLabel => 'Nombre visible';

  @override
  String get profileNameHint => 'Cómo te ve tu pareja';

  @override
  String get profileNameRequired => 'Escribe un nombre visible.';

  @override
  String get profileCurrencyLabel => 'Moneda';

  @override
  String get profileAvatarFailed =>
      'No pudimos usar esa imagen. Inténtalo de nuevo.';

  @override
  String get profileErrorGeneric =>
      'No pudimos guardar los cambios. Inténtalo de nuevo.';

  @override
  String get pickerErrorPhotoAccessDenied =>
      'Permite el acceso a tus fotos desde Ajustes para elegir un avatar.';

  @override
  String get pickerErrorCameraAccessDenied =>
      'Permite el acceso a la cámara desde Ajustes para tomar una foto.';

  @override
  String get pickerErrorGeneric =>
      'No pudimos abrir el selector de imágenes. Inténtalo de nuevo.';

  @override
  String get dashboardLoading => 'Cargando tu panel…';

  @override
  String get dashboardLoadErrorTitle => 'No pudimos cargar el panel';

  @override
  String get dashboardLoadErrorMessage => 'Inténtalo de nuevo en un momento.';

  @override
  String get dashboardAvailableBalance => 'Balance disponible';

  @override
  String get dashboardRecentActivity => 'Actividad reciente';

  @override
  String get dashboardSeeAll => 'Ver todo';

  @override
  String get dashboardSavingsRate => 'Tasa de ahorro real';

  @override
  String get dashboardRecurringExpenses => 'Gastos recurrentes';

  @override
  String get dashboardLimitAlerts => 'Alertas de límites';

  @override
  String get dashboardSavingsRateShort => 'tasa de ahorro';

  @override
  String dashboardLeak(String amount) {
    return 'Fuga $amount';
  }

  @override
  String get transactionsLoadError => 'No pudimos cargar el historial';

  @override
  String get transactionsEmptyTitle => 'Sin movimientos';

  @override
  String get transactionsEmptyMessage =>
      'Ajusta los filtros o registra tu primer gasto.';

  @override
  String get transactionsFilterUncategorized => 'Sin categorizar';

  @override
  String get transactionFallbackTitle => 'Movimiento';

  @override
  String get errorAuthSession => 'No pudimos verificar tu sesión.';

  @override
  String get errorNetwork => 'Revisa tu conexión a internet.';

  @override
  String get errorNotFound => 'No encontramos lo que buscabas.';

  @override
  String get errorServer => 'Algo falló en el servidor. Inténtalo de nuevo.';

  @override
  String get errorUnexpected => 'Ocurrió un error inesperado.';

  @override
  String get authErrorInvalidCredentials => 'Correo o contraseña incorrectos.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Confirma tu correo antes de iniciar sesión. Revisa tu bandeja de entrada.';

  @override
  String get authErrorEmailExists =>
      'Ya existe una cuenta con este correo. Inicia sesión.';

  @override
  String get authErrorWeakPassword =>
      'La contraseña es muy débil. Usa al menos 6 caracteres.';

  @override
  String get authErrorSamePassword =>
      'La nueva contraseña debe ser distinta a la anterior.';

  @override
  String get authErrorInvalidEmail => 'El correo no es válido.';

  @override
  String get authErrorSignupDisabled =>
      'El registro está deshabilitado por ahora.';

  @override
  String get authErrorRateLimit =>
      'Demasiados intentos. Espera un momento e inténtalo de nuevo.';

  @override
  String get authErrorGeneric =>
      'No pudimos completar la operación. Inténtalo de nuevo.';

  @override
  String get authErrorUnexpected =>
      'Ocurrió un error inesperado. Inténtalo de nuevo.';

  @override
  String get invitationErrorInvalidEmail => 'Escribe un correo válido.';

  @override
  String get invitationErrorInvalidExpiry =>
      'La duración de la invitación no es válida.';

  @override
  String get invitationErrorCannotInviteSelf =>
      'No puedes invitar tu propio correo.';

  @override
  String get invitationErrorNotOwner =>
      'Sólo quien creó este hogar puede invitar.';

  @override
  String get invitationErrorAlreadyMember =>
      'Esa persona ya pertenece a este hogar.';

  @override
  String get invitationErrorInvalidToken =>
      'El enlace o código de invitación no es válido.';

  @override
  String get invitationErrorEmailMismatch =>
      'Esta invitación fue enviada a otro correo. Usa esa cuenta para continuar.';

  @override
  String get invitationErrorNotFound => 'No encontramos esta invitación.';

  @override
  String get invitationErrorAcceptedCannotCancel =>
      'Una invitación aceptada ya no se puede revocar.';

  @override
  String get invitationErrorHouseholdNotEmpty =>
      'Tu hogar actual contiene datos. No podemos moverlos automáticamente.';

  @override
  String get invitationErrorProfileNotFound =>
      'No encontramos tu perfil. Inténtalo de nuevo.';

  @override
  String get invitationErrorGeneric =>
      'No pudimos completar la invitación. Inténtalo de nuevo.';

  @override
  String get currencyCAD => 'Dólar canadiense';

  @override
  String get currencyUSD => 'Dólar estadounidense';

  @override
  String get currencyEUR => 'Euro';

  @override
  String get currencyMXN => 'Peso mexicano';

  @override
  String get currencyCOP => 'Peso colombiano';

  @override
  String get currencyARS => 'Peso argentino';

  @override
  String get currencyCLP => 'Peso chileno';

  @override
  String get currencyPEN => 'Sol peruano';

  @override
  String get currencyBRL => 'Real brasileño';

  @override
  String get currencyGBP => 'Libra esterlina';

  @override
  String get currencyJPY => 'Yen japonés';

  @override
  String get currencyCHF => 'Franco suizo';

  @override
  String get insightsTitle => 'Dashboard';

  @override
  String get insightsLoading => 'Cargando tus estadísticas…';

  @override
  String get insightsErrorTitle => 'No pudimos cargar tus estadísticas';

  @override
  String get insightsErrorMessage => 'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get insightsRetry => 'Reintentar';

  @override
  String get insightsEmptyTitle => 'Aún no hay gastos';

  @override
  String get insightsEmptyMessage =>
      'Registra tu primer gasto para ver tus estadísticas del mes.';

  @override
  String get insightsEmptyAction => 'Registrar un gasto';

  @override
  String get insightsMonthSummaryTitle => 'Resumen del mes';

  @override
  String get insightsSpentLabel => 'Gastado este mes';

  @override
  String insightsOfBudget(String budget) {
    return 'de $budget';
  }

  @override
  String insightsBudgetUsed(int percent) {
    return '$percent% usado';
  }

  @override
  String insightsRemaining(String amount) {
    return 'Te queda $amount';
  }

  @override
  String insightsOverBudgetBy(String amount) {
    return 'Te pasaste por $amount';
  }

  @override
  String get insightsNoBudgetNote =>
      'Aún no defines un presupuesto este mes. Crea uno para seguir tu ritmo.';

  @override
  String get insightsCreateBudget => 'Crear presupuesto';

  @override
  String get insightsStatusOnTrack => 'Vas al día con tu presupuesto.';

  @override
  String get insightsStatusAhead => 'Vas por debajo del ritmo previsto. ¡Bien!';

  @override
  String get insightsStatusAtRisk =>
      'Estás gastando más rápido de lo previsto.';

  @override
  String get insightsStatusOver => 'Superaste tu presupuesto del mes.';

  @override
  String get insightsPaceTitle => 'Ritmo de gasto';

  @override
  String get insightsPaceExpected => 'Esperado a hoy';

  @override
  String get insightsPaceActual => 'Gastado a hoy';

  @override
  String insightsPaceAhead(String amount) {
    return 'Vas $amount por debajo del ritmo.';
  }

  @override
  String insightsPaceBehind(String amount) {
    return 'Vas $amount por encima del ritmo.';
  }

  @override
  String get insightsPaceOnPace => 'Justo en el ritmo previsto.';

  @override
  String insightsPaceReduce(String amount) {
    return 'Reduce $amount para cerrar dentro del presupuesto.';
  }

  @override
  String get insightsCategoriesTitle => 'Gasto por categoría';

  @override
  String insightsCategoryShare(int percent) {
    return '$percent% del total';
  }

  @override
  String get insightsCategoryUnnamed => 'Categoría';

  @override
  String insightsCategoryRemaining(String amount) {
    return 'Quedan $amount';
  }

  @override
  String insightsCategoryOverBy(String amount) {
    return 'Excedido por $amount';
  }

  @override
  String get insightsPieTitle => 'Distribución por categoría';

  @override
  String get insightsPieOthers => 'Otros';

  @override
  String get insightsPieCenterLabel => 'gastado';

  @override
  String get insightsRunawayTitle => 'Categorías fuera de control';

  @override
  String insightsRunawayBadge(int percent) {
    return '+$percent%';
  }

  @override
  String insightsRunawayCompare(String average) {
    return 'Promedio de 3 meses: $average';
  }

  @override
  String get insightsTrendTitle => 'Comparativo histórico';

  @override
  String get insightsTrendVsPreviousLabel => 'Mes anterior';

  @override
  String get insightsTrendVsAverageLabel => 'Promedio 3 meses';

  @override
  String insightsTrendChangeUp(int percent) {
    return '$percent% más';
  }

  @override
  String insightsTrendChangeDown(int percent) {
    return '$percent% menos';
  }

  @override
  String get insightsTrendChangeStable => 'Similar';

  @override
  String get insightsTrendNoPreviousMonth =>
      'Aún no hay datos del mes anterior.';

  @override
  String get insightsProjectionTitle => 'Proyección de cierre';

  @override
  String get insightsProjectionInsufficientData =>
      'Necesitamos unos días más de este mes para poder proyectar tu cierre.';

  @override
  String get insightsProjectionLabel => 'Estimado a fin de mes';

  @override
  String insightsProjectionOverBudget(String amount) {
    return 'Superarías tu presupuesto por $amount.';
  }

  @override
  String get insightsProjectionWithinBudget =>
      'Cerrarías el mes dentro de tu presupuesto.';

  @override
  String get insightsDailyTitle => 'Gasto diario';

  @override
  String get insightsDailyAverageLabel => 'Promedio diario';

  @override
  String get insightsDailyMostExpensiveLabel => 'Día más caro';

  @override
  String get insightsDailyNoSpendLabel => 'Días sin gasto';

  @override
  String insightsDailyNoSpendValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
      zero: '0 días',
    );
    return '$_temp0';
  }

  @override
  String get insightsWeekdayTitle => 'Patrón semanal';

  @override
  String get insightsWeekdayMostExpensiveLabel => 'Día con más gasto';

  @override
  String get insightsWeekdayLeastExpensiveLabel => 'Día con menos gasto';

  @override
  String get insightsLastActivityTitle => 'Última actividad por categoría';

  @override
  String get insightsLastActivityToday => 'Hoy';

  @override
  String get insightsLastActivityYesterday => 'Ayer';

  @override
  String insightsLastActivityDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hace $count días',
      one: 'Hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get insightsUncategorizedTitle => 'Sin categorizar';

  @override
  String insightsUncategorizedMessage(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gastos',
      one: '1 gasto',
    );
    return '$_temp0 sin categoría este mes, por $amount.';
  }

  @override
  String get insightsUncategorizedAction => 'Categorizar ahora';

  @override
  String get insightsRecommendationsTitle => 'Recomendaciones';

  @override
  String insightsRecommendationReduceCategory(String amount, String category) {
    return 'Para cerrar el mes dentro de presupuesto, reduce unos $amount en $category.';
  }

  @override
  String insightsRecommendationRunaway(String category) {
    return '$category está gastando bastante más de lo habitual este mes. Vale la pena revisarlo.';
  }

  @override
  String get insightsRecommendationAllOnTrack =>
      '¡Vas muy bien este mes! Sigue así.';

  @override
  String get quickEntryTitle => 'Registro rápido';

  @override
  String get movementNew => 'Nuevo movimiento';

  @override
  String get movementExpense => 'Registrar gasto';

  @override
  String get movementIncome => 'Registrar ingreso';

  @override
  String get movementTransfer => 'Transferir entre cuentas';

  @override
  String get currencyLabel => 'Moneda';

  @override
  String get accountLabel => 'Cuenta';

  @override
  String get accountDestination => 'Cuenta de destino';

  @override
  String get accountSource => 'Cuenta origen';

  @override
  String get amountReceived => 'Cantidad recibida';

  @override
  String get amountSent => 'Cantidad enviada';

  @override
  String get incomeSourceLabel => 'Fuente de ingreso';

  @override
  String get incomeSourceNew => 'Nueva fuente';

  @override
  String get optionalNote => 'Nota (opcional)';

  @override
  String get saveIncome => 'Guardar ingreso';

  @override
  String get saveTransfer => 'Guardar transferencia';

  @override
  String get withoutSource => 'Sin fuente';

  @override
  String get accountsTitle => 'Cuentas';

  @override
  String get incomeSourcesTitle => 'Fuentes de ingreso';

  @override
  String get archivedLabel => 'Archivada';

  @override
  String get archiveAction => 'Archivar';

  @override
  String get accountNew => 'Nueva cuenta';

  @override
  String get accountEdit => 'Editar cuenta';

  @override
  String get sourceEdit => 'Editar fuente';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get openingBalance => 'Saldo inicial';

  @override
  String get billedCurrency => 'Moneda facturada';

  @override
  String get usualAccount => 'Cuenta habitual';

  @override
  String get totalBalance => 'Saldo total';

  @override
  String get partialTotal => 'Total parcial · falta una tasa de cambio';

  @override
  String get monthlyNetFlow => 'Flujo neto del mes';

  @override
  String get incomeBySource => 'Ingresos por fuente';

  @override
  String get incomeByCurrency => 'Ingresos por moneda';

  @override
  String get noIncomePeriod => 'Sin ingresos en este período';

  @override
  String get accountsLoadError => 'No se pudieron cargar las cuentas';

  @override
  String get incomeSourcesLoadError => 'No se pudieron cargar las fuentes';

  @override
  String get recordCharge => 'Registrar cargo';

  @override
  String get actualDebitedAmount => 'Importe real debitado';

  @override
  String get chargeAccountMissing =>
      'Selecciona una cuenta habitual antes de registrar el cargo';

  @override
  String get chargeSaved => 'Cargo registrado';

  @override
  String get chargeSaveError => 'No se pudo registrar el cargo';
}
