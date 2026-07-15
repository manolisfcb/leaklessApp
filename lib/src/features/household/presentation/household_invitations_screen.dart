import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../domain/enums/household_invitation_status.dart';
import '../../../domain/models/household.dart';
import '../../../domain/models/household_invitation.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../application/household_providers.dart';
import '../application/invitation_links.dart';
import 'invitation_error_message.dart';

final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

/// Owner experience for issuing, sharing and revoking one-time invitations.
class HouseholdInvitationsScreen extends ConsumerStatefulWidget {
  const HouseholdInvitationsScreen({this.initialInvitation, super.key});

  final HouseholdInvitation? initialInvitation;

  @override
  ConsumerState<HouseholdInvitationsScreen> createState() =>
      _HouseholdInvitationsScreenState();
}

class _HouseholdInvitationsScreenState
    extends ConsumerState<HouseholdInvitationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  late HouseholdInvitation? _invitation;
  String? _error;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _invitation = widget.initialInvitation;
    _email.text = widget.initialInvitation?.invitedEmail ?? '';
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _create(Household household) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
      _invitation = null;
    });

    final notifier = ref.read(householdInvitationsControllerProvider.notifier);
    final result = await notifier.create(
      householdId: household.id,
      email: _email.text,
    );
    final actionState = ref.read(householdInvitationsControllerProvider);
    notifier.clear();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result?.token != null) {
        _invitation = result;
      } else {
        _error = invitationErrorMessage(
          actionState.error ?? StateError('Missing invitation token'),
          context.l10n,
        );
      }
    });
  }

  Future<void> _cancel() async {
    final invitation = _invitation;
    if (invitation == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final notifier = ref.read(householdInvitationsControllerProvider.notifier);
    final result = await notifier.cancel(invitation.id);
    final actionState = ref.read(householdInvitationsControllerProvider);
    notifier.clear();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result != null) {
        _invitation = invitation.copyWith(
          status: result.status,
          token: null,
          updatedAt: result.updatedAt,
        );
      } else {
        _error = invitationErrorMessage(
          actionState.error ?? StateError('Unable to revoke invitation'),
          context.l10n,
        );
      }
    });
  }

  Future<void> _copy(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _share(BuildContext buttonContext, String link) async {
    final l10n = buttonContext.l10n;
    final box = buttonContext.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: l10n.invitationShareSubject,
          text: l10n.invitationShareText(link, _invitation!.token ?? ''),
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invitationShareFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final householdAsync = ref.watch(currentHouseholdProvider);
    final household = householdAsync.asData?.value;
    final user = ref.watch(currentUserProvider);
    final isOwner = household != null && household.ownerId == user?.id;

    return GlassScaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(CupertinoIcons.back),
        ),
        title: Text(l10n.invitationsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.huge,
        ),
        children: [
          _IntroCard(householdName: household?.name),
          AppSpacing.gapLg,
          if (householdAsync.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (household == null)
            _NoticeCard(
              icon: CupertinoIcons.exclamationmark_triangle,
              message: l10n.invitationsNoHousehold,
            )
          else if (!isOwner)
            _NoticeCard(
              icon: CupertinoIcons.lock,
              message: l10n.invitationsNotOwner,
            )
          else ...[
            Form(
              key: _formKey,
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.householdPartnerEmailLabel,
                      style: AppTypography.titleMedium,
                    ),
                    AppSpacing.gapMd,
                    TextFormField(
                      controller: _email,
                      enabled: !_loading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                      decoration: InputDecoration(
                        hintText: l10n.householdPartnerEmailHint,
                        prefixIcon: const Icon(CupertinoIcons.mail),
                      ),
                      validator: (value) {
                        final email = (value ?? '').trim();
                        if (email.isEmpty) return l10n.invitationEmailRequired;
                        if (!_emailPattern.hasMatch(email)) {
                          return l10n.commonInvalidEmail;
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _create(household),
                    ),
                    AppSpacing.gapLg,
                    GlassButton(
                      label: l10n.invitationCreate,
                      icon: CupertinoIcons.paperplane,
                      loading: _loading,
                      onPressed: _loading ? null : () => _create(household),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              AppSpacing.gapLg,
              _NoticeCard(
                icon: CupertinoIcons.exclamationmark_circle,
                message: _error!,
                isError: true,
              ),
            ],
            if (_invitation != null) ...[
              AppSpacing.gapLg,
              _InvitationShareCard(
                invitation: _invitation!,
                loading: _loading,
                onCopyLink: (value) => _copy(value, l10n.invitationLinkCopied),
                onCopyCode: (value) => _copy(value, l10n.invitationCodeCopied),
                onShare: _share,
                onCancel: _cancel,
              ),
            ],
          ],
          AppSpacing.gapLg,
          GlassButton(
            label: l10n.invitationHaveCode,
            icon: CupertinoIcons.number,
            variant: GlassButtonVariant.glass,
            onPressed: () => context.push(AppRoutes.invitation),
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({this.householdName});

  final String? householdName;

  @override
  Widget build(BuildContext context) => GlassCard(
    gradientGlow: context.colors.goal,
    child: Column(
      children: [
        Icon(
          CupertinoIcons.person_2_fill,
          size: 42,
          color: context.colors.goal,
        ),
        AppSpacing.gapMd,
        Text(
          householdName ?? context.l10n.invitationsIntroTitleFallback,
          style: AppTypography.headlineMedium,
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapSm,
        Text(
          context.l10n.invitationsIntroSubtitle,
          style: AppTypography.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _InvitationShareCard extends StatelessWidget {
  const _InvitationShareCard({
    required this.invitation,
    required this.loading,
    required this.onCopyLink,
    required this.onCopyCode,
    required this.onShare,
    required this.onCancel,
  });

  final HouseholdInvitation invitation;
  final bool loading;
  final ValueChanged<String> onCopyLink;
  final ValueChanged<String> onCopyCode;
  final Future<void> Function(BuildContext, String) onShare;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeName = Localizations.localeOf(context).toString();
    final token = invitation.token;
    final active =
        invitation.status == HouseholdInvitationStatus.pending && token != null;
    final link = active
        ? InvitationLinks.invitationUri(token).toString()
        : null;
    final expires = invitation.expiresAt == null
        ? null
        : DateFormat.MMMMd(
            localeName,
          ).add_Hm().format(invitation.expiresAt!.toLocal());

    return GlassCard(
      strong: true,
      child: Column(
        children: [
          _StatusPill(status: invitation.status),
          AppSpacing.gapMd,
          Text(
            invitation.invitedEmail ?? l10n.invitationTitle,
            style: AppTypography.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (expires != null && active) ...[
            AppSpacing.gapXs,
            Text(
              l10n.invitationExpiresOn(expires),
              style: AppTypography.bodySmall.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
          if (link != null) ...[
            AppSpacing.gapLg,
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadii.cardRadius,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: QrImageView(
                  data: link,
                  size: 196,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: context.colors.textPrimary,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
            ),
            AppSpacing.gapMd,
            SelectableText(
              token!,
              style: AppTypography.labelSmall.copyWith(
                color: context.colors.textSecondary,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapLg,
            Builder(
              builder: (buttonContext) => GlassButton(
                label: l10n.invitationShare,
                icon: CupertinoIcons.share,
                onPressed: loading ? null : () => onShare(buttonContext, link),
              ),
            ),
            AppSpacing.gapSm,
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => onCopyLink(link),
                    icon: const Icon(CupertinoIcons.link),
                    label: Text(l10n.invitationCopyLink),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => onCopyCode(token),
                    icon: const Icon(CupertinoIcons.doc_on_doc),
                    label: Text(l10n.invitationCopyCode),
                  ),
                ),
              ],
            ),
            AppSpacing.gapSm,
            GlassButton(
              label: l10n.invitationRevoke,
              icon: CupertinoIcons.xmark_circle,
              variant: GlassButtonVariant.glass,
              accent: context.colors.expense,
              loading: loading,
              onPressed: loading ? null : onCancel,
            ),
          ] else ...[
            AppSpacing.gapMd,
            Text(
              l10n.invitationNoLongerShareable,
              style: AppTypography.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final HouseholdInvitationStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, color) = switch (status) {
      HouseholdInvitationStatus.pending => (
        l10n.invitationStatusPending,
        context.colors.alert,
      ),
      HouseholdInvitationStatus.accepted => (
        l10n.invitationStatusAccepted,
        context.colors.income,
      ),
      HouseholdInvitationStatus.cancelled => (
        l10n.invitationStatusCancelled,
        context.colors.expense,
      ),
      HouseholdInvitationStatus.expired => (
        l10n.invitationStatusExpired,
        context.colors.textTertiary,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.pillRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: color),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.message,
    this.isError = false,
  });

  final IconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? context.colors.expense : context.colors.alert;
    return GlassCard(
      borderColor: color.withValues(alpha: 0.35),
      child: Row(
        children: [
          Icon(icon, color: color),
          AppSpacing.gapMd,
          Expanded(child: Text(message, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}
