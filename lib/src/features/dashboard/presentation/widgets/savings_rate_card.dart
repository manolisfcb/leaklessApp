import 'package:flutter/cupertino.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/models/money.dart';
import '../../../../shared/widgets/widgets.dart';

/// The compact "hidrómetro financiero": a glass card whose liquid bar level is
/// the month's savings rate. When there's a leak (gastos hormiga) an amber
/// chip below the bar shows the exact amount.
class SavingsRateCard extends StatelessWidget {
  const SavingsRateCard({
    required this.savingsRate,
    required this.leak,
    super.key,
  });

  final double savingsRate;
  final Money leak;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: colors.goalSoft,
                  borderRadius: AppRadii.pillRadius,
                ),
                child: Icon(
                  CupertinoIcons.chart_pie,
                  size: 20,
                  color: colors.goal,
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Text(
                  l10n.dashboardSavingsRate,
                  style: AppTypography.titleMedium,
                ),
              ),
              Text(
                '${(savingsRate * 100).round()}%',
                style: AppTypography.displaySmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          LiquidProgressBar(value: savingsRate, height: 14),
          if (leak.isPositive) ...[
            AppSpacing.gapMd,
            Align(
              alignment: Alignment.centerLeft,
              child: _LeakChip(leak: leak),
            ),
          ],
        ],
      ),
    );
  }
}

class _LeakChip extends StatelessWidget {
  const _LeakChip({required this.leak});
  final Money leak;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.alertSoft,
        borderRadius: AppRadii.pillRadius,
        border: Border.all(color: colors.alert),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.drop, size: 14, color: colors.alert),
          AppSpacing.gapXs,
          Text(
            context.l10n.dashboardLeak(leak.format()),
            style: AppTypography.labelSmall.copyWith(color: colors.alert),
          ),
        ],
      ),
    );
  }
}
