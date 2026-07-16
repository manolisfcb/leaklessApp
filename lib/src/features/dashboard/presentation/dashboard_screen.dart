import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../transactions/application/categories_providers.dart';
import '../../transactions/application/transactions_providers.dart';
import '../../transactions/presentation/widgets/transaction_tile.dart';
import '../application/dashboard_providers.dart';
import '../domain/dashboard_summary.dart';
import 'widgets/couple_header.dart';
import 'widgets/savings_rate_card.dart';
import 'widgets/summary_cards.dart';

/// Home screen — the "frente a frente" dashboard with the financial hydrometer.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(dashboardSummaryProvider);
    return GlassScaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(CupertinoIcons.gear_alt_fill),
          ),
        ],
      ),
      body: summary.when(
        loading: () => AppLoader(message: l10n.dashboardLoading),
        error: (_, _) => AppEmptyState(
          icon: CupertinoIcons.exclamationmark_circle,
          title: l10n.dashboardLoadErrorTitle,
          message: l10n.dashboardLoadErrorMessage,
        ),
        data: (data) => _DashboardBody(summary: data),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final recent =
        ref.watch(transactionsStreamProvider).asData?.value ?? const [];
    final categories = ref.watch(categoriesByIdProvider);

    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 120),
      children: [
        const Padding(padding: AppSpacing.screen, child: _MonthSelector()),
        AppSpacing.gapLg,
        Padding(
          padding: AppSpacing.screen,
          child: _BalanceHeroCard(summary: summary),
        ),
        AppSpacing.gapMd,
        Padding(
          padding: AppSpacing.screen,
          child: SavingsRateCard(
            savingsRate: summary.savingsRate,
            leak: summary.leak,
          ),
        ),
        AppSpacing.gapMd,
        SummaryCards(summary: summary),
        AppSpacing.gapXl,
        Padding(
          padding: AppSpacing.screen,
          child: SectionHeader(
            title: l10n.dashboardRecentActivity,
            actionLabel: l10n.dashboardSeeAll,
            onAction: () => context.go(AppRoutes.transactions),
          ),
        ),
        AppSpacing.gapSm,
        Padding(
          padding: AppSpacing.screen,
          child: GlassCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              children: [
                for (final tx in recent.take(4))
                  TransactionTile(
                    transaction: tx,
                    category: categories[tx.categoryId],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The hero card that anchors the home: total balance with its FX context,
/// the couple thread, per-account balances and the month's net flow — all in
/// one glass surface so nothing important lives below the fold.
class _BalanceHeroCard extends StatelessWidget {
  const _BalanceHeroCard({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final overview = summary.overview;
    final netFlow = summary.netFlow;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.totalBalance,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          AppSpacing.gapXs,
          Center(
            child: AmountText(
              money: summary.totalBalance,
              style: AppTypography.displayLarge,
              color: summary.totalBalance.isNegative
                  ? colors.expense
                  : colors.textPrimary,
            ),
          ),
          if (overview?.isPartial ?? false)
            Text(
              l10n.partialTotal,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: colors.alert),
            ),
          if (overview?.rate case final rate?)
            Text(
              '1 ${rate.foreignCurrency} = ${rate.decimalValue} '
              '${rate.reportingCurrency} · ${DateFormat.yMMMd().format(rate.rateDate)}',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
          if (summary.members.isNotEmpty) ...[
            AppSpacing.gapMd,
            CoupleHeader(members: summary.members, dense: true),
          ],
          AppSpacing.gapSm,
          Container(height: 1, color: colors.divider),
          AppSpacing.gapMd,
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.monthlyNetFlow,
                  style: AppTypography.labelLarge.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              AmountText(
                money: netFlow,
                style: AppTypography.titleLarge,
                signDisplay: SignDisplay.always,
                color: netFlow.isNegative
                    ? colors.expense
                    : netFlow.isPositive
                    ? colors.income
                    : colors.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends ConsumerWidget {
  const _MonthSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final controller = ref.read(selectedMonthProvider.notifier);
    final label = DateFormat.yMMMM().format(month);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GlassIconButton(
          icon: CupertinoIcons.chevron_left,
          onPressed: controller.previous,
        ),
        Text(
          toBeginningOfSentenceCase(label) ?? label,
          style: AppTypography.titleLarge,
        ),
        GlassIconButton(
          icon: CupertinoIcons.chevron_right,
          onPressed: controller.isCurrentMonth ? null : controller.next,
        ),
      ],
    );
  }
}
