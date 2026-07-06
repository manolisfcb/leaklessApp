import 'package:flutter/cupertino.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/month_insights.dart';

/// Nudges the user to categorize this month's uncategorized expenses. The
/// screen only renders this card when there is at least one — with none, the
/// section stays hidden.
class UncategorizedCard extends StatelessWidget {
  const UncategorizedCard({
    required this.insights,
    required this.onCategorize,
    super.key,
  });

  final MonthInsights insights;
  final VoidCallback onCategorize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final uncategorized = insights.uncategorized;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.question_circle,
                size: 20,
                color: colors.textSecondary,
              ),
              AppSpacing.gapSm,
              Text(l10n.insightsUncategorizedTitle, style: AppTypography.titleLarge),
            ],
          ),
          AppSpacing.gapMd,
          Text(
            l10n.insightsUncategorizedMessage(
              uncategorized.count,
              uncategorized.amount.format(),
            ),
            style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          AppSpacing.gapLg,
          GlassButton(
            label: l10n.insightsUncategorizedAction,
            variant: GlassButtonVariant.glass,
            onPressed: onCategorize,
            expand: false,
          ),
        ],
      ),
    );
  }
}
