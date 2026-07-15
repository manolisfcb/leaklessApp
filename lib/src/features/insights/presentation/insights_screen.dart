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
import 'widgets/category_last_activity_card.dart';
import 'widgets/category_pie_card.dart';
import 'widgets/daily_spend_card.dart';
import 'widgets/income_sources_card.dart';
import 'widgets/month_summary_card.dart';
import 'widgets/projection_card.dart';
import 'widgets/recommendations_card.dart';
import 'widgets/runaway_category_card.dart';
import 'widgets/spending_pace_card.dart';
import 'widgets/trend_card.dart';
import 'widgets/uncategorized_card.dart';
import 'widgets/weekday_pattern_card.dart';

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
      appBar: AppBar(
        title: Text(l10n.insightsTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(CupertinoIcons.gear_alt_fill),
          ),
        ],
      ),
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
    final incomeInsights = ref.watch(incomeInsightsProvider).asData?.value;
    void createBudget() => context.push(AppRoutes.budgets);
    void categorizeUncategorized() {
      ref.read(transactionFilterProvider.notifier).showUncategorizedOnly();
      context.go(AppRoutes.transactions);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        120,
      ),
      children: [
        MonthSummaryCard(insights: insights, onCreateBudget: createBudget),
        if (incomeInsights != null) ...[
          AppSpacing.gapLg,
          IncomeSourcesCard(insights: incomeInsights),
        ],
        if (insights.hasBudget) ...[
          AppSpacing.gapLg,
          SpendingPaceCard(insights: insights),
        ],
        if (insights.categories.isNotEmpty) ...[
          AppSpacing.gapLg,
          CategoryPieCard(insights: insights, categories: categories),
          AppSpacing.gapLg,
          CategoryBreakdownCard(
            insights: insights,
            categories: categories,
            onCreateBudget: createBudget,
          ),
        ],
        if (insights.runawayCategories.isNotEmpty) ...[
          AppSpacing.gapLg,
          RunawayCategoryCard(insights: insights, categories: categories),
        ],
        AppSpacing.gapLg,
        TrendCard(insights: insights),
        AppSpacing.gapLg,
        ProjectionCard(insights: insights),
        AppSpacing.gapLg,
        DailySpendCard(insights: insights),
        if (insights.weekday.mostExpensiveWeekday != null) ...[
          AppSpacing.gapLg,
          WeekdayPatternCard(insights: insights),
        ],
        if (insights.categories.isNotEmpty) ...[
          AppSpacing.gapLg,
          CategoryLastActivityCard(insights: insights, categories: categories),
        ],
        if (!insights.uncategorized.isEmpty) ...[
          AppSpacing.gapLg,
          UncategorizedCard(
            insights: insights,
            onCategorize: categorizeUncategorized,
          ),
        ],
        AppSpacing.gapLg,
        RecommendationsCard(insights: insights, categories: categories),
      ],
    );
  }
}
