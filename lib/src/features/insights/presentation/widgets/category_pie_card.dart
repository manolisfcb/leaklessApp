import 'package:flutter/material.dart';

import '../../../../core/l10n/category_names.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/category_colors.dart';
import '../../../../domain/models/money.dart';
import '../../../../domain/models/transaction_category.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/month_insights.dart';

/// One row of the pie card's legend: a named slice with its own color, share
/// and amount. [category] is null for the aggregated "Others" bucket.
class CategoryPieSlice {
  const CategoryPieSlice({
    required this.categoryId,
    required this.category,
    required this.spent,
    required this.shareOfTotal,
  });

  final String categoryId;
  final TransactionCategory? category;
  final Money spent;
  final double shareOfTotal;
}

/// Proportional snapshot of the month's spend: a donut chart plus a legend,
/// shown before [CategoryBreakdownCard]'s per-category detail.
class CategoryPieCard extends StatelessWidget {
  const CategoryPieCard({
    required this.insights,
    required this.categories,
    super.key,
  });

  final MonthInsights insights;
  final Map<String, TransactionCategory> categories;

  /// Top-5 categories by spend, plus an "Others" bucket aggregating the rest.
  /// No "Others" bucket when there are 5 or fewer categories.
  static List<CategoryPieSlice> topSlices(
    MonthInsights insights,
    Map<String, TransactionCategory> categories,
  ) {
    const maxSlices = 5;
    final sorted = insights.categories;
    final top = sorted.take(maxSlices);
    final rest = sorted.skip(maxSlices);

    final slices = [
      for (final c in top)
        CategoryPieSlice(
          categoryId: c.categoryId,
          category: categories[c.categoryId],
          spent: c.spent,
          shareOfTotal: c.shareOfTotal,
        ),
    ];

    if (rest.isNotEmpty) {
      final othersMinor = rest.fold<int>(0, (s, c) => s + c.spent.minorUnits);
      final othersShare = rest.fold<double>(0, (s, c) => s + c.shareOfTotal);
      slices.add(
        CategoryPieSlice(
          categoryId: '_others',
          category: null,
          spent: Money(minorUnits: othersMinor, currency: insights.currency),
          shareOfTotal: othersShare,
        ),
      );
    }

    return slices;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final slices = topSlices(insights, categories);
    final othersColor = colors.textTertiary;

    final donutSlices = [
      for (final (i, s) in slices.indexed)
        (
          value: s.shareOfTotal,
          color: s.categoryId == '_others'
              ? othersColor
              : CategoryColors.forCategory(s.category, i),
        ),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.insightsPieTitle, style: AppTypography.titleLarge),
          AppSpacing.gapLg,
          Center(
            child: DonutChart(
              slices: donutSlices,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AmountText(money: insights.totalSpent, style: AppTypography.titleLarge),
                  Text(
                    l10n.insightsPieCenterLabel,
                    style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.gapLg,
          for (final (i, s) in slices.indexed) ...[
            if (i > 0) AppSpacing.gapMd,
            _LegendRow(
              slice: s,
              color: donutSlices[i].color,
              label: s.categoryId == '_others'
                  ? l10n.insightsPieOthers
                  : (s.category == null
                        ? l10n.insightsCategoryUnnamed
                        : categoryDisplayName(s.category!, l10n)),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.slice, required this.color, required this.label});

  final CategoryPieSlice slice;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final percent = (slice.shareOfTotal * 100).round();
    final shareLabel = percent == 0 && slice.shareOfTotal > 0 ? '<1%' : '$percent%';

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        AppSpacing.gapSm,
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          shareLabel,
          style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
        ),
        AppSpacing.gapSm,
        AmountText(money: slice.spent, style: AppTypography.bodyMedium),
      ],
    );
  }
}
