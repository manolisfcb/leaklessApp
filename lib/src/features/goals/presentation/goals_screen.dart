import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../domain/models/goal.dart';
import '../../../domain/models/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/goals_providers.dart';
import 'goal_form_sheet.dart';

/// Goals screen: the "translucent chest". Each goal shows a liquid progress bar
/// and one-tap express contributions.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(goalsControllerProvider, (_, next) {
      if (!next.hasError) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos completar la acción. Inténtalo de nuevo.',
            ),
          ),
        );
    });
    final l10n = context.l10n;
    final goals = ref.watch(goalsStreamProvider);
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Metas'),
        actions: [
          IconButton(
            tooltip: 'Nueva meta',
            onPressed: () => GoalFormSheet.show(context),
            icon: const Icon(CupertinoIcons.add),
          ),
          IconButton(
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(CupertinoIcons.gear_alt_fill),
          ),
        ],
      ),
      body: goals.when(
        loading: () => const AppLoader(),
        error: (_, _) => const AppEmptyState(
          icon: CupertinoIcons.exclamationmark_circle,
          title: 'No pudimos cargar tus metas',
        ),
        data: (items) {
          if (items.isEmpty) {
            return AppEmptyState(
              icon: CupertinoIcons.flag,
              title: 'Sin metas todavía',
              message: 'Crea una meta y vean el progreso llenarse juntos.',
              actionLabel: 'Crear meta',
              onAction: () => GoalFormSheet.show(context),
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
            itemBuilder: (context, i) => _GoalCard(
              goal: items[i],
              onEdit: () => GoalFormSheet.show(context, goal: items[i]),
              onDelete: () => _confirmDelete(context, ref, items[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Goal goal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar meta'),
        content: Text(
          '¿Quieres borrar “${goal.name}”? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(goalsControllerProvider.notifier).delete(goal.id);
    }
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });
  final Goal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Future<void> _contribute(WidgetRef ref, num major) {
    final amount = Money.fromMajor(major, currency: goal.target.currency);
    return ref
        .read(goalsControllerProvider.notifier)
        .contribute(goalId: goal.id, amountMinorUnits: amount.minorUnits);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final completed = goal.isCompleted;
    final accent = completed ? colors.income : colors.goal;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(goal.name, style: AppTypography.titleLarge)),
              if (completed)
                Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  color: colors.income,
                  size: 22,
                ),
              PopupMenuButton<_GoalAction>(
                tooltip: 'Acciones de meta',
                onSelected: (action) {
                  switch (action) {
                    case _GoalAction.edit:
                      onEdit();
                    case _GoalAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: _GoalAction.edit, child: Text('Editar')),
                  PopupMenuItem(
                    value: _GoalAction.delete,
                    child: Text('Borrar'),
                  ),
                ],
              ),
            ],
          ),
          AppSpacing.gapMd,
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AmountText(
                money: goal.saved,
                style: AppTypography.displaySmall,
                color: accent,
              ),
              Text(
                ' / ${goal.target.format()}',
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          LiquidProgressBar(value: goal.progress, color: accent, height: 18),
          AppSpacing.gapXs,
          Text(
            '${(goal.progress * 100).round()}% · faltan ${goal.remaining.format()}',
            style: AppTypography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (!completed) ...[
            AppSpacing.gapLg,
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    label:
                        '+ ${Money.fromMajor(50, currency: goal.target.currency).format()}',
                    variant: GlassButtonVariant.glass,
                    onPressed: () => _contribute(ref, 50),
                  ),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: GlassButton(
                    label:
                        '+ ${Money.fromMajor(100, currency: goal.target.currency).format()}',
                    onPressed: () => _contribute(ref, 100),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

enum _GoalAction { edit, delete }
