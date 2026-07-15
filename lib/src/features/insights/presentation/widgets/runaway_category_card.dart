import 'package:flutter/material.dart';

import '../../../../core/l10n/category_names.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../domain/models/transaction_category.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/month_insights.dart';

/// Categories spending well above their recent 3-month average. The screen
/// only renders this card when [insights] has at least one runaway category —
/// with no history, the section stays hidden rather than showing an empty
/// card.
class RunawayCategoryCard extends StatelessWidget {
  const RunawayCategoryCard({
    required this.insights,
    required this.categories,
    super.key,
  });

  final MonthInsights insights;
  final Map<String, TransactionCategory> categories;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GlassCard(
      borderColor: context.colors.alert,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.insightsRunawayTitle, style: AppTypography.titleLarge),
          AppSpacing.gapLg,
          for (final (i, r) in insights.runawayCategories.indexed) ...[
            if (i > 0) AppSpacing.gapMd,
            _RunawayRow(runaway: r, category: categories[r.categoryId]),
          ],
        ],
      ),
    );
  }
}

class _RunawayRow extends StatelessWidget {
  const _RunawayRow({required this.runaway, this.category});

  final RunawayCategory runaway;
  final TransactionCategory? category;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          CategoryIcons.forKey(category?.iconName),
          size: 18,
          color: colors.alert,
        ),
        AppSpacing.gapSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category == null
                    ? l10n.insightsCategoryUnnamed
                    : categoryDisplayName(category!, l10n),
                style: AppTypography.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
              AppSpacing.gapXs,
              Text(
                l10n.insightsRunawayCompare(runaway.averageSpend.format()),
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapSm,
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Badge(
              text: l10n.insightsRunawayBadge(
                (runaway.overshootPct * 100).round(),
              ),
            ),
            AppSpacing.gapXs,
            AmountText(
              money: runaway.currentSpend,
              style: AppTypography.bodyMedium,
              color: colors.expense,
            ),
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.alert.withValues(alpha: 0.18),
        borderRadius: AppRadii.pillRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: colors.alert,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
