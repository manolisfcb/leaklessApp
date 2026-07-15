import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../domain/enums/finance_enums.dart';
import '../../../domain/models/financial_account.dart';
import '../../../domain/models/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../household/application/household_providers.dart';
import '../application/accounts_providers.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    return GlassScaffold(
      appBar: AppBar(title: Text(context.l10n.accountsTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref),
        child: const Icon(CupertinoIcons.add),
      ),
      body: accounts.when(
        loading: () => const AppLoader(),
        error: (_, _) => AppEmptyState(
          icon: CupertinoIcons.exclamationmark_circle,
          title: context.l10n.accountsLoadError,
        ),
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            120,
          ),
          children: [
            for (final account in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: GlassCard(
                  onTap: () => _showForm(context, ref, account: account),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.creditcard),
                      AppSpacing.gapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              style: AppTypography.titleMedium,
                            ),
                            Text(
                              '${account.openingBalance.format(showSymbol: false)}${account.isArchived ? ' · ${context.l10n.archivedLabel}' : ''}',
                            ),
                          ],
                        ),
                      ),
                      if (!account.isArchived)
                        IconButton(
                          tooltip: context.l10n.archiveAction,
                          onPressed: () => ref
                              .read(accountsControllerProvider.notifier)
                              .archive(account.id),
                          icon: const Icon(CupertinoIcons.archivebox),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showForm(
    BuildContext context,
    WidgetRef ref, {
    FinancialAccount? account,
  }) async {
    final result =
        await showDialog<({String name, String currency, num opening})>(
          context: context,
          builder: (_) => _AccountDialog(account: account),
        );
    if (result == null) return;
    final household = await ref.read(currentHouseholdProvider.future);
    if (household == null) return;
    await ref
        .read(accountsControllerProvider.notifier)
        .save(
          FinancialAccount(
            id: account?.id ?? '',
            householdId: household.id,
            name: result.name,
            currency: result.currency,
            openingBalance: Money.fromMajor(
              result.opening,
              currency: result.currency,
            ),
            openingBalanceAt: account?.openingBalanceAt ?? DateTime.now(),
            kind: account?.kind ?? AccountKind.checking,
            balanceNature: account?.balanceNature ?? BalanceNature.asset,
            iconName: account?.iconName ?? 'bank',
            colorHex: account?.colorHex,
            isDefault: account?.isDefault ?? false,
            isArchived: account?.isArchived ?? false,
          ),
        );
  }
}

class _AccountDialog extends StatefulWidget {
  const _AccountDialog({this.account});
  final FinancialAccount? account;
  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  late final name = TextEditingController(text: widget.account?.name ?? '');
  late final opening = TextEditingController(
    text: widget.account?.openingBalance.major.toString() ?? '0',
  );
  late String currency = widget.account?.currency ?? 'CAD';
  @override
  void dispose() {
    name.dispose();
    opening.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.account == null
          ? context.l10n.accountNew
          : context.l10n.accountEdit,
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: name,
          decoration: InputDecoration(labelText: context.l10n.nameLabel),
        ),
        DropdownButtonFormField<String>(
          initialValue: currency,
          items: const [
            DropdownMenuItem(value: 'CAD', child: Text('CAD')),
            DropdownMenuItem(value: 'USD', child: Text('USD')),
          ],
          onChanged: widget.account == null
              ? (value) => setState(() => currency = value!)
              : null,
        ),
        TextField(
          controller: opening,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: context.l10n.openingBalance),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.commonCancel),
      ),
      FilledButton(
        onPressed: () {
          final amount = num.tryParse(opening.text.replaceAll(',', '.'));
          if (name.text.trim().isEmpty || amount == null) return;
          Navigator.pop(context, (
            name: name.text.trim(),
            currency: currency,
            opening: amount,
          ));
        },
        child: Text(context.l10n.quickEntrySave),
      ),
    ],
  );
}
