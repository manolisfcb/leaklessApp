import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/enum_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/categories_providers.dart';
import '../application/transactions_providers.dart';
import 'widgets/transaction_tile.dart';

/// History screen: the household's transactions with instant tactile filters by
/// responsible and priority.
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final transactions = ref.watch(filteredTransactionsProvider);
    final categories = ref.watch(categoriesByIdProvider);

    return GlassScaffold(
      appBar: AppBar(title: Text(l10n.navHistory)),
      body: Column(
        children: [
          const _Filters(),
          AppSpacing.gapSm,
          Expanded(
            child: transactions.when(
              loading: () => const AppLoader(),
              error: (_, _) => AppEmptyState(
                icon: CupertinoIcons.exclamationmark_circle,
                title: l10n.transactionsLoadError,
              ),
              data: (items) {
                if (items.isEmpty) {
                  return AppEmptyState(
                    icon: CupertinoIcons.tray,
                    title: l10n.transactionsEmptyTitle,
                    message: l10n.transactionsEmptyMessage,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    120,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final tx = items[i];
                    return TransactionTile(
                      transaction: tx,
                      category: categories[tx.categoryId],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends ConsumerWidget {
  const _Filters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(transactionFilterProvider);
    final controller = ref.read(transactionFilterProvider.notifier);

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screen,
        children: [
          for (final r in ResponsibleType.values)
            _Chip(
              label: r.localizedLabel(l10n),
              selected: filter.responsible == r,
              onTap: () => controller.toggleResponsible(r),
            ),
          const _Divider(),
          for (final p in TransactionPriority.values)
            _Chip(
              label: p.localizedLabel(l10n),
              selected: filter.priority == p,
              onTap: () => controller.togglePriority(p),
            ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 20,
    margin: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.md,
    ),
    color: context.colors.divider,
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.glassFill,
            borderRadius: AppRadii.pillRadius,
            border: Border.all(
              color: selected ? colors.primary : colors.glassBorder,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: selected ? Colors.white : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
