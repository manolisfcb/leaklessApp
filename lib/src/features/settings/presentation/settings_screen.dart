import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/prefs/locale_controller.dart';
import '../../../core/purchases/purchases_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_providers.dart';
import '../../household/application/household_providers.dart';
import '../../profile/application/profile_providers.dart';
import 'delete_account_sheet.dart';

/// Settings: profile, household, notifications, subscription and sign out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = ref.watch(currentProfileProvider).asData?.value;
    final household = ref.watch(currentHouseholdProvider).asData?.value;
    final isPremium = ref.watch(isPremiumProvider);
    final notifications = ref.watch(notificationPermissionProvider);

    return GlassScaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          120,
        ),
        children: [
          GlassCard(
            onTap: () => context.push(AppRoutes.profileEdit),
            child: Row(
              children: [
                ProfileBubble(
                  initials: profile?.initials ?? '?',
                  imageUrl: profile?.avatarUrl,
                  size: 64,
                ),
                AppSpacing.gapLg,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.displayName ?? 'Tu perfil',
                        style: AppTypography.titleLarge,
                      ),
                      AppSpacing.gapXs,
                      Text(
                        household?.name ?? 'Sin household',
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(CupertinoIcons.chevron_right, color: colors.textTertiary),
              ],
            ),
          ),
          AppSpacing.gapLg,
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                _SettingsRow(
                  icon: CupertinoIcons.house,
                  label: 'Nombre y moneda',
                  value: household == null
                      ? 'Sin hogar'
                      : '${household.name} · ${household.currency}',
                  onTap: household == null
                      ? null
                      : () => context.push(AppRoutes.householdConfiguration),
                ),
                const _RowDivider(),
                _SettingsRow(
                  icon: CupertinoIcons.person_2,
                  label: 'Pareja',
                  value:
                      '${ref.watch(householdMembersProvider).asData?.value.length ?? 0} miembros',
                  onTap: () => context.push(AppRoutes.householdInvitations),
                ),
                const _RowDivider(),
                _SettingsRow(
                  icon: CupertinoIcons.bell,
                  label: 'Notificaciones',
                  value: switch (notifications.asData?.value) {
                    null => '…',
                    final status when status.isGranted => 'Activadas',
                    _ => 'Desactivadas',
                  },
                ),
                const _RowDivider(),
                _SettingsRow(
                  icon: CupertinoIcons.tag,
                  label: context.l10n.settingsCategories,
                  onTap: () => context.push(AppRoutes.categories),
                ),
                const _RowDivider(),
                _SettingsRow(
                  icon: CupertinoIcons.globe,
                  label: context.l10n.settingsLanguage,
                  value: _languageLabel(
                    context.l10n,
                    ref.watch(localeControllerProvider),
                  ),
                  onTap: () => _showLanguageSheet(context, ref),
                ),
                const _RowDivider(),
                _SettingsRow(
                  icon: CupertinoIcons.star,
                  label: 'Suscripción',
                  value: isPremium ? 'Premium' : 'Gratis',
                  valueColor: isPremium ? colors.income : null,
                ),
              ],
            ),
          ),
          AppSpacing.gapXl,
          GlassButton(
            label: 'Cerrar sesión',
            icon: CupertinoIcons.square_arrow_right,
            variant: GlassButtonVariant.glass,
            accent: colors.expense,
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
          AppSpacing.gapMd,
          TextButton(
            onPressed: () => _confirmDeleteAccount(context, ref),
            child: Text(
              'Eliminar cuenta',
              style: AppTypography.labelLarge.copyWith(color: colors.expense),
            ),
          ),
        ],
      ),
    );
  }

  /// Name of the active language for the row's trailing value.
  String _languageLabel(AppLocalizations l10n, Locale? locale) =>
      switch (locale?.languageCode) {
        'es' => l10n.languageSpanish,
        'en' => l10n.languageEnglish,
        'pt' => l10n.languagePortuguese,
        _ => l10n.languageSystem,
      };

  /// Lets the user pick the app language (or follow the system's).
  Future<void> _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.read(localeControllerProvider);
    final options = <(Locale?, String)>[
      (null, l10n.languageSystem),
      (const Locale('es'), l10n.languageSpanish),
      (const Locale('en'), l10n.languageEnglish),
      (const Locale('pt'), l10n.languagePortuguese),
    ];
    return GlassBottomSheet.show<void>(
      context,
      title: l10n.settingsLanguage,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (locale, label) in options)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _LanguageOption(
                label: label,
                selected: locale?.languageCode == current?.languageCode,
                onTap: () {
                  unawaited(
                    ref
                        .read(localeControllerProvider.notifier)
                        .setLocale(locale),
                  );
                  Navigator.of(sheetContext).pop();
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Opens the re-authenticated deletion sheet, choosing the consequence copy
  /// from the caller's role in their household.
  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final userId = ref.read(currentUserProvider)?.id;
    final household = ref.read(currentHouseholdProvider).asData?.value;
    final memberCount =
        ref.read(householdMembersProvider).asData?.value.length ?? 1;

    final DeleteAccountMode mode;
    if (memberCount <= 1) {
      mode = DeleteAccountMode.soloOwner;
    } else if (household?.ownerId == userId) {
      mode = DeleteAccountMode.sharedOwner;
    } else {
      mode = DeleteAccountMode.member;
    }

    await DeleteAccountSheet.show(context, mode: mode);
    // On success the session is cleared and the router redirects to auth; no
    // further navigation is needed here.
  }
}

/// A tappable language choice inside the language sheet.
class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.titleMedium)),
          if (selected)
            Icon(CupertinoIcons.checkmark_alt, color: colors.primary),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colors.textSecondary),
              AppSpacing.gapMd,
              Expanded(child: Text(label, style: AppTypography.titleMedium)),
              if (value != null)
                Text(
                  value!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: valueColor ?? colors.textSecondary,
                  ),
                ),
              AppSpacing.gapSm,
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: context.colors.divider);
}
