import 'package:flutter/cupertino.dart';

import '../../../../core/l10n/category_names.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/models/transaction_category.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/month_insights.dart';

/// Actionable, never-blaming nudges derived from the month's data, ordered by
/// impact. Always renders at least one row — [MonthInsights.from] guarantees
/// a positive-reinforcement entry when nothing else applies.
class RecommendationsCard extends StatelessWidget {
  const RecommendationsCard({
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
          Text(
            l10n.insightsRecommendationsTitle,
            style: AppTypography.titleLarge,
          ),
          AppSpacing.gapLg,
          for (final (i, r) in insights.recommendations.indexed) ...[
            if (i > 0) AppSpacing.gapMd,
            _RecommendationRow(
              recommendation: r,
              category: r.categoryId == null ? null : categories[r.categoryId],
            ),
          ],
        ],
      ),
    );
  }
}

class _RecommendationRow extends StatelessWidget {
  const _RecommendationRow({required this.recommendation, this.category});

  final InsightRecommendation recommendation;
  final TransactionCategory? category;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final categoryName = category == null
        ? l10n.insightsCategoryUnnamed
        : categoryDisplayName(category!, l10n);

    final (icon, accent, message) = switch (recommendation.kind) {
      InsightRecommendationKind.reduceCategory => (
        CupertinoIcons.arrow_down_circle,
        colors.alert,
        l10n.insightsRecommendationReduceCategory(
          recommendation.amount?.format() ?? '',
          categoryName,
        ),
      ),
      InsightRecommendationKind.runawayCategory => (
        CupertinoIcons.exclamationmark_triangle,
        colors.alert,
        l10n.insightsRecommendationRunaway(categoryName),
      ),
      InsightRecommendationKind.allOnTrack => (
        CupertinoIcons.checkmark_seal,
        colors.goal,
        l10n.insightsRecommendationAllOnTrack,
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: accent),
        AppSpacing.gapSm,
        Expanded(child: Text(message, style: AppTypography.bodyMedium)),
      ],
    );
  }
}
