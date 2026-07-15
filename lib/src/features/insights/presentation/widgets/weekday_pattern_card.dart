import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/models/money.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/month_insights.dart';

/// Which weekday tends to be the most and least expensive, averaged over
/// the recent months (or just the current month without enough history).
/// The screen only renders this card once there is at least one weekday
/// with spend — with none, the section stays hidden.
class WeekdayPatternCard extends StatelessWidget {
  const WeekdayPatternCard({required this.insights, super.key});

  final MonthInsights insights;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final weekday = insights.weekday;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.insightsWeekdayTitle, style: AppTypography.titleLarge),
          AppSpacing.gapLg,
          if (weekday.mostExpensiveWeekday != null)
            _WeekdayRow(
              label: l10n.insightsWeekdayMostExpensiveLabel,
              weekdayName: _weekdayName(weekday.mostExpensiveWeekday!, locale),
              amount: weekday.averageByWeekday[weekday.mostExpensiveWeekday]!,
              accent: context.colors.expense,
            ),
          if (weekday.leastExpensiveWeekday != null) ...[
            AppSpacing.gapMd,
            _WeekdayRow(
              label: l10n.insightsWeekdayLeastExpensiveLabel,
              weekdayName: _weekdayName(weekday.leastExpensiveWeekday!, locale),
              amount: weekday.averageByWeekday[weekday.leastExpensiveWeekday]!,
              accent: context.colors.goal,
            ),
          ],
        ],
      ),
    );
  }

  /// Formats an ISO weekday (1 = Monday … 7 = Sunday) as a capitalized,
  /// locale-aware weekday name, anchored to a known Monday.
  static String _weekdayName(int isoWeekday, String locale) {
    final monday = DateTime(2024);
    final date = monday.add(Duration(days: isoWeekday - 1));
    final name = DateFormat.EEEE(locale).format(date);
    return name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({
    required this.label,
    required this.weekdayName,
    required this.amount,
    required this.accent,
  });

  final String label;
  final String weekdayName;
  final Money amount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              AppSpacing.gapXs,
              Text(
                weekdayName,
                style: AppTypography.titleMedium.copyWith(color: accent),
              ),
            ],
          ),
        ),
        AmountText(
          money: amount,
          style: AppTypography.bodyMedium,
          color: colors.textSecondary,
        ),
      ],
    );
  }
}
