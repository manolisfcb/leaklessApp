import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/category_names.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/currencies.dart';
import '../../../domain/models/household.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../../transactions/application/categories_providers.dart';
import '../application/household_providers.dart';
import 'invitation_error_message.dart';

final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

/// Post-auth setup gate and reusable household settings form.
class HouseholdSetupScreen extends ConsumerStatefulWidget {
  const HouseholdSetupScreen({this.isOnboarding = true, super.key});

  final bool isOnboarding;

  @override
  ConsumerState<HouseholdSetupScreen> createState() =>
      _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends ConsumerState<HouseholdSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _partnerEmail = TextEditingController();
  var _currency = 'USD';
  var _initializedHouseholdId = '';
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _partnerEmail.dispose();
    super.dispose();
  }

  void _initialize(Household household) {
    if (_initializedHouseholdId == household.id) return;
    _initializedHouseholdId = household.id;
    _name.text = household.name;
    _currency = household.currency;
  }

  Future<void> _save(Household household, {required bool invite}) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _partnerEmail.text.trim();
    if (invite && !_emailPattern.hasMatch(email)) {
      setState(() => _error = context.l10n.householdSetupPartnerEmailInvalid);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final setup = ref.read(householdSetupControllerProvider.notifier);
    final configured = await setup.save(
      householdId: household.id,
      name: _name.text,
      currency: _currency,
    );
    if (!mounted) return;
    if (configured == null) {
      final state = ref.read(householdSetupControllerProvider);
      setState(() {
        _submitting = false;
        _error = _setupErrorMessage(
          context.l10n,
          state.error ?? StateError('Household setup failed'),
        );
      });
      return;
    }

    if (invite) {
      final invitations = ref.read(
        householdInvitationsControllerProvider.notifier,
      );
      final invitation = await invitations.create(
        householdId: configured.id,
        email: email,
      );
      final invitationState = ref.read(householdInvitationsControllerProvider);
      invitations.clear();
      if (!mounted) return;
      if (invitation?.token == null) {
        setState(() {
          _submitting = false;
          _error = context.l10n.householdSetupInvitationFailed(
            invitationErrorMessage(
              invitationState.error ?? StateError('Invitation failed'),
            ),
          );
        });
        return;
      }
      await setup.refreshScope();
      if (!mounted) return;
      context.go(AppRoutes.householdInvitations, extra: invitation);
      return;
    }

    await setup.refreshScope();
    if (!mounted) return;
    if (widget.isOnboarding) {
      context.go(AppRoutes.dashboard);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final householdAsync = ref.watch(currentHouseholdProvider);
    final household = householdAsync.asData?.value;
    final user = ref.watch(currentUserProvider);

    return GlassScaffold(
      appBar: widget.isOnboarding
          ? null
          : AppBar(
              leading: IconButton(
                onPressed: context.pop,
                icon: const Icon(CupertinoIcons.back),
              ),
              title: Text(l10n.householdSetupTitle),
            ),
      body: switch (householdAsync) {
        AsyncLoading() => AppLoader(message: l10n.householdSetupPreparing),
        AsyncError() => _SetupUnavailable(
          title: l10n.householdSetupLoadErrorTitle,
          message: l10n.commonCheckConnection,
          onRetry: _retry,
        ),
        _ when household == null => _SetupUnavailable(
          title: l10n.householdSetupNoHouseholdTitle,
          message: l10n.householdSetupNoHouseholdMessage,
          onRetry: _retry,
        ),
        _ when household.ownerId != user?.id => _SetupUnavailable(
          title: l10n.householdSetupWaitingOwnerTitle,
          message: l10n.householdSetupWaitingOwnerMessage,
          onRetry: _retry,
        ),
        _ => _buildForm(context, household),
      },
    );
  }

  Widget _buildForm(BuildContext context, Household household) {
    _initialize(household);
    final colors = context.colors;
    final l10n = context.l10n;
    final categories = ref.watch(categoriesProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        widget.isOnboarding ? AppSpacing.xxl : AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.huge,
      ),
      children: [
        if (widget.isOnboarding) ...[
          Icon(CupertinoIcons.house_fill, size: 48, color: colors.primary),
          AppSpacing.gapMd,
          Text(
            l10n.householdSetupHeroTitle,
            textAlign: TextAlign.center,
            style: AppTypography.displaySmall,
          ),
          AppSpacing.gapSm,
          Text(
            l10n.householdSetupHeroSubtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          AppSpacing.gapXl,
        ],
        Form(
          key: _formKey,
          child: Column(
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepTitle(
                      number: '1',
                      title: l10n.settingsHouseholdNameCurrency,
                      icon: CupertinoIcons.house,
                    ),
                    AppSpacing.gapLg,
                    TextFormField(
                      controller: _name,
                      enabled: !_submitting,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      maxLength: 80,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.householdNameLabel,
                        hintText: l10n.householdNameHint,
                        prefixIcon: const Icon(CupertinoIcons.home),
                      ),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? l10n.householdNameRequired
                          : null,
                    ),
                    AppSpacing.gapMd,
                    DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: InputDecoration(
                        labelText: l10n.householdCurrencyLabel,
                        prefixIcon: const Icon(
                          CupertinoIcons.money_dollar_circle,
                        ),
                      ),
                      items: [
                        if (!supportedCurrencies.any(
                          (entry) => entry.$1 == _currency,
                        ))
                          DropdownMenuItem(
                            value: _currency,
                            child: Text(_currency),
                          ),
                        for (final entry in supportedCurrencies)
                          DropdownMenuItem(
                            value: entry.$1,
                            child: Text('${entry.$1} · ${entry.$2}'),
                          ),
                      ],
                      onChanged: _submitting
                          ? null
                          : (value) =>
                                setState(() => _currency = value ?? _currency),
                    ),
                    AppSpacing.gapSm,
                    Text(
                      l10n.householdCurrencyNote,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapLg,
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepTitle(
                      number: '2',
                      title: l10n.householdSetupStep2Title,
                      icon: CupertinoIcons.square_grid_2x2,
                    ),
                    AppSpacing.gapSm,
                    Text(
                      l10n.householdSetupStep2Subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    AppSpacing.gapMd,
                    _CategoryReview(categories: categories),
                  ],
                ),
              ),
              if (widget.isOnboarding) ...[
                AppSpacing.gapLg,
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StepTitle(
                        number: '3',
                        title: l10n.householdSetupStep3Title,
                        icon: CupertinoIcons.person_2,
                      ),
                      AppSpacing.gapSm,
                      Text(
                        l10n.householdSetupStep3Subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      AppSpacing.gapMd,
                      TextFormField(
                        controller: _partnerEmail,
                        enabled: !_submitting,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                        decoration: InputDecoration(
                          labelText: l10n.householdPartnerEmailLabel,
                          hintText: l10n.householdPartnerEmailHint,
                          prefixIcon: const Icon(CupertinoIcons.mail),
                        ),
                        onFieldSubmitted: (_) => _save(household, invite: true),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_error != null) ...[AppSpacing.gapLg, _ErrorCard(message: _error!)],
        AppSpacing.gapXl,
        if (widget.isOnboarding) ...[
          GlassButton(
            label: l10n.householdSetupSaveAndInvite,
            icon: CupertinoIcons.paperplane,
            loading: _submitting,
            onPressed: _submitting
                ? null
                : () => _save(household, invite: true),
          ),
          AppSpacing.gapSm,
          TextButton(
            onPressed: _submitting
                ? null
                : () => _save(household, invite: false),
            child: Text(l10n.householdSetupContinueWithoutInvite),
          ),
        ] else
          GlassButton(
            label: l10n.commonSaveChanges,
            icon: CupertinoIcons.checkmark_alt,
            loading: _submitting,
            onPressed: _submitting
                ? null
                : () => _save(household, invite: false),
          ),
      ],
    );
  }

  void _retry() {
    ref.invalidate(currentHouseholdProvider);
    ref.invalidate(householdSetupStateProvider);
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({
    required this.number,
    required this.title,
    required this.icon,
  });

  final String number;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: context.colors.goalSoft,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          number,
          style: AppTypography.labelLarge.copyWith(
            color: context.colors.primary,
          ),
        ),
      ),
      AppSpacing.gapMd,
      Expanded(child: Text(title, style: AppTypography.titleLarge)),
      Icon(icon, color: context.colors.textSecondary),
    ],
  );
}

