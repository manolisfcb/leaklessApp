// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get navHome => 'Início';

  @override
  String get navHistory => 'Histórico';

  @override
  String get navBudgets => 'Orçamentos';

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
  String get categoryLeisure => 'Lazer';

  @override
  String get categorySubscriptions => 'Assinaturas';

  @override
  String get categorySavings => 'Poupança';

  @override
  String get categoryEssentials => 'Despesas essenciais';

  @override
  String get categoryEducation => 'Educação';

  @override
  String get categoryEmergencyFund => 'Reserva de emergência';

  @override
  String get categoryHealth => 'Saúde';

  @override
  String get categoryNew => 'Nova categoria';

  @override
  String get categoryEdit => 'Editar categoria';

  @override
  String get categoryNameLabel => 'Nome';

  @override
  String get categoryNameHint => 'Ex.: Pets';

  @override
  String get categoryNameRequired => 'Digite um nome.';

  @override
  String get categoryIconLabel => 'Ícone';

  @override
  String get categoryColorLabel => 'Cor';

  @override
  String get categoryCreate => 'Criar categoria';

  @override
  String get categorySaveChanges => 'Salvar alterações';

  @override
  String get categoryDefaultBadge => 'Padrão';

  @override
  String get categoryDeleteTitle => 'Excluir categoria';

  @override
  String categoryDeleteWarning(String name) {
    return '\"$name\" e seus orçamentos serão excluídos. Suas transações permanecerão, sem categoria.';
  }

  @override
  String get categoriesLoadFailed => 'Não foi possível carregar as categorias';

  @override
  String get categoriesOperationFailed =>
      'Não foi possível concluir a operação. Tente novamente.';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get quickEntryWho => 'Quem?';

  @override
  String get quickEntryCategory => 'Categoria';

  @override
  String get quickEntryNote => 'Nota';

  @override
  String get quickEntryNoteHint => 'Descrição (ex.: loja)';

  @override
  String get quickEntryPriority => 'Prioridade';

  @override
  String get quickEntrySave => 'Salvar';

  @override
  String get quickEntrySaveError =>
      'Não conseguimos salvar o gasto. Verifique sua conexão e tente novamente.';

  @override
  String get quickEntryScanReceipt => 'Escanear recibo';

  @override
  String get quickEntryScanningReceipt => 'Lendo recibo…';

  @override
  String get quickEntryTakePhoto => 'Tirar uma foto';

  @override
  String get quickEntryPickFromGallery => 'Escolher da galeria';

  @override
  String get quickEntryScanSuccess =>
      'Recibo lido. Confira os dados antes de salvar.';

  @override
  String get quickEntryScanEmpty =>
      'Não conseguimos ler o recibo. Tente outra foto ou preencha manualmente.';

  @override
  String get quickEntryScanPhotoAccessDenied =>
      'Permita o acesso às fotos nos Ajustes para escolher uma imagem.';

  @override
  String get quickEntryScanCameraAccessDenied =>
      'Permita o acesso à câmera nos Ajustes para tirar uma foto.';

  @override
  String get quickEntryScanPickerError =>
      'Não conseguimos abrir a câmera ou a galeria. Tente novamente.';

  @override
  String get quickEntryScanNetworkError =>
      'Sem conexão com o leitor de recibos. Verifique sua internet.';

  @override
  String get quickEntryScanRateLimited =>
      'O leitor está ocupado. Aguarde alguns segundos e tente novamente.';

  @override
  String get quickEntryScanUnauthorized =>
      'Entre na sua conta para escanear recibos.';

  @override
  String get quickEntryScanInvalidImage =>
      'Não conseguimos processar essa imagem. Tente outra foto.';

  @override
  String get quickEntryScanUnavailable =>
      'O leitor de recibos não está disponível agora. Tente mais tarde.';

  @override
  String get quickEntryScanGenericError =>
      'Não conseguimos ler o recibo. Tente novamente.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsProfileFallback => 'Seu perfil';

  @override
  String get settingsHouseholdNameCurrency => 'Nome e moeda';

  @override
  String get settingsNoHousehold => 'Sem lar';

  @override
  String get settingsPartner => 'Parceiro(a)';

  @override
  String settingsMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membros',
      one: '1 membro',
    );
    return '$_temp0';
  }

  @override
  String get settingsNotifications => 'Notificações';

  @override
  String get settingsNotificationsOn => 'Ativadas';

  @override
  String get settingsNotificationsOff => 'Desativadas';

  @override
  String get settingsCategories => 'Categorias';

  @override
  String get settingsBudgets => 'Orçamentos';

  @override
  String get settingsSubscription => 'Assinatura';

  @override
  String get settingsPremium => 'Premium';

  @override
  String get settingsFree => 'Grátis';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsSignOut => 'Sair';

  @override
  String get settingsDeleteAccount => 'Excluir conta';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get transactionTypeIncome => 'Receita';

  @override
  String get transactionTypeExpense => 'Despesa';

  @override
  String get transactionTypeTransfer => 'Transferência';

  @override
  String get priorityNecessity => 'Necessidade';

  @override
  String get priorityLifestyle => 'Estilo de Vida';

  @override
  String get priorityFuture => 'Futuro';

  @override
  String get priorityAnt => 'Formiga';

  @override
  String get sourceManual => 'Manual';

  @override
  String get sourceBank => 'Banco';

  @override
  String get sourceImport => 'Importado';

  @override
  String get responsibleMe => 'Você';

  @override
  String get responsiblePartner => 'Parceiro(a)';

  @override
  String get responsibleShared => 'Compartilhado';

  @override
  String get budgetStatusNormal => 'Sob controle';

  @override
  String get budgetStatusWarning => 'Perto do limite';

  @override
  String get budgetStatusExceeded => 'Limite excedido';

  @override
  String get budgetAlertsTitle => 'Alertas de orçamento';

  @override
  String get budgetAlertsSubtitle =>
      'Vocês dois recebem um aviso ao cruzar o limite.';

  @override
  String get budgetAlertThresholdLabel => 'Avisar quando restar';

  @override
  String budgetAlertBanner(int percent, String category) {
    return 'Atenção: você já usou $percent% de $category este mês.';
  }

  @override
  String budgetAlertBannerGeneric(int percent) {
    return 'Atenção: você já usou $percent% de um orçamento este mês.';
  }

  @override
  String budgetLimitReachedBanner(String category) {
    return 'Você atingiu o limite de $category este mês.';
  }

  @override
  String get budgetLimitReachedBannerGeneric =>
      'Você atingiu o limite de um orçamento este mês.';

  @override
  String get goalStatusActive => 'Ativa';

  @override
  String get goalStatusCompleted => 'Concluída';

  @override
  String get goalStatusPaused => 'Pausada';

  @override
  String get goalStatusArchived => 'Arquivada';

  @override
  String get subscriptionStatusActive => 'Ativa';

  @override
  String get subscriptionStatusTrial => 'Teste';

  @override
  String get subscriptionStatusPaused => 'Pausada';

  @override
  String get subscriptionStatusCanceled => 'Cancelada';

  @override
  String get subscriptionFrequencyWeekly => 'Semanal';

  @override
  String get subscriptionFrequencyMonthly => 'Mensal';

  @override
  String get subscriptionFrequencyYearly => 'Anual';

  @override
  String get subscriptionsTitle => 'Despesas recorrentes';

  @override
  String get subscriptionsEmptyTitle => 'Sem despesas recorrentes';

  @override
  String get subscriptionsEmptyMessage =>
      'Adicione suas assinaturas e cobranças fixas para ser lembrado a tempo.';

  @override
  String get subscriptionsLoadFailed =>
      'Não foi possível carregar as despesas recorrentes';

  @override
  String get subscriptionsOperationFailed =>
      'Não foi possível concluir a operação. Tente novamente.';

  @override
  String get subscriptionNew => 'Nova despesa recorrente';

  @override
  String get subscriptionEdit => 'Editar despesa recorrente';

  @override
  String get subscriptionCreate => 'Adicionar';

  @override
  String get subscriptionSaveChanges => 'Salvar alterações';

  @override
  String get subscriptionNameLabel => 'Nome';

  @override
  String get subscriptionNameHint => 'Ex.: Netflix';

  @override
  String get subscriptionNameRequired => 'Digite um nome.';

  @override
  String get subscriptionAmountLabel => 'Valor';

  @override
  String get subscriptionAmountRequired => 'Digite um valor maior que zero.';

  @override
  String get subscriptionFrequencyLabel => 'Frequência';

  @override
  String get subscriptionNextChargeLabel => 'Próxima cobrança';

  @override
  String get subscriptionNextChargeNone => 'Sem data';

  @override
  String get subscriptionNextChargeClear => 'Remover data';

  @override
  String get subscriptionCategoryLabel => 'Categoria (opcional)';

  @override
  String get subscriptionReminderTitle => 'Lembrete';

  @override
  String get subscriptionReminderSubtitle => 'Avisamos você antes da cobrança.';

  @override
  String get subscriptionReminderDaysLabel => 'Avisar antes';

  @override
  String subscriptionReminderDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
      zero: 'No mesmo dia',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionDeleteTitle => 'Excluir despesa recorrente';

  @override
  String subscriptionDeleteWarning(String name) {
    return '\"$name\" e seu lembrete serão excluídos.';
  }

  @override
  String get recurringReminderChannelName => 'Lembretes de cobrança';

  @override
  String get recurringReminderChannelDescription =>
      'Aviso antes de uma cobrança recorrente';

  @override
  String get recurringReminderTitle => 'Cobrança próxima';

  @override
  String recurringReminderBody(String name) {
    return '$name será cobrado em breve';
  }

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonSaveChanges => 'Salvar alterações';

  @override
  String get commonSignInToContinue => 'Faça login para continuar.';

  @override
  String get commonCheckConnection =>
      'Verifique sua conexão e tente novamente.';

  @override
  String get commonInvalidNameMax80 =>
      'Digite um nome válido de até 80 caracteres.';

  @override
  String get commonInvalidCurrency => 'Selecione uma moeda válida.';

  @override
  String get commonInvalidEmail => 'E-mail inválido.';

  @override
  String get authResetPasswordTitle => 'Redefinir senha';

  @override
  String get authSignUpConfirmEmailInfo =>
      'Enviamos um e-mail para confirmar sua conta. Abra-o e volte para entrar.';

  @override
  String get authResetLinkSentInfo =>
      'Se o e-mail estiver cadastrado, enviamos um link para redefinir sua senha.';

  @override
  String get authCreateAccountTitle => 'Crie sua conta';

  @override
  String get authReviewInvitationTitle => 'Entre para ver seu convite';

  @override
  String get authWelcomeBackTitle => 'Bem-vindo de volta';

  @override
  String get authPendingInvitationHint =>
      'Use o e-mail para o qual o convite foi enviado. Continuaremos automaticamente ao entrar.';

  @override
  String get authNameHint => 'Seu nome';

  @override
  String get authEmailHint => 'E-mail';

  @override
  String get authPasswordHint => 'Senha';

  @override
  String get authConfirmPasswordHint => 'Confirmar senha';

  @override
  String get authForgotPassword => 'Esqueceu sua senha?';

  @override
  String get authCreateAccountCta => 'Criar conta';

  @override
  String get authSignInCta => 'Entrar';

  @override
  String get authToggleToSignIn => 'Já tem conta? Entre';

  @override
  String get authToggleToSignUp => 'Sem conta? Cadastre-se';

  @override
  String get authNameRequired => 'Digite seu nome.';

  @override
  String get authEmailRequired => 'Digite seu e-mail.';

  @override
  String get authPasswordRequired => 'Digite sua senha.';

  @override
  String get authPasswordTooShort => 'Mínimo de 6 caracteres.';

  @override
  String get authPasswordsDontMatch => 'As senhas não coincidem.';

  @override
  String get authForgotPasswordBody =>
      'Digite seu e-mail e enviaremos um link para criar uma nova senha.';

  @override
  String get authSendLink => 'Enviar link';

  @override
  String get resetPasswordUpdated => 'Senha atualizada.';

  @override
  String get resetPasswordTitle => 'Crie uma nova senha';

  @override
  String get resetPasswordBody =>
      'Escolha uma nova senha para sua conta. Ao salvá-la, você entrará automaticamente.';

  @override
  String get resetPasswordNewLabel => 'Nova senha';

  @override
  String get resetPasswordNewRequired => 'Digite sua nova senha.';

  @override
  String get resetPasswordSave => 'Salvar senha';

  @override
  String get onboardingSlide1Title => 'Detecte os vazamentos de dinheiro';

  @override
  String get onboardingSlide1Body =>
      'Aqueles pequenos gastos formiga que escapam sem você perceber. O leakless os torna visíveis para você retomar o controle.';

  @override
  String get onboardingSlide2Title => 'Controlem os gastos em casal';

  @override
  String get onboardingSlide2Body =>
      'Um livro de contas compartilhado e em tempo real. Se um gasta, ambos sabem na hora.';

  @override
  String get onboardingSlide3Title => 'Poupem juntos com metas claras';

  @override
  String get onboardingSlide3Body =>
      'Definam metas, vejam o progresso líquido se encher e celebrem cada aporte rumo ao futuro que desejam.';

  @override
  String get onboardingSkip => 'Pular';

  @override
  String get onboardingStart => 'Começar';

  @override
  String get onboardingNext => 'Próximo';

  @override
  String get householdSetupPartnerEmailInvalid =>
      'Digite um e-mail válido para seu parceiro.';

  @override
  String householdSetupInvitationFailed(String error) {
    return 'Salvamos o lar, mas não conseguimos criar o convite. $error';
  }

  @override
  String get householdSetupTitle => 'Configurar lar';

  @override
  String get householdSetupPreparing => 'Preparando seu lar…';

  @override
  String get householdSetupLoadErrorTitle => 'Não conseguimos carregar seu lar';

  @override
  String get householdSetupNoHouseholdTitle => 'Sua conta ainda não tem um lar';

  @override
  String get householdSetupNoHouseholdMessage =>
      'Não mostraremos dados financeiros até recuperar um lar válido.';

  @override
  String get householdSetupWaitingOwnerTitle => 'Aguardando o dono';

  @override
  String get householdSetupWaitingOwnerMessage =>
      'Quem criou este lar deve preencher o nome e a moeda. Atualizaremos este estado quando terminar.';

  @override
  String get householdSetupHeroTitle => 'Vamos tornar este lar seu';

  @override
  String get householdSetupHeroSubtitle =>
      'Configure a base compartilhada. Você poderá ajustá-la depois.';

  @override
  String get householdNameLabel => 'Nome do lar';

  @override
  String get householdNameHint => 'Nossa casa';

  @override
  String get householdNameRequired => 'Digite um nome para o lar.';

  @override
  String get householdCurrencyLabel => 'Moeda principal';

  @override
  String get householdCurrencyNote =>
      'A moeda só pode mudar enquanto o lar não tiver valores salvos.';

  @override
  String get householdSetupStep2Title => 'Categorias iniciais';

  @override
  String get householdSetupStep2Subtitle =>
      'Estas categorias já estão prontas para registrar gastos.';

  @override
  String get householdSetupStep3Title => 'Seu parceiro';

  @override
  String get householdSetupStep3Subtitle =>
      'O convite é opcional. Você poderá retomá-lo em Ajustes.';

  @override
  String get householdPartnerEmailLabel => 'E-mail do seu parceiro';

  @override
  String get householdPartnerEmailHint => 'parceiro@email.com';

  @override
  String get householdSetupSaveAndInvite => 'Salvar e convidar';

  @override
  String get householdSetupContinueWithoutInvite => 'Continuar sem convidar';

  @override
  String get categoriesReviewLoadError =>
      'Não conseguimos carregar as categorias. Tente novamente antes de continuar.';

  @override
  String get categoriesReviewEmpty => 'Não encontramos categorias iniciais.';

  @override
  String get householdSetupErrorNotOwner =>
      'Apenas quem criou este lar pode configurá-lo.';

  @override
  String get householdSetupErrorCurrencyLocked =>
      'Este lar já tem valores. Mudar a moeda poderia reinterpretá-los, então mantemos a moeda atual.';

  @override
  String get householdSetupErrorGeneric =>
      'Não conseguimos salvar o lar. Tente novamente.';

  @override
  String get invitationShareSubject => 'Convite para o nosso lar no leakless';

  @override
  String invitationShareText(String link, String code) {
    return 'Junte-se ao nosso lar no leakless.\n\n$link\n\nSe o link não abrir, cole este código:\n$code';
  }

  @override
  String get invitationShareFailed =>
      'Não conseguimos abrir o menu de compartilhamento.';

  @override
  String get invitationsTitle => 'Convidar seu parceiro';

  @override
  String get invitationsNoHousehold =>
      'Não encontramos um lar ativo para convidar.';

  @override
  String get invitationsNotOwner =>
      'Apenas quem criou este lar pode enviar convites.';

  @override
  String get invitationEmailRequired => 'Digite o e-mail dele(a).';

  @override
  String get invitationCreate => 'Criar convite';

  @override
  String get invitationLinkCopied => 'Link copiado.';

  @override
  String get invitationCodeCopied => 'Código copiado.';

  @override
  String get invitationHaveCode => 'Tenho um código de convite';

  @override
  String get invitationsIntroTitleFallback => 'Compartilhar o lar';

  @override
  String get invitationsIntroSubtitle =>
      'Gere um link de uso único. Ele só funciona com o e-mail que você indicar.';

  @override
  String invitationExpiresOn(String date) {
    return 'Vence em $date';
  }

  @override
  String get invitationTitle => 'Convite';

  @override
  String get invitationShare => 'Compartilhar convite';

  @override
  String get invitationCopyLink => 'Copiar link';

  @override
  String get invitationCopyCode => 'Copiar código';

  @override
  String get invitationRevoke => 'Revogar convite';

  @override
  String get invitationNoLongerShareable =>
      'Este código não pode mais ser compartilhado.';

  @override
  String get invitationStatusPending => 'Pendente';

  @override
  String get invitationStatusAccepted => 'Aceito';

  @override
  String get invitationStatusCancelled => 'Revogado';

  @override
  String get invitationStatusExpired => 'Expirado';

  @override
  String get invitationCodeInvalidFormat =>
      'O código deve ter 64 caracteres hexadecimais.';

  @override
  String get invitationExpiredMessage => 'O convite expirou.';

  @override
  String get invitationCancelledMessage => 'O convite foi revogado.';

  @override
  String get invitationAlreadyUsedMessage => 'Este convite já foi usado.';

  @override
  String get invitationPersistenceFailed =>
      'Mantenha o app aberto: não conseguimos salvar a tentativa com segurança.';

  @override
  String get invitationOpenFailed => 'Não conseguimos abrir este convite.';

  @override
  String get invitationSuccessHeroTitle => 'Vocês estão conectados';

  @override
  String get invitationHeroTitle => 'Um lar, para dois';

  @override
  String get invitationPasteCodeTitle => 'Cole seu código';

  @override
  String get invitationPasteCodeSubtitle =>
      'Você pode abrir o link ou colar aqui o código que compartilharam com você.';

  @override
  String get invitationCodeFieldHint => 'Código de 64 caracteres';

  @override
  String get invitationReview => 'Revisar convite';

  @override
  String get invitationHouseholdFallback => 'Lar compartilhado';

  @override
  String invitationInviterInvited(String inviter) {
    return '$inviter convidou você para compartilhar este lar.';
  }

  @override
  String get invitationInviterFallback => 'Seu parceiro';

  @override
  String invitationValidUntil(String date) {
    return 'Válido até $date';
  }

  @override
  String get invitationAcceptJoin => 'Aceitar e entrar';

  @override
  String get invitationNotNow => 'Agora não';

  @override
  String get invitationUseAnotherAccount => 'Usar outra conta';

  @override
  String get invitationDiscard => 'Descartar convite';

  @override
  String get invitationAlreadyMember => 'Você já pertencia a este lar.';

  @override
  String get invitationAcceptedSuccess =>
      'O convite foi aceito. Agora vocês podem ver suas finanças compartilhadas.';

  @override
  String get invitationGoHome => 'Ir para o início';

  @override
  String get profileImageTooLarge => 'A imagem é muito grande. Tente outra.';

  @override
  String get profileUpdated => 'Perfil atualizado.';

  @override
  String get profileChangeAvatarTitle => 'Alterar avatar';

  @override
  String get profileEditTitle => 'Editar perfil';

  @override
  String get profileLoading => 'Carregando seu perfil…';

  @override
  String get profileLoadErrorTitle => 'Não conseguimos carregar seu perfil';

  @override
  String get profileNoProfileTitle => 'Sem perfil';

  @override
  String get profileNoProfileMessage =>
      'Entre novamente para editar seu perfil.';

  @override
  String get profileNameLabel => 'Nome visível';

  @override
  String get profileNameHint => 'Como seu parceiro vê você';

  @override
  String get profileNameRequired => 'Digite um nome visível.';

  @override
  String get profileCurrencyLabel => 'Moeda';

  @override
  String get profileAvatarFailed =>
      'Não conseguimos usar essa imagem. Tente novamente.';

  @override
  String get profileErrorGeneric =>
      'Não conseguimos salvar as alterações. Tente novamente.';

  @override
  String get pickerErrorPhotoAccessDenied =>
      'Permita o acesso às suas fotos em Ajustes para escolher um avatar.';

  @override
  String get pickerErrorCameraAccessDenied =>
      'Permita o acesso à câmera em Ajustes para tirar uma foto.';

  @override
  String get pickerErrorGeneric =>
      'Não conseguimos abrir o seletor de imagens. Tente novamente.';

  @override
  String get dashboardLoading => 'Carregando seu painel…';

  @override
  String get dashboardLoadErrorTitle => 'Não foi possível carregar o painel';

  @override
  String get dashboardLoadErrorMessage => 'Tente novamente em instantes.';

  @override
  String get dashboardAvailableBalance => 'Saldo disponível';

  @override
  String get dashboardRecentActivity => 'Atividade recente';

  @override
  String get dashboardSeeAll => 'Ver tudo';

  @override
  String get dashboardSavingsRate => 'Taxa de poupança real';

  @override
  String get dashboardRecurringExpenses => 'Despesas recorrentes';

  @override
  String get dashboardLimitAlerts => 'Alertas de limites';

  @override
  String get dashboardSavingsRateShort => 'taxa de poupança';

  @override
  String dashboardLeak(String amount) {
    return 'Vazamento $amount';
  }

  @override
  String get transactionsLoadError => 'Não foi possível carregar o histórico';

  @override
  String get transactionsEmptyTitle => 'Sem movimentos';

  @override
  String get transactionsEmptyMessage =>
      'Ajuste os filtros ou registre sua primeira despesa.';

  @override
  String get transactionsFilterUncategorized => 'Sem categoria';

  @override
  String get transactionFallbackTitle => 'Movimento';

  @override
  String get errorAuthSession => 'Não foi possível verificar sua sessão.';

  @override
  String get errorNetwork => 'Verifique sua conexão com a internet.';

  @override
  String get errorNotFound => 'Não encontramos o que você procurava.';

  @override
  String get errorServer => 'Algo falhou no servidor. Tente novamente.';

  @override
  String get errorUnexpected => 'Ocorreu um erro inesperado.';

  @override
  String get authErrorInvalidCredentials => 'E-mail ou senha incorretos.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Confirme seu e-mail antes de entrar. Verifique sua caixa de entrada.';

  @override
  String get authErrorEmailExists =>
      'Já existe uma conta com este e-mail. Entre.';

  @override
  String get authErrorWeakPassword =>
      'A senha é muito fraca. Use ao menos 6 caracteres.';

  @override
  String get authErrorSamePassword =>
      'A nova senha deve ser diferente da anterior.';

  @override
  String get authErrorInvalidEmail => 'O e-mail não é válido.';

  @override
  String get authErrorSignupDisabled =>
      'O cadastro está desativado por enquanto.';

  @override
  String get authErrorRateLimit =>
      'Muitas tentativas. Aguarde um momento e tente novamente.';

  @override
  String get authErrorGeneric =>
      'Não foi possível concluir a operação. Tente novamente.';

  @override
  String get authErrorUnexpected =>
      'Ocorreu um erro inesperado. Tente novamente.';

  @override
  String get invitationErrorInvalidEmail => 'Digite um e-mail válido.';

  @override
  String get invitationErrorInvalidExpiry =>
      'A duração do convite não é válida.';

  @override
  String get invitationErrorCannotInviteSelf =>
      'Você não pode convidar seu próprio e-mail.';

  @override
  String get invitationErrorNotOwner =>
      'Somente quem criou este lar pode convidar.';

  @override
  String get invitationErrorAlreadyMember =>
      'Essa pessoa já pertence a este lar.';

  @override
  String get invitationErrorInvalidToken =>
      'O link ou código do convite não é válido.';

  @override
  String get invitationErrorEmailMismatch =>
      'Este convite foi enviado a outro e-mail. Use essa conta para continuar.';

  @override
  String get invitationErrorNotFound => 'Não encontramos este convite.';

  @override
  String get invitationErrorAcceptedCannotCancel =>
      'Um convite aceito não pode mais ser revogado.';

  @override
  String get invitationErrorHouseholdNotEmpty =>
      'Seu lar atual contém dados. Não podemos movê-los automaticamente.';

  @override
  String get invitationErrorProfileNotFound =>
      'Não encontramos seu perfil. Tente novamente.';

  @override
  String get invitationErrorGeneric =>
      'Não foi possível concluir o convite. Tente novamente.';

  @override
  String get currencyCAD => 'Dólar canadense';

  @override
  String get currencyUSD => 'Dólar americano';

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
  String get currencyBRL => 'Real brasileiro';

  @override
  String get currencyGBP => 'Libra esterlina';

  @override
  String get currencyJPY => 'Iene japonês';

  @override
  String get currencyCHF => 'Franco suíço';

  @override
  String get insightsTitle => 'Dashboard';

  @override
  String get insightsLoading => 'Carregando suas estatísticas…';

  @override
  String get insightsErrorTitle => 'Não conseguimos carregar suas estatísticas';

  @override
  String get insightsErrorMessage => 'Verifique sua conexão e tente novamente.';

  @override
  String get insightsRetry => 'Tentar de novo';

  @override
  String get insightsEmptyTitle => 'Ainda não há gastos';

  @override
  String get insightsEmptyMessage =>
      'Registre seu primeiro gasto para ver as estatísticas do mês.';

  @override
  String get insightsEmptyAction => 'Registrar um gasto';

  @override
  String get insightsMonthSummaryTitle => 'Resumo do mês';

  @override
  String get insightsSpentLabel => 'Gasto neste mês';

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
    return 'Restam $amount';
  }

  @override
  String insightsOverBudgetBy(String amount) {
    return 'Você passou $amount';
  }

  @override
  String get insightsNoBudgetNote =>
      'Você ainda não definiu um orçamento este mês. Crie um para acompanhar seu ritmo.';

  @override
  String get insightsCreateBudget => 'Criar orçamento';

  @override
  String get insightsStatusOnTrack => 'Você está em dia com seu orçamento.';

  @override
  String get insightsStatusAhead =>
      'Você está abaixo do ritmo previsto. Muito bem!';

  @override
  String get insightsStatusAtRisk =>
      'Você está gastando mais rápido do que o previsto.';

  @override
  String get insightsStatusOver => 'Você ultrapassou o orçamento do mês.';

  @override
  String get insightsPaceTitle => 'Ritmo de gasto';

  @override
  String get insightsPaceExpected => 'Esperado até hoje';

  @override
  String get insightsPaceActual => 'Gasto até hoje';

  @override
  String insightsPaceAhead(String amount) {
    return 'Você está $amount abaixo do ritmo.';
  }

  @override
  String insightsPaceBehind(String amount) {
    return 'Você está $amount acima do ritmo.';
  }

  @override
  String get insightsPaceOnPace => 'Exatamente no ritmo previsto.';

  @override
  String insightsPaceReduce(String amount) {
    return 'Reduza $amount para fechar dentro do orçamento.';
  }

  @override
  String get insightsCategoriesTitle => 'Gasto por categoria';

  @override
  String insightsCategoryShare(int percent) {
    return '$percent% do total';
  }

  @override
  String get insightsCategoryUnnamed => 'Categoria';

  @override
  String insightsCategoryRemaining(String amount) {
    return 'Restam $amount';
  }

  @override
  String insightsCategoryOverBy(String amount) {
    return 'Excedido em $amount';
  }

  @override
  String get insightsPieTitle => 'Distribuição por categoria';

  @override
  String get insightsPieOthers => 'Outros';

  @override
  String get insightsPieCenterLabel => 'gasto';

  @override
  String get insightsRunawayTitle => 'Categorias fora de controle';

  @override
  String insightsRunawayBadge(int percent) {
    return '+$percent%';
  }

  @override
  String insightsRunawayCompare(String average) {
    return 'Média de 3 meses: $average';
  }

  @override
  String get insightsTrendTitle => 'Comparativo histórico';

  @override
  String get insightsTrendVsPreviousLabel => 'Mês anterior';

  @override
  String get insightsTrendVsAverageLabel => 'Média de 3 meses';

  @override
  String insightsTrendChangeUp(int percent) {
    return '$percent% a mais';
  }

  @override
  String insightsTrendChangeDown(int percent) {
    return '$percent% a menos';
  }

  @override
  String get insightsTrendChangeStable => 'Parecido';

  @override
  String get insightsTrendNoPreviousMonth =>
      'Ainda não há dados do mês anterior.';

  @override
  String get insightsProjectionTitle => 'Projeção de fechamento';

  @override
  String get insightsProjectionInsufficientData =>
      'Precisamos de mais alguns dias deste mês para projetar seu fechamento.';

  @override
  String get insightsProjectionLabel => 'Estimativa para o fim do mês';

  @override
  String insightsProjectionOverBudget(String amount) {
    return 'Você ultrapassaria seu orçamento em $amount.';
  }

  @override
  String get insightsProjectionWithinBudget =>
      'Você fecharia o mês dentro do orçamento.';

  @override
  String get insightsDailyTitle => 'Gasto diário';

  @override
  String get insightsDailyAverageLabel => 'Média diária';

  @override
  String get insightsDailyMostExpensiveLabel => 'Dia mais caro';

  @override
  String get insightsDailyNoSpendLabel => 'Dias sem gasto';

  @override
  String insightsDailyNoSpendValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
      zero: '0 dias',
    );
    return '$_temp0';
  }

  @override
  String get insightsWeekdayTitle => 'Padrão semanal';

  @override
  String get insightsWeekdayMostExpensiveLabel => 'Dia de maior gasto';

  @override
  String get insightsWeekdayLeastExpensiveLabel => 'Dia de menor gasto';

  @override
  String get insightsLastActivityTitle => 'Última atividade por categoria';

  @override
  String get insightsLastActivityToday => 'Hoje';

  @override
  String get insightsLastActivityYesterday => 'Ontem';

  @override
  String insightsLastActivityDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Há $count dias',
      one: 'Há 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get insightsUncategorizedTitle => 'Sem categoria';

  @override
  String insightsUncategorizedMessage(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count despesas',
      one: '1 despesa',
    );
    return '$_temp0 sem categoria este mês, totalizando $amount.';
  }

  @override
  String get insightsUncategorizedAction => 'Categorizar agora';

  @override
  String get insightsRecommendationsTitle => 'Recomendações';

  @override
  String insightsRecommendationReduceCategory(String amount, String category) {
    return 'Para fechar o mês dentro do orçamento, reduza cerca de $amount em $category.';
  }

  @override
  String insightsRecommendationRunaway(String category) {
    return '$category está gastando bem mais que o habitual este mês. Vale a pena revisar.';
  }

  @override
  String get insightsRecommendationAllOnTrack =>
      'Você está indo muito bem este mês! Continue assim.';

  @override
  String get quickEntryTitle => 'Registro rápido';
}
