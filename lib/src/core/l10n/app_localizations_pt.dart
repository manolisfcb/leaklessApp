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
  String get quickEntryScanReceipt => 'Escanear recibo';

  @override
  String get quickEntryScanningReceipt => 'Lendo recibo…';

  @override
  String get quickEntryTakePhoto => 'Tirar uma foto';

  @override
  String get quickEntryPickFromGallery => 'Escolher da galeria';

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
}
