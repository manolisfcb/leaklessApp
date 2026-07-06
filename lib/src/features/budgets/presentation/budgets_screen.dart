import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/category_names.dart';
import '../../../core/l10n/enum_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../domain/enums/finance_enums.dart';
import '../../../domain/models/budget.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../shared/widgets/widgets.dart';
import '../../transactions/application/categories_providers.dart';
import '../application/budgets_providers.dart';
import 'budget_form_sheet.dart';

/// Budgets screen: a liquid tube per category that tints amber at 75% and coral
/// at 100%, where it offers an emergency adjustment.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider);
    final categories = ref.watch(categoriesByIdProvider);
    ref.listen<AsyncValue<void>>(budgetsControllerProvider, (previous, next) {
      if (!next.hasError || identical(previous?.error, next.error)) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(budgetErrorMessage(next.error!))),
        );
    });

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Presupuestos'),
        actions: [
          IconButton(
            tooltip: 'Nuevo presupuesto',
            icon: const Icon(CupertinoIcons.add),
            onPressed: () => _showBudgetForm(context),
          ),
        ],
      ),
      body: budgets.when(
        loading: () => const AppLoader(),
        error: (_, _) => const AppEmptyState(
          icon: CupertinoIcons.exclamationmark_circle,
          title: 'No pudimos cargar los presupuestos',
        ),
        data: (items) {
          if (items.isEmpty) {
            return AppEmptyState(
              icon: CupertinoIcons.chart_bar,
              title: 'Sin presupuestos',
              message: 'Crea límites por categoría para vigilar tus fugas.',
              actionLabel: 'Crear presupuesto',
              onAction: () => _showBudgetForm(context),
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
              onTap: () => _showBudgetForm(context, budget: items[i]),
              onDelete: () => _confirmDelete(context, ref, items[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showBudgetForm(BuildContext context, {Budget? budget}) =>
      GlassBottomSheet.show<void>(
        context,
        title: budget == null ? 'Nuevo presupuesto' : 'Editar presupuesto',
        builder: (_) => BudgetFormSheet(budget: budget),
      );

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Budget budget,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar presupuesto'),
        content: const Text(
          'Se eliminará este límite mensual. Esta acción no borra tus gastos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(budgetsControllerProvider.notifier).delete(budget.id);
    }
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.onTap,
    required this.onDelete,
    this.category,
  });
  final Budget budget;
  final TransactionCategory? category;
  final VoidCallback onTap;
  final VoidCallback onDelete;

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
      onTap: onTap,
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
                        category == null
                            ? 'Categoría'
                            : categoryDisplayName(category!, context.l10n),
                        style: AppTypography.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Eliminar presupuesto',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        CupertinoIcons.trash,
                        size: 18,
                        color: colors.textSecondary,
                      ),
                      onPressed: onDelete,
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
                  '${budget.status.localizedLabel(context.l10n)} · ${budget.percent.round()}%',
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

/// Maps controller failures to concise, user-facing budget messages.
String budgetErrorMessage(Object error) {
  Object? current = error;
  while (current != null) {
    final details = current.toString().toLowerCase();
    if (details.contains('23505') ||
        details.contains('duplicate key') ||
        details.contains('unique constraint')) {
      return 'Ya existe un presupuesto para esa categoría este mes.';
    }
    current = current is AppException ? current.cause : null;
  }
  return 'No pudimos completar la operación. Inténtalo de nuevo.';
}
