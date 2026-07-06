import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../quick_entry/presentation/quick_entry_sheet.dart';
import '../../transactions/application/categories_providers.dart';
import '../../transactions/application/transactions_providers.dart';
import '../application/insights_providers.dart';
import '../domain/month_insights.dart';
import 'widgets/category_breakdown_card.dart';
import 'widgets/month_summary_card.dart';
import 'widgets/spending_pace_card.dart';

/// Financial insights ("Dashboard") for the current month. Renders the
/// [MonthInsights] read-model as a scroll of glass cards and handles every
/// state: loading, error (with retry), no transactions, and no budget.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final insights = ref.watch(monthInsightsProvider);

    return GlassScaffold(
      appBar: AppBar(title: Text(l10n.insightsTitle)),
      body: insights.when(
        loading: () => AppLoader(message: l10n.insightsLoading),
        error: (_, _) => AppEmptyState(
          icon: CupertinoIcons.exclamationmark_circle,
          title: l10n.insightsErrorTitle,
          message: l10n.insightsErrorMessage,
          actionLabel: l10n.insightsRetry,
          onAction: () {
            ref
              ..invalidate(transactionsStreamProvider)
              ..invalidate(categoriesProvider);
          },
        ),
        data: (data) {
          if (!data.hasTransactions) {
            return AppEmptyState(
              icon: CupertinoIcons.chart_pie,
              title: l10n.insightsEmptyTitle,
              message: l10n.insightsEmptyMessage,
              actionLabel: l10n.insightsEmptyAction,
              onAction: () => _openQuickEntry(context),
            );
          }
          return _InsightsBody(insights: data);
        },
      ),
    );
  }

  void _openQuickEntry(BuildContext context) => GlassBottomSheet.show<void>(
    context,
    title: context.l10n.quickEntryTitle,
    builder: (_) => const QuickEntrySheet(),
  );
}

class _InsightsBody extends ConsumerWidget {
  const _InsightsBody({required this.insights});

  final MonthInsights insights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesByIdProvider);
    void createBudget() => context.push(AppRoutes.budgets);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        120,
      ),
      children: [
        MonthSummaryCard(insights: insights, onCreateBudget: createBudget),
        if (insights.hasBudget) ...[
          AppSpacing.gapLg,
          SpendingPaceCard(insights: insights),
        ],
        if (insights.categories.isNotEmpty) ...[
          AppSpacing.gapLg,
          CategoryBreakdownCard(
            insights: insights,
            categories: categories,
            onCreateBudget: createBudget,
          ),
        ],
      ],
    );
  }
}