class _CategoryReview extends StatelessWidget {
  const _CategoryReview({required this.categories});

  final AsyncValue<List<TransactionCategory>> categories;

  @override
  Widget build(BuildContext context) => switch (categories) {
    AsyncLoading() => const LinearProgressIndicator(),
    AsyncError() => Text(
      context.l10n.categoriesReviewLoadError,
      style: AppTypography.bodySmall.copyWith(color: context.colors.expense),
    ),
    AsyncData(:final value) when value.isEmpty => Text(
      context.l10n.categoriesReviewEmpty,
      style: AppTypography.bodySmall.copyWith(color: context.colors.alert),
    ),
    AsyncData(:final value) => Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final category in value)
          Chip(
            avatar: Icon(CategoryIcons.forKey(category.iconName), size: 17),
            label: Text(categoryDisplayName(category, context.l10n)),
          ),
      ],
    ),
  };
}

class _SetupUnavailable extends StatelessWidget {
  const _SetupUnavailable({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => AppEmptyState(
    icon: CupertinoIcons.house,
    title: title,
    message: message,
    actionLabel: context.l10n.commonRetry,
    onAction: onRetry,
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => GlassCard(
    borderColor: context.colors.expense,
    child: Row(
      children: [
        Icon(
          CupertinoIcons.exclamationmark_circle,
          color: context.colors.expense,
        ),
        AppSpacing.gapMd,
        Expanded(child: Text(message, style: AppTypography.bodyMedium)),
      ],
    ),
  );
}

String _setupErrorMessage(AppLocalizations l10n, Object error) {
  final code = error is ServerException ? error.code : null;
  return switch (code) {
    'invalid_household_name' => l10n.commonInvalidNameMax80,
    'invalid_currency' => l10n.commonInvalidCurrency,
    'not_household_owner' => l10n.householdSetupErrorNotOwner,
    'currency_change_requires_empty_household' =>
      l10n.householdSetupErrorCurrencyLocked,
    'authentication_required' => l10n.commonSignInToContinue,
    _ => l10n.householdSetupErrorGeneric,
  };
}
