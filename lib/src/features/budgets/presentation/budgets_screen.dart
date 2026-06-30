import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../domain/enums/finance_enums.dart';
import '../../../domain/models/budget.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../shared/widgets/widgets.dart';
import '../../transactions/application/categories_providers.dart';
import '../application/budgets_providers.dart';

/// Budgets screen: a liquid tube per category that tints amber at 75% and coral
/// at 100%, where it offers an emergency adjustment.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider);
    final categories = ref.watch(categoriesByIdProvider);

    return GlassScaffold(
      appBar: AppBar(title: const Text('Presupuestos')),
      body: budgets.when(
        loading: () => const AppLoader(),
        error: (_, _) => const AppEmptyState(
          icon: CupertinoIcons.exclamationmark_circle,
          title: 'No pudimos cargar los presupuestos',
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              icon: CupertinoIcons.chart_bar,
              title: 'Sin presupuestos',
              message: 'Crea límites por categoría para vigilar tus fugas.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              120,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => AppSpacing.gapLg,
            itemBuilder: (context, i) => _BudgetCard(
              budget: items[i],
              category: categories[items[i].categoryId],
            ),
          );
        },
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget, this.category});
  final Budget budget;
  final TransactionCategory? category;

  Color _statusColor(AppColors colors) => switch (budget.status) {
    BudgetStatus.normal => colors.goal,
    BudgetStatus.warning => colors.alert,
    BudgetStatus.exceeded => colors.expense,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = _statusColor(colors);
    final exceeded = budget.status == BudgetStatus.exceeded;

    return GlassCard(
      borderColor: budget.status == BudgetStatus.normal ? null : accent,
      gradientGlow: exceeded ? colors.expense : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LiquidTubeIndicator(
            value: budget.ratio,
            color: accent,
            width: 46,
            height: 120,
          ),
          AppSpacing.gapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CategoryIcons.forKey(category?.iconName),
                      size: 18,
                      color: accent,
                    ),
                    AppSpacing.gapSm,
                    Expanded(
                      child: Text(
                        category?.name ?? 'Categoría',
                        style: AppTypography.titleMedium,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapSm,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    AmountText(
                      money: budget.spent,
                      style: AppTypography.titleLarge,
                      color: accent,
                    ),
                    Text(
                      ' / ${budget.limit.format()}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapXs,
                Text(
                  '${budget.status.label} · ${budget.percent.round()}%',
                  style: AppTypography.bodySmall.copyWith(color: accent),
                ),
                if (exceeded) ...[
                  AppSpacing.gapMd,
                  GlassButton(
                    label: 'Ajuste de emergencia',
                    icon: CupertinoIcons.arrow_2_squarepath,
                    variant: GlassButtonVariant.glass,
                    accent: colors.expense,
                    expand: false,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Próximamente: transferir presupuesto entre categorías.',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
