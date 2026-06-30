import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_providers.dart';
import '../../../core/purchases/purchases_providers.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../household/application/household_providers.dart';
import '../../profile/application/profile_providers.dart';

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
                  icon: CupertinoIcons.person_2,
                  label: 'Pareja / Household',
                  value: '${ref.watch(householdMembersProvider).asData?.value.length ?? 0} miembros',
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
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
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
  });

  final IconData icon;
  final String label;
  final String? value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
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
          Icon(CupertinoIcons.chevron_right, size: 16, color: colors.textTertiary),
        ],
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
