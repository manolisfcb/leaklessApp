import 'package:flutter/material.dart';

import '../../../../core/l10n/category_names.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../domain/models/transaction_category.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/month_insights.dart';

/// Compact list of the most recent transaction date per category, with
/// relative labels ("Today", "Yesterday", "N days ago").
class CategoryLastActivityCard extends StatelessWidget {
  const CategoryLastActivityCard({
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.insightsLastActivityTitle, style: AppTypography.titleLarge),
          AppSpacing.gapLg,
          for (final (i, c) in insights.categories.indexed) ...[
            if (i > 0) AppSpacing.gapMd,
            _LastActivityRow(
              insight: c,
              category: categories[c.categoryId],
              relativeLabel: _relativeLabel(c.lastActivity, l10n),
            ),
          ],
        ],
      ),
    );
  }

  String _relativeLabel(DateTime lastActivity, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(
      lastActivity.year,
      lastActivity.month,
      lastActivity.day,
    );
    final daysAgo = today.difference(day).inDays;
    if (daysAgo <= 0) return l10n.insightsLastActivityToday;
    if (daysAgo == 1) return l10n.insightsLastActivityYesterday;
    return l10n.insightsLastActivityDaysAgo(daysAgo);
  }
}

class _LastActivityRow extends StatelessWidget {
  const _LastActivityRow({
    required this.insight,
    required this.relativeLabel,
    this.category,
  });

  final CategoryInsight insight;
  final TransactionCategory? category;
  final String relativeLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Row(
      children: [
        Icon(
          CategoryIcons.forKey(category?.iconName),
          size: 18,
          color: colors.textSecondary,
        ),
        AppSpacing.gapSm,
        Expanded(
          child: Text(
            category == null
                ? l10n.insightsCategoryUnnamed
                : categoryDisplayName(category!, l10n),
            style: AppTypography.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppSpacing.gapSm,
        Text(
          relativeLabel,
          style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}
