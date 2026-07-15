import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/income_insights.dart';

class IncomeSourcesCard extends StatelessWidget {
  const IncomeSourcesCard({required this.insights, super.key});
  final IncomeInsights insights;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.incomeBySource, style: AppTypography.titleLarge),
        AppSpacing.gapXs,
        Text(
          insights.total.format(showSymbol: false),
          style: AppTypography.displaySmall.copyWith(
            color: context.colors.income,
          ),
        ),
        AppSpacing.gapLg,
        if (insights.bySource.isEmpty)
          Text(context.l10n.noIncomePeriod, style: AppTypography.bodyMedium)
        else
          for (final slice in insights.bySource) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    slice.name.isEmpty
                        ? context.l10n.withoutSource
                        : slice.name,
                  ),
                ),
                Text('${(slice.share * 100).round()}%'),
                AppSpacing.gapMd,
                Text(slice.total.format(showSymbol: false)),
              ],
            ),
            AppSpacing.gapXs,
            LinearProgressIndicator(
              value: slice.share,
              color: context.colors.income,
              backgroundColor: context.colors.glassFill,
              borderRadius: AppRadii.pillRadius,
            ),
            AppSpacing.gapMd,
          ],
        if (insights.byCurrency.isNotEmpty) ...[
          const Divider(),
          Text(context.l10n.incomeByCurrency, style: AppTypography.titleMedium),
          AppSpacing.gapSm,
          for (final slice in insights.byCurrency)
            Text(
              '${slice.currency} · ${slice.reportingTotal.format(showSymbol: false)}',
            ),
        ],
      ],
    ),
  );
}
