import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/models/money.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/month_insights.dart';

/// Compares spend-to-date against the linear budget pace and, when the month is
/// projected to overshoot, the amount to trim to still close on budget. Only
/// meaningful with a budget set — the screen hides it otherwise.
class SpendingPaceCard extends StatelessWidget {
  const SpendingPaceCard({required this.insights, super.key});

  final MonthInsights insights;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final pace = insights.pace;
    // difference = actual − expected: negative means under pace (good).
    final bool? ahead = pace.difference.isZero ? null : pace.difference.isNegative;
    final accent = switch (ahead) {
      true => colors.income,
      false => colors.alert,
      null => colors.textSecondary,
    };

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.insightsPaceTitle, style: AppTypography.titleLarge),
          AppSpacing.gapLg,
          Row(
            children: [
              Expanded(
                child: _PaceColumn(
                  label: l10n.insightsPaceExpected,
                  money: pace.expectedToDate,
                  color: colors.textSecondary,
                ),
              ),
              Expanded(
                child: _PaceColumn(
                  label: l10n.insightsPaceActual,
                  money: pace.actualToDate,
                  color: accent,
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          Text(
            _paceMessage(l10n, ahead),
            style: AppTypography.bodyMedium.copyWith(color: accent),
          ),
          if (pace.amountToReduce != null && !pace.amountToReduce!.isZero) ...[
            AppSpacing.gapXs,
            Text(
              l10n.insightsPaceReduce(pace.amountToReduce!.format()),
              style: AppTypography.bodySmall.copyWith(color: colors.expense),
            ),
          ],
        ],
      ),
    );
  }

  String _paceMessage(AppLocalizations l10n, bool? ahead) => switch (ahead) {
    true => l10n.insightsPaceAhead(insights.pace.difference.absolute.format()),
    false => l10n.insightsPaceBehind(insights.pace.difference.absolute.format()),
    null => l10n.insightsPaceOnPace,
  };
}

class _PaceColumn extends StatelessWidget {
  const _PaceColumn({
    required this.label,
    required this.money,
    required this.color,
  });

  final String label;
  final Money money;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        AppSpacing.gapXs,
        AmountText(
          money: money,
          style: AppTypography.titleMedium,
          color: color,
        ),
      ],
    );
  }
}
