import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../domain/enums/household_invitation_status.dart';
import '../../../domain/models/household_invitation.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../application/household_providers.dart';
import '../application/invitation_intent_controller.dart';
import '../application/invitation_links.dart';
import 'invitation_error_message.dart';

enum _InvitationView { code, loading, preview, error, success }

/// Recipient experience for safely previewing and accepting an invitation.
class InvitationScreen extends ConsumerStatefulWidget {
  const InvitationScreen({super.key});

  @override
  ConsumerState<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends ConsumerState<InvitationScreen> {
  final _code = TextEditingController();
  _InvitationView _view = _InvitationView.code;
  HouseholdInvitation? _preview;
  String? _activeToken;
  String? _scheduledToken;
  String? _error;
  String? _errorCode;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _scheduleInspection(String token) {
    if (_activeToken == token || _scheduledToken == token) return;
    _scheduledToken = token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduledToken = null;
      if (_activeToken == token) return;
      unawaited(_inspect(token));
    });
  }

  Future<void> _submitCode() async {
    final token = InvitationLinks.normalizeToken(_code.text);
    if (token == null) {
      setState(() {
        _view = _InvitationView.error;
        _error = context.l10n.invitationCodeInvalidFormat;
        _errorCode = 'invalid_invitation_token';
      });
      return;
    }
    await ref.read(invitationIntentControllerProvider.notifier).capture(token);
    if (mounted) await _inspect(token);
  }

  Future<void> _inspect(String token) async {
    setState(() {
      _activeToken = token;
      _view = _InvitationView.loading;
      _preview = null;
      _error = null;
      _errorCode = null;
    });
    final notifier = ref.read(householdInvitationsControllerProvider.notifier);
    final result = await notifier.inspect(token);
    final actionState = ref.read(householdInvitationsControllerProvider);
    notifier.clear();
    if (!mounted) return;
    if (result == null) {
      final error =
          actionState.error ?? StateError('Unable to inspect invitation');
      setState(() {
        _view = _InvitationView.error;
        _error = invitationErrorMessage(error);
        _errorCode = error is ServerException ? error.code : null;
      });
      return;
    }
    setState(() {
      _preview = result;
      _view = result.status == HouseholdInvitationStatus.pending
          ? _InvitationView.preview
          : _InvitationView.error;
      if (_view == _InvitationView.error) {
        _error = switch (result.status) {
          HouseholdInvitationStatus.expired =>
            context.l10n.invitationExpiredMessage,
          HouseholdInvitationStatus.cancelled =>
            context.l10n.invitationCancelledMessage,
          HouseholdInvitationStatus.accepted =>
            context.l10n.invitationAlreadyUsedMessage,
          HouseholdInvitationStatus.pending => null,
        };
      }
    });
  }

  Future<void> _accept() async {
    final token = _activeToken;
    if (token == null) return;
    setState(() {
      _view = _InvitationView.loading;
      _error = null;
    });
    final notifier = ref.read(householdInvitationsControllerProvider.notifier);
    final result = await notifier.accept(token);
    final actionState = ref.read(householdInvitationsControllerProvider);
    notifier.clear();
    if (!mounted) return;
    if (result == null) {
      final error =
          actionState.error ?? StateError('Unable to accept invitation');
      setState(() {
        _view = _InvitationView.error;
        _error = invitationErrorMessage(error);
        _errorCode = error is ServerException ? error.code : null;
      });
      return;
    }
    await ref.read(invitationIntentControllerProvider.notifier).discard();
    if (!mounted) return;
    setState(() {
      _view = _InvitationView.success;
      _preview = result;
      _activeToken = null;
      _code.clear();
    });
  }

  Future<void> _discard({bool navigate = true}) async {
    await ref.read(invitationIntentControllerProvider.notifier).discard();
    if (!mounted) return;
    setState(() {
      _activeToken = null;
      _preview = null;
      _error = null;
      _errorCode = null;
      _view = _InvitationView.code;
      _code.clear();
    });
    if (navigate) context.go(AppRoutes.dashboard);
  }

  Future<void> _useAnotherAccount() async {
    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final intent = ref.watch(invitationIntentControllerProvider);
    if (intent.token case final token?) _scheduleInspection(token);

    return GlassScaffold(
      appBar: AppBar(title: Text(l10n.invitationTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.huge,
        ),
        children: [
          _InvitationHero(view: _view),
          AppSpacing.gapXl,
          if (intent.persistenceFailed && intent.token != null) ...[
            _InlineNotice(message: l10n.invitationPersistenceFailed),
            AppSpacing.gapLg,
          ],
          switch (_view) {
            _InvitationView.code => _CodeCard(
              controller: _code,
              onSubmit: _submitCode,
            ),
            _InvitationView.loading => const GlassCard(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            _InvitationView.preview => _PreviewCard(
              invitation: _preview!,
              onAccept: _accept,
              onReject: _discard,
            ),
            _InvitationView.error => _ErrorCard(
              message: _error ?? l10n.invitationOpenFailed,
              emailMismatch: _errorCode == 'invitation_email_mismatch',
              onUseAnotherAccount: _useAnotherAccount,
              onDiscard: _discard,
            ),
            _InvitationView.success => _SuccessCard(
              alreadyAccepted: _preview?.alreadyAccepted ?? false,
              onContinue: () => context.go(AppRoutes.dashboard),
            ),
          },
        ],
      ),
    );
  }
}

