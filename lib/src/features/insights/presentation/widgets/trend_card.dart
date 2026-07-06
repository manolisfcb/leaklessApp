import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/month_insights.dart';

/// Month-over-month and vs-3-month-average comparison, with a 4-month mini
/// bar chart. Shows a soft note instead of a change figure when there is no
/// previous month to compare against.
class TrendCard extends StatelessWidget {
  const TrendCard({required this.insights, super.key});

  final MonthInsights insights;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final comparison = insights.comparison;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.insightsTrendTitle, style: AppTypography.titleLarge),
          AppSpacing.gapLg,
          MiniBarChart(
            values: [
              for (final m in comparison.recentTotals) m.total.major.abs(),
            ],
            labels: [
              for (final m in comparison.recentTotals)
                DateFormat.MMM().format(m.month),
            ],
          ),
          AppSpacing.gapLg,
          if (comparison.hasPreviousMonth)
            _ComparisonRow(
              label: l10n.insightsTrendVsPreviousLabel,
              changePct: comparison.changeVsPreviousPct,
              direction: comparison.directionVsPrevious,
            )
          else
            Text(
              l10n.insightsTrendNoPreviousMonth,
              style: AppTypography.bodySmall.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          AppSpacing.gapMd,
          _ComparisonRow(
            label: l10n.insightsTrendVsAverageLabel,
            changePct: comparison.changeVsAveragePct,
            direction: comparison.directionVsAverage,
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.changePct,
    required this.direction,
  });

  final String label;
  final double? changePct;
  final TrendDirection direction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    // Spending more than before is the "worse" outcome, so up = alert color.
    final (icon, color) = switch (direction) {
      TrendDirection.up => (CupertinoIcons.arrow_up_right, colors.expense),
      TrendDirection.down => (CupertinoIcons.arrow_down_right, colors.income),
      TrendDirection.stable => (CupertinoIcons.minus, colors.textSecondary),
    };
    final text = switch (direction) {
      TrendDirection.up => l10n.insightsTrendChangeUp(
        ((changePct ?? 0).abs() * 100).round(),
      ),
      TrendDirection.down => l10n.insightsTrendChangeDown(
        ((changePct ?? 0).abs() * 100).round(),
      ),
      TrendDirection.stable => l10n.insightsTrendChangeStable,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            AppSpacing.gapXs,
            Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
