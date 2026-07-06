import 'package:flutter/cupertino.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/models/money.dart';
import '../../../../shared/widgets/widgets.dart';

/// The "hidrómetro financiero": a translucent capsule whose liquid level is the
/// month's savings rate. When there's a leak (gastos hormiga) an amber chip
/// floats over the water showing the exact amount.
class HydrometerGauge extends StatelessWidget {
  const HydrometerGauge({
    required this.savingsRate,
    required this.leak,
    super.key,
  });

  final double savingsRate;
  final Money leak;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasLeak = leak.isPositive;
    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          LiquidTubeIndicator(
            value: savingsRate,
            color: colors.goal,
            width: 150,
            height: 240,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(savingsRate * 100).round()}%',
                style: AppTypography.displayMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              Text(
                context.l10n.dashboardSavingsRateShort,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          if (hasLeak)
            Positioned(
              bottom: 8,
              child: _LeakChip(leak: leak),
            ),
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
