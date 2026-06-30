import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../domain/models/goal.dart';
import '../../../domain/models/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/goals_providers.dart';

/// Goals screen: the "translucent chest". Each goal shows a liquid progress bar
/// and one-tap express contributions.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsStreamProvider);
    return GlassScaffold(
      appBar: AppBar(title: const Text('Metas')),
      body: goals.when(
        loading: () => const AppLoader(),
        error: (_, _) => const AppEmptyState(
          icon: CupertinoIcons.exclamationmark_circle,
          title: 'No pudimos cargar tus metas',
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              icon: CupertinoIcons.flag,
              title: 'Sin metas todavía',
              message: 'Crea una meta y vean el progreso llenarse juntos.',
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
            itemBuilder: (context, i) => _GoalCard(goal: items[i]),
          );
        },
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});
  final Goal goal;

  Future<void> _contribute(WidgetRef ref, num major) {
    final amount = Money.fromMajor(major, currency: goal.target.currency);
    return ref.read(goalsControllerProvider.notifier).contribute(
      goalId: goal.id,
      amountMinorUnits: amount.minorUnits,
    );
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
              Expanded(
                child: Text(goal.name, style: AppTypography.titleLarge),
              ),
              if (completed)
                Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  color: colors.income,
                  size: 22,
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
            style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
          ),
          if (!completed) ...[
            AppSpacing.gapLg,
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    label: '+ ${Money.fromMajor(50, currency: goal.target.currency).format()}',
                    variant: GlassButtonVariant.glass,
                    onPressed: () => _contribute(ref, 50),
                  ),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: GlassButton(
                    label: '+ ${Money.fromMajor(100, currency: goal.target.currency).format()}',
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
