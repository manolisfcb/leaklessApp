import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/month_insights.dart';

/// End-of-month spend projection extrapolated from the run rate so far.
/// Shows a soft "not enough data yet" message instead of a number when the
/// projection isn't reliable (early in the month or too few expenses).
class ProjectionCard extends StatelessWidget {
  const ProjectionCard({required this.insights, super.key});

  final MonthInsights insights;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final projection = insights.projection;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.insightsProjectionTitle, style: AppTypography.titleLarge),
          AppSpacing.gapLg,
          if (!projection.isReliable)
            Text(
              l10n.insightsProjectionInsufficientData,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            )
          else ...[
            Text(
              l10n.insightsProjectionLabel,
              style: AppTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            AppSpacing.gapXs,
            AmountText(
              money: projection.projectedTotal!,
              style: AppTypography.displaySmall,
              color: projection.projectedOverBudget != null
                  ? colors.expense
                  : colors.textPrimary,
            ),
            if (insights.hasBudget) ...[
              AppSpacing.gapMd,
              Text(
                projection.projectedOverBudget != null
                    ? l10n.insightsProjectionOverBudget(
                        projection.projectedOverBudget!.format(),
                      )
                    : l10n.insightsProjectionWithinBudget,
                style: AppTypography.bodyMedium.copyWith(
                  color: projection.projectedOverBudget != null
                      ? colors.expense
                      : colors.textSecondary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
