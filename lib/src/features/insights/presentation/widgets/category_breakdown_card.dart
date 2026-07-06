import 'package:flutter/material.dart';

import '../../../../core/l10n/category_names.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../domain/models/transaction_category.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/month_insights.dart';

/// Per-category spend for the month, sorted by amount. Each row shows the
/// category, the amount, its share of the total and a bar (fill = budget usage
/// when a limit exists, otherwise its share). Offers a CTA to create a budget
/// when none is set.
class CategoryBreakdownCard extends StatelessWidget {
  const CategoryBreakdownCard({
    required this.insights,
    required this.categories,
    required this.onCreateBudget,
    super.key,
  });

  final MonthInsights insights;
  final Map<String, TransactionCategory> categories;
  final VoidCallback onCreateBudget;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.insightsCategoriesTitle, style: AppTypography.titleLarge),
          AppSpacing.gapLg,
          for (final (i, c) in insights.categories.indexed) ...[
            if (i > 0) AppSpacing.gapLg,
            _CategoryRow(
              insight: c,
              category: categories[c.categoryId],
            ),
          ],
          if (!insights.hasBudget) ...[
            AppSpacing.gapLg,
            Text(
              l10n.insightsNoBudgetNote,
              style: AppTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            AppSpacing.gapMd,
            GlassButton(
              label: l10n.insightsCreateBudget,
              variant: GlassButtonVariant.glass,
              onPressed: onCreateBudget,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.insight, this.category});

  final CategoryInsight insight;
  final TransactionCategory? category;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final ratio = insight.limitRatio;
    final overLimit = ratio != null && ratio >= 1.0;
    final accent = overLimit ? colors.expense : colors.goal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              CategoryIcons.forKey(category?.iconName),
              size: 18,
              color: accent,
            ),
            AppSpacing.gapSm,
            Expanded(
              child: Text(
                category == null
                    ? l10n.insightsCategoryUnnamed
                    : categoryDisplayName(category!, l10n),
                style: AppTypography.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AmountText(
              money: insight.spent,
              style: AppTypography.titleMedium,
              color: accent,
            ),
          ],
        ),
        AppSpacing.gapSm,
        LiquidProgressBar(
          value: ratio ?? insight.shareOfTotal,
          color: accent,
          height: 10,
          animateWave: false,
        ),
        AppSpacing.gapXs,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.insightsCategoryShare((insight.shareOfTotal * 100).round()),
              style: AppTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            if (insight.limit != null)
              Text(
                insight.limit!.format(),
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
