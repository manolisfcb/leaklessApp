import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/dashboard_summary.dart';

/// The two-up stat cards under the savings card: recurring expenses and
/// budget limit alerts, each tappable into its feature.
class SummaryCards extends StatelessWidget {
  const SummaryCards({required this.summary, super.key});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Padding(
      padding: AppSpacing.screen,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _SummaryCard(
                data: _CardData(
                  icon: CupertinoIcons.creditcard,
                  accent: colors.goal,
                  value: '${summary.activeSubscriptions}',
                  label: l10n.dashboardRecurringExpenses,
                  onTap: () => context.push(AppRoutes.subscriptions),
                ),
              ),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: _SummaryCard(
                data: _CardData(
                  icon: CupertinoIcons.exclamationmark_triangle,
                  accent: colors.alert,
                  value: '${summary.activeAlerts}',
                  label: l10n.dashboardLimitAlerts,
                  onTap: () => context.push(AppRoutes.budgets),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardData {
  const _CardData({
    required this.icon,
    required this.accent,
    required this.value,
    required this.label,
    this.onTap,
  });
  final IconData icon;
  final Color accent;
  final String value;
  final String label;
  final VoidCallback? onTap;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});
  final _CardData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GlassCard(
      onTap: data.onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: data.accent.withValues(alpha: 0.14),
                  borderRadius: AppRadii.pillRadius,
                ),
                child: Icon(data.icon, size: 20, color: data.accent),
              ),
              const Spacer(),
              Text(data.value, style: AppTypography.displaySmall),
            ],
          ),
          AppSpacing.gapSm,
          Text(
            data.label,
            style: AppTypography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