class _InvitationHero extends StatelessWidget {
  const _InvitationHero({required this.view});

  final _InvitationView view;

  @override
  Widget build(BuildContext context) {
    final success = view == _InvitationView.success;
    final color = success ? context.colors.income : context.colors.goal;
    return Column(
      children: [
        Container(
          height: 82,
          width: 82,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            boxShadow: AppShadows.glow(color),
          ),
          child: Icon(
            success ? CupertinoIcons.check_mark : CupertinoIcons.person_2_fill,
            color: color,
            size: 38,
          ),
        ),
        AppSpacing.gapLg,
        Text(
          success
              ? context.l10n.invitationSuccessHeroTitle
              : context.l10n.invitationHeroTitle,
          style: AppTypography.headlineMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.invitationPasteCodeTitle, style: AppTypography.titleLarge),
          AppSpacing.gapSm,
          Text(
            l10n.invitationPasteCodeSubtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          AppSpacing.gapLg,
          TextField(
            controller: controller,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-fA-F0-9]')),
              LengthLimitingTextInputFormatter(64),
            ],
            decoration: InputDecoration(
              hintText: l10n.invitationCodeFieldHint,
              prefixIcon: const Icon(CupertinoIcons.number),
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          AppSpacing.gapLg,
          GlassButton(
            label: l10n.invitationReview,
            icon: CupertinoIcons.arrow_right,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.invitation,
    required this.onAccept,
    required this.onReject,
  });

  final HouseholdInvitation invitation;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeName = Localizations.localeOf(context).toString();
    final expires = invitation.expiresAt == null
        ? null
        : DateFormat.MMMMd(localeName)
              .add_Hm()
              .format(invitation.expiresAt!.toLocal());
    return GlassCard(
      strong: true,
      gradientGlow: context.colors.goal,
      child: Column(
        children: [
          Text(
            invitation.householdName ?? l10n.invitationHouseholdFallback,
            style: AppTypography.headlineMedium,
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapSm,
          Text(
            l10n.invitationInviterInvited(
              invitation.inviterDisplayName ?? l10n.invitationInviterFallback,
            ),
            style: AppTypography.bodyLarge.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (invitation.invitedEmail case final email?) ...[
            AppSpacing.gapLg,
            _DetailRow(icon: CupertinoIcons.mail, text: email),
          ],
          if (expires != null) ...[
            AppSpacing.gapSm,
            _DetailRow(
              icon: CupertinoIcons.clock,
              text: l10n.invitationValidUntil(expires),
            ),
          ],
          AppSpacing.gapXl,
          GlassButton(
            label: l10n.invitationAcceptJoin,
            icon: CupertinoIcons.check_mark,
            onPressed: onAccept,
          ),
          AppSpacing.gapSm,
          GlassButton(
            label: l10n.invitationNotNow,
            variant: GlassButtonVariant.glass,
            onPressed: onReject,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: context.colors.textSecondary),
      AppSpacing.gapSm,
      Expanded(
        child: Text(
          text,
          style: AppTypography.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ),
    ],
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.emailMismatch,
    required this.onUseAnotherAccount,
    required this.onDiscard,
  });

  final String message;
  final bool emailMismatch;
  final VoidCallback onUseAnotherAccount;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) => GlassCard(
    borderColor: context.colors.expense.withValues(alpha: 0.4),
    child: Column(
      children: [
        Icon(
          CupertinoIcons.exclamationmark_circle,
          size: 38,
          color: context.colors.expense,
        ),
        AppSpacing.gapMd,
        Text(
          message,
          style: AppTypography.bodyLarge,
          textAlign: TextAlign.center,
        ),
        if (emailMismatch) ...[
          AppSpacing.gapLg,
          GlassButton(
            label: context.l10n.invitationUseAnotherAccount,
            icon: CupertinoIcons.person_crop_circle_badge_xmark,
            onPressed: onUseAnotherAccount,
          ),
        ],
        AppSpacing.gapSm,
        GlassButton(
          label: context.l10n.invitationDiscard,
          variant: GlassButtonVariant.glass,
          accent: context.colors.expense,
          onPressed: onDiscard,
        ),
      ],
    ),
  );
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.alreadyAccepted, required this.onContinue});

  final bool alreadyAccepted;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => GlassCard(
    gradientGlow: context.colors.income,
    child: Column(
      children: [
        Text(
          alreadyAccepted
              ? context.l10n.invitationAlreadyMember
              : context.l10n.invitationAcceptedSuccess,
          style: AppTypography.bodyLarge,
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapXl,
        GlassButton(
          label: context.l10n.invitationGoHome,
          icon: CupertinoIcons.house_fill,
          accent: context.colors.income,
          onPressed: onContinue,
        ),
      ],
    ),
  );
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => GlassCard(
    borderColor: context.colors.alert.withValues(alpha: 0.4),
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Row(
      children: [
        Icon(
          CupertinoIcons.exclamationmark_triangle,
          color: context.colors.alert,
        ),
        AppSpacing.gapMd,
        Expanded(child: Text(message, style: AppTypography.bodySmall)),
      ],
    ),
  );
}
