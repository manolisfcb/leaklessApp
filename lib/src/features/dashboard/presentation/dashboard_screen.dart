import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../transactions/application/categories_providers.dart';
import '../../transactions/application/transactions_providers.dart';
import '../../transactions/presentation/widgets/transaction_tile.dart';
import '../application/dashboard_providers.dart';
import '../domain/dashboard_summary.dart';
import 'widgets/couple_header.dart';
import 'widgets/hydrometer_gauge.dart';
import 'widgets/summary_cards.dart';

/// Home screen — the "frente a frente" dashboard with the financial hydrometer.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    return GlassScaffold(
      body: summary.when(
        loading: () => const AppLoader(message: 'Cargando tu panel…'),
        error: (_, _) => const AppEmptyState(
          icon: CupertinoIcons.exclamationmark_circle,
          title: 'No pudimos cargar el panel',
          message: 'Inténtalo de nuevo en un momento.',
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
    final colors = context.colors;
    final recent = ref.watch(transactionsStreamProvider).asData?.value ?? const [];
    final categories = ref.watch(categoriesByIdProvider);

    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 120),
      children: [
        const Padding(
          padding: AppSpacing.screen,
          child: _MonthSelector(),
        ),
        AppSpacing.gapLg,
        Center(
          child: Column(
            children: [
              Text(
                'Balance disponible',
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              AppSpacing.gapXs,
              AmountText(
                money: summary.balance,
                style: AppTypography.displayLarge,
                color: summary.balance.isNegative
                    ? colors.expense
                    : colors.textPrimary,
              ),
            ],
          ),
        ),
        AppSpacing.gapLg,
        Padding(
          padding: AppSpacing.screen,
          child: CoupleHeader(members: summary.members),
        ),
        AppSpacing.gapLg,
        HydrometerGauge(savingsRate: summary.savingsRate, leak: summary.leak),
        AppSpacing.gapXl,
        SummaryCards(summary: summary),
        AppSpacing.gapXl,
        Padding(
          padding: AppSpacing.screen,
          child: SectionHeader(
            title: 'Actividad reciente',
            actionLabel: 'Ver todo',
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
