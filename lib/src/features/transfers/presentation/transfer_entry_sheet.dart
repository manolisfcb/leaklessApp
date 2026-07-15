import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../domain/models/financial_account.dart';
import '../../../domain/models/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../accounts/application/accounts_providers.dart';
import '../application/transfer_controller.dart';

class TransferEntrySheet extends ConsumerStatefulWidget {
  const TransferEntrySheet({super.key});
  @override
  ConsumerState<TransferEntrySheet> createState() => _TransferEntrySheetState();
}

class _TransferEntrySheetState extends ConsumerState<TransferEntrySheet> {
  final sent = TextEditingController();
  final received = TextEditingController();
  String? fromId;
  String? toId;

  @override
  void dispose() {
    sent.dispose();
    received.dispose();
    super.dispose();
  }

  Future<void> _save(List<FinancialAccount> accounts) async {
    FinancialAccount? from;
    FinancialAccount? to;
    for (final account in accounts) {
      if (account.id == fromId) from = account;
      if (account.id == toId) to = account;
    }
    final sentValue = num.tryParse(sent.text.replaceAll(',', '.'));
    final receivedValue = num.tryParse(received.text.replaceAll(',', '.'));
    if (from == null ||
        to == null ||
        sentValue == null ||
        receivedValue == null ||
        sentValue <= 0 ||
        receivedValue <= 0)
      return;
    final ok = await ref
        .read(transferControllerProvider.notifier)
        .submit(
          from: from,
          to: to,
          sent: Money.fromMajor(sentValue, currency: from.currency),
          received: Money.fromMajor(receivedValue, currency: to.currency),
        );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accounts =
        ref.watch(activeAccountsProvider).asData?.value ??
        const <FinancialAccount>[];
    final saving = ref.watch(transferControllerProvider).isLoading;
    final from = accounts.where((a) => a.id == fromId).firstOrNull;
    final to = accounts.where((a) => a.id == toId).firstOrNull;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            key: const Key('transfer-from-account'),
            initialValue: fromId,
            decoration: InputDecoration(labelText: context.l10n.accountSource),
            items: [
              for (final a in accounts)
                DropdownMenuItem(
                  value: a.id,
                  child: Text('${a.name} · ${a.currency}'),
                ),
            ],
            onChanged: (value) => setState(() => fromId = value),
          ),
          AppSpacing.gapLg,
          TextField(
            key: const Key('transfer-sent-amount'),
            controller: sent,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: context.l10n.amountSent,
              suffixText: from?.currency,
            ),
          ),
          AppSpacing.gapXl,
          DropdownButtonFormField<String>(
            key: const Key('transfer-to-account'),
            initialValue: toId,
            decoration: InputDecoration(
              labelText: context.l10n.accountDestination,
            ),
            items: [
              for (final a in accounts.where((a) => a.id != fromId))
                DropdownMenuItem(
                  value: a.id,
                  child: Text('${a.name} · ${a.currency}'),
                ),
            ],
            onChanged: (value) => setState(() => toId = value),
          ),
          AppSpacing.gapLg,
          TextField(
            key: const Key('transfer-received-amount'),
            controller: received,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: context.l10n.amountReceived,
              suffixText: to?.currency,
            ),
          ),
          AppSpacing.gapXl,
          GlassButton(
            key: const Key('transfer-save-button'),
            label: context.l10n.saveTransfer,
            loading: saving,
            onPressed: saving ? null : () => _save(accounts),
          ),
        ],
      ),
    );
  }
}
