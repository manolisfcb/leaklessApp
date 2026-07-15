import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/enum_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../domain/models/financial_account.dart';
import '../../../domain/models/income_source.dart';
import '../../../shared/widgets/widgets.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../income_sources/application/income_sources_providers.dart';
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
    final accounts = {
      for (final account
          in ref.watch(accountsProvider).asData?.value ??
              const <FinancialAccount>[])
        account.id: account,
    };
    final sources = {
      for (final source
          in ref.watch(incomeSourcesProvider).asData?.value ??
              const <IncomeSource>[])
        source.id: source,
    };

    return GlassScaffold(
      appBar: AppBar(
        title: Text(l10n.navHistory),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(CupertinoIcons.gear_alt_fill),
          ),
        ],
      ),
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
                    return Dismissible(
                      key: ValueKey(tx.id),
                      direction: DismissDirection.endToStart,
                      background: _DeleteBackground(label: l10n.commonDelete),
                      confirmDismiss: (_) => _deleteTransaction(
                        context: context,
                        ref: ref,
                        transactionId: tx.id,
                      ),
                      child: TransactionTile(
                        transaction: tx,
                        category: categories[tx.categoryId],
                        accountName: accounts[tx.accountId]?.name,
                        incomeSourceName: sources[tx.incomeSourceId]?.name,
                        showDate: true,
                      ),
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

Future<bool> _deleteTransaction({
  required BuildContext context,
  required WidgetRef ref,
  required String transactionId,
}) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.transactionDeleteTitle),
      content: Text(l10n.transactionDeleteMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            l10n.commonDelete,
            style: TextStyle(color: dialogContext.colors.expense),
          ),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  final deleted = await ref
      .read(transactionsControllerProvider.notifier)
      .delete(transactionId);
  if (!context.mounted) return false;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        deleted ? l10n.transactionDeleteSuccess : l10n.transactionDeleteError,
      ),
    ),
  );

  // The provider refresh removes the row. Returning false lets Dismissible
  // settle safely instead of requiring the refreshed list in the same frame.
  return false;
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
    decoration: BoxDecoration(
      color: context.colors.expense,
      borderRadius: AppRadii.cardRadius,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(CupertinoIcons.trash, color: Colors.white),
        AppSpacing.gapSm,
        Text(
          label,
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ],
    ),
  );
}

class _Filters extends ConsumerWidget {
  const _Filters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(transactionFilterProvider);
    final controller = ref.read(transactionFilterProvider.notifier);
    final accounts =
        ref.watch(accountsProvider).asData?.value ?? const <FinancialAccount>[];
    final sources =
        ref.watch(incomeSourcesProvider).asData?.value ??
        const <IncomeSource>[];

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screen,
        children: [
          for (final type in TransactionType.values)
            _Chip(
              label: type.localizedLabel(l10n),
              selected: filter.type == type,
              onTap: () => controller.toggleType(type),
            ),
          const _Divider(),
          for (final currency in const ['CAD', 'USD'])
            _Chip(
              label: currency,
              selected: filter.currency == currency,
              onTap: () => controller.toggleCurrency(currency),
            ),
          if (accounts.isNotEmpty) ...[
            const _Divider(),
            for (final account in accounts)
              _Chip(
                label: account.name,
                selected: filter.accountId == account.id,
                onTap: () => controller.toggleAccount(account.id),
              ),
          ],
          if (sources.isNotEmpty) ...[
            const _Divider(),
            for (final source in sources.where((source) => !source.isArchived))
              _Chip(
                label: source.name,
                selected: filter.incomeSourceId == source.id,
                onTap: () => controller.toggleIncomeSource(source.id),
              ),
          ],
          const _Divider(),
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
          const _Divider(),
          _Chip(
            label: l10n.transactionsFilterUncategorized,
            selected: filter.uncategorizedOnly,
            onTap: controller.toggleUncategorized,
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
