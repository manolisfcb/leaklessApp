import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/month_insights.dart';

/// Day-of-month spending shape: a bar per day, the daily average, the
/// priciest day and how many days had no spend at all.
class DailySpendCard extends StatelessWidget {
  const DailySpendCard({required this.insights, super.key});

  final MonthInsights insights;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final daily = insights.daily;
    final daysInMonth = DateTime(
      insights.month.year,
      insights.month.month + 1,
      0,
    ).day;
    final maxMinor = daily.byDay.values.fold<int>(
      0,
      (m, v) => v.minorUnits > m ? v.minorUnits : m,
    );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.insightsDailyTitle, style: AppTypography.titleLarge),
          AppSpacing.gapLg,
          SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var day = 1; day <= daysInMonth; day++) ...[
                  if (day > 1) const SizedBox(width: 2),
                  Expanded(
                    child: _DayBar(
                      heightFactor: maxMinor > 0
                          ? (daily.byDay[day]?.minorUnits ?? 0) / maxMinor
                          : 0,
                      highlighted: day == daily.mostExpensiveDay,
                    ),
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.gapLg,
          _StatRow(
            label: l10n.insightsDailyAverageLabel,
            value: daily.dailyAverage.format(),
          ),
          if (daily.mostExpensiveDay != null) ...[
            AppSpacing.gapSm,
            _StatRow(
              label: l10n.insightsDailyMostExpensiveLabel,
              value:
                  '${daily.mostExpensiveDay} — ${daily.mostExpensiveDayAmount.format()}',
            ),
          ],
          AppSpacing.gapSm,
          _StatRow(
            label: l10n.insightsDailyNoSpendLabel,
            value: l10n.insightsDailyNoSpendValue(daily.daysWithoutSpend),
          ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({required this.heightFactor, required this.highlighted});

  final double heightFactor;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: heightFactor.clamp(0.03, 1.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: highlighted ? colors.expense : colors.goal.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
