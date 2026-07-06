import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/dashboard_summary.dart';

/// The horizontally-scrolling summary cards under the hydrometer.
class SummaryCards extends StatelessWidget {
  const SummaryCards({required this.summary, super.key});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cards = [
      _CardData(
        icon: CupertinoIcons.chart_pie,
        accent: colors.income,
        value: '${(summary.savingsRate * 100).round()}%',
        label: 'Tasa de ahorro real',
      ),
      _CardData(
        icon: CupertinoIcons.creditcard,
        accent: colors.goal,
        value: '${summary.activeSubscriptions}',
        label: 'Gastos recurrentes',
        onTap: () => context.push(AppRoutes.subscriptions),
      ),
      _CardData(
        icon: CupertinoIcons.exclamationmark_triangle,
        accent: colors.alert,
        value: '${summary.activeAlerts}',
        label: 'Alertas de límites',
        onTap: () => context.go(AppRoutes.budgets),
      ),
    ];

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screen,
        itemCount: cards.length,
        separatorBuilder: (_, _) => AppSpacing.gapMd,
        itemBuilder: (context, i) => _SummaryCard(data: cards[i]),
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
    return SizedBox(
      width: 160,
      child: GlassCard(
        onTap: data.onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            Text(data.value, style: AppTypography.displaySmall),
            Text(
              data.label,
              style: AppTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
