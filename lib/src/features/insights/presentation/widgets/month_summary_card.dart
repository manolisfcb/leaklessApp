import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/month_insights.dart';

/// Headline card: what was spent this month against the total budget, with a
/// liquid progress bar and a plain-language status message. When no budget is
/// set it invites the user to create one.
class MonthSummaryCard extends StatelessWidget {
  const MonthSummaryCard({
    required this.insights,
    required this.onCreateBudget,
    super.key,
  });

  final MonthInsights insights;
  final VoidCallback onCreateBudget;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final accent = _statusColor(colors);

    return GlassCard(
      borderColor: insights.status == SpendingStatus.onTrack ? null : accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.insightsMonthSummaryTitle, style: AppTypography.titleLarge),
          AppSpacing.gapMd,
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AmountText(
                money: insights.totalSpent,
                style: AppTypography.displaySmall,
                color: accent,
              ),
              if (insights.hasBudget) ...[
                AppSpacing.gapSm,
                Text(
                  l10n.insightsOfBudget(insights.totalBudget.format()),
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          if (insights.hasBudget) ...[
            AppSpacing.gapMd,
            LiquidProgressBar(
              value: insights.budgetUsedPct ?? 0,
              color: accent,
            ),
            AppSpacing.gapSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.insightsBudgetUsed(
                    ((insights.budgetUsedPct ?? 0) * 100).round(),
                  ),
                  style: AppTypography.bodySmall.copyWith(color: accent),
                ),
                Text(
                  insights.budgetDifference.isNegative
                      ? l10n.insightsOverBudgetBy(
                          insights.budgetDifference.absolute.format(),
                        )
                      : l10n.insightsRemaining(
                          insights.budgetDifference.format(),
                        ),
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            Text(
              _statusMessage(l10n),
              style: AppTypography.bodyMedium.copyWith(color: accent),
            ),
          ] else ...[
            AppSpacing.gapMd,
            Text(
              l10n.insightsNoBudgetNote,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            AppSpacing.gapLg,
            GlassButton(
              label: l10n.insightsCreateBudget,
              onPressed: onCreateBudget,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(AppColors colors) => switch (insights.status) {
    SpendingStatus.onTrack => colors.goal,
    SpendingStatus.ahead => colors.income,
    SpendingStatus.atRisk => colors.alert,
    SpendingStatus.over => colors.expense,
  };

  String _statusMessage(AppLocalizations l10n) => switch (insights.status) {
    SpendingStatus.onTrack => l10n.insightsStatusOnTrack,
    SpendingStatus.ahead => l10n.insightsStatusAhead,
    SpendingStatus.atRisk => l10n.insightsStatusAtRisk,
    SpendingStatus.over => l10n.insightsStatusOver,
  };
}
