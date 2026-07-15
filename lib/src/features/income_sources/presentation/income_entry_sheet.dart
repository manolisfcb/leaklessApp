import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../domain/enums/finance_enums.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../domain/models/financial_account.dart';
import '../../../domain/models/income_source.dart';
import '../../../domain/models/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../household/application/household_providers.dart';
import '../../quick_entry/application/quick_entry_controller.dart';
import '../application/income_sources_providers.dart';

class IncomeEntrySheet extends ConsumerStatefulWidget {
  const IncomeEntrySheet({super.key});

  @override
  ConsumerState<IncomeEntrySheet> createState() => _IncomeEntrySheetState();
}

class _IncomeEntrySheetState extends ConsumerState<IncomeEntrySheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _currency;
  String? _accountId;
  String? _sourceId;
  final DateTime _occurredAt = DateTime.now();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final currency = _currency ?? 'CAD';
    final parsed = num.tryParse(_amount.text.replaceAll(',', '.'));
    if (parsed == null ||
        parsed <= 0 ||
        _sourceId == null ||
        _accountId == null) {
      return;
    }
    final amount = Money.fromMajor(parsed, currency: currency);
    final ok = await ref
        .read(quickEntryControllerProvider.notifier)
        .submit(
          amountMinorUnits: amount.minorUnits,
          type: TransactionType.income,
          priority: TransactionPriority.future,
          responsible: ResponsibleType.me,
          currency: currency,
          accountId: _accountId,
          incomeSourceId: _sourceId,
          description: _note.text.trim().isEmpty ? null : _note.text.trim(),
          occurredAt: _occurredAt,
        );
    if (ok && mounted) Navigator.of(context).pop();
  }

  void _selectSource(IncomeSource source) {
    setState(() {
      _sourceId = source.id;
      _currency = source.defaultCurrency;
      _accountId = source.defaultAccountId;
    });
  }

  Future<void> _createSource() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _NewSourceDialog(),
    );
    if (name == null || name.trim().isEmpty) return;
    final household = await ref.read(currentHouseholdProvider.future);
    if (household == null) return;
    final accounts = ref.read(activeAccountsProvider).asData?.value ?? const [];
    final account = accounts.cast<FinancialAccount?>().firstWhere(
      (item) => item?.isDefault == true,
      orElse: () => accounts.isEmpty ? null : accounts.first,
    );
    final saved = await ref
        .read(incomeSourcesControllerProvider.notifier)
        .save(
          IncomeSource(
            id: '',
            householdId: household.id,
            name: name.trim(),
            type: IncomeSourceType.other,
            defaultCurrency: account?.currency ?? household.currency,
            defaultAccountId: account?.id,
          ),
        );
    if (saved != null && mounted) _selectSource(saved);
  }

  @override
  Widget build(BuildContext context) {
    final householdCurrency =
        ref.watch(currentHouseholdProvider).asData?.value?.currency ?? 'CAD';
    final currency = _currency ?? householdCurrency;
    final accounts =
        ref.watch(activeAccountsProvider).asData?.value ??
        const <FinancialAccount>[];
    final sources =
        ref.watch(incomeSourcesProvider).asData?.value ??
        const <IncomeSource>[];
    final saving = ref.watch(quickEntryControllerProvider).isLoading;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('income-amount-field'),
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: context.l10n.amountReceived,
              suffixText: currency,
            ),
          ),
          AppSpacing.gapLg,
          DropdownButtonFormField<String>(
            key: const Key('income-source-field'),
            initialValue: _sourceId,
            decoration: InputDecoration(
              labelText: context.l10n.incomeSourceLabel,
            ),
            items: [
              for (final source in sources.where(
                (source) => !source.isArchived,
              ))
                DropdownMenuItem(value: source.id, child: Text(source.name)),
            ],
            onChanged: (id) {
              for (final source in sources) {
                if (source.id == id) {
                  _selectSource(source);
                  break;
                }
              }
            },
          ),
          TextButton.icon(
            onPressed: _createSource,
            icon: const Icon(Icons.add),
            label: Text(context.l10n.incomeSourceNew),
          ),
          AppSpacing.gapMd,
          DropdownButtonFormField<String>(
            key: const Key('income-currency-field'),
            initialValue: currency,
            decoration: InputDecoration(labelText: context.l10n.currencyLabel),
            items: const ['CAD', 'USD']
                .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                .toList(),
            onChanged: (value) => setState(() {
              _currency = value;
              _accountId = null;
            }),
          ),
          AppSpacing.gapLg,
          DropdownButtonFormField<String>(
            key: const Key('income-account-field'),
            initialValue: accounts.any((account) => account.id == _accountId)
                ? _accountId
                : null,
            decoration: InputDecoration(
              labelText: context.l10n.accountDestination,
            ),
            items: [
              for (final account in accounts.where(
                (account) => account.currency == currency,
              ))
                DropdownMenuItem(
                  value: account.id,
                  child: Text('${account.name} · ${account.currency}'),
                ),
            ],
            onChanged: (value) => setState(() => _accountId = value),
          ),
          AppSpacing.gapLg,
          TextFormField(
            controller: _note,
            decoration: InputDecoration(labelText: context.l10n.optionalNote),
          ),
          AppSpacing.gapXl,
          GlassButton(
            key: const Key('income-save-button'),
            label: context.l10n.saveIncome,
            loading: saving,
            onPressed: saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _NewSourceDialog extends StatefulWidget {
  const _NewSourceDialog();
  @override
  State<_NewSourceDialog> createState() => _NewSourceDialogState();
}

class _NewSourceDialogState extends State<_NewSourceDialog> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.incomeSourceNew),
    content: TextField(
      controller: controller,
      autofocus: true,
      decoration: InputDecoration(labelText: context.l10n.nameLabel),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.commonCancel),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, controller.text),
        child: Text(context.l10n.quickEntrySave),
      ),
    ],
  );
}
