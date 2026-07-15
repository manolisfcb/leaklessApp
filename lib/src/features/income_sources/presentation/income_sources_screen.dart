import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../domain/enums/finance_enums.dart';
import '../../../domain/models/income_source.dart';
import '../../../shared/widgets/widgets.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../household/application/household_providers.dart';
import '../application/income_sources_providers.dart';

class IncomeSourcesScreen extends ConsumerWidget {
  const IncomeSourcesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(incomeSourcesProvider);
    return GlassScaffold(
      appBar: AppBar(title: Text(context.l10n.incomeSourcesTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context, ref),
        child: const Icon(CupertinoIcons.add),
      ),
      body: sources.when(
        loading: () => const AppLoader(),
        error: (_, _) => AppEmptyState(
          icon: CupertinoIcons.exclamationmark_circle,
          title: context.l10n.incomeSourcesLoadError,
        ),
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            120,
          ),
          children: [
            for (final source in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: GlassCard(
                  onTap: () => _edit(context, ref, source: source),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.briefcase),
                      AppSpacing.gapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(source.name, style: AppTypography.titleMedium),
                            Text(
                              '${source.defaultCurrency}${source.isArchived ? ' · ${context.l10n.archivedLabel}' : ''}',
                            ),
                          ],
                        ),
                      ),
                      if (!source.isArchived)
                        IconButton(
                          tooltip: context.l10n.archiveAction,
                          onPressed: () => ref
                              .read(incomeSourcesControllerProvider.notifier)
                              .archive(source.id),
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

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    IncomeSource? source,
  }) async {
    final result =
        await showDialog<({String name, String currency, String? accountId})>(
          context: context,
          builder: (_) => _SourceDialog(source: source),
        );
    if (result == null) return;
    final household = await ref.read(currentHouseholdProvider.future);
    if (household == null) return;
    await ref
        .read(incomeSourcesControllerProvider.notifier)
        .save(
          IncomeSource(
            id: source?.id ?? '',
            householdId: household.id,
            name: result.name,
            defaultCurrency: result.currency,
            defaultAccountId: result.accountId,
            type: source?.type ?? IncomeSourceType.other,
            iconName: source?.iconName ?? 'briefcase',
            colorHex: source?.colorHex,
            isArchived: source?.isArchived ?? false,
          ),
        );
  }
}

class _SourceDialog extends ConsumerStatefulWidget {
  const _SourceDialog({this.source});
  final IncomeSource? source;
  @override
  ConsumerState<_SourceDialog> createState() => _SourceDialogState();
}

class _SourceDialogState extends ConsumerState<_SourceDialog> {
  late final name = TextEditingController(text: widget.source?.name ?? '');
  late String currency = widget.source?.defaultCurrency ?? 'CAD';
  late String? accountId = widget.source?.defaultAccountId;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts =
        ref.watch(activeAccountsProvider).asData?.value ?? const [];
    return AlertDialog(
      title: Text(
        widget.source == null
            ? context.l10n.incomeSourceNew
            : context.l10n.sourceEdit,
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
            onChanged: (value) => setState(() {
              currency = value!;
              accountId = null;
            }),
          ),
          DropdownButtonFormField<String>(
            initialValue: accounts.any((a) => a.id == accountId)
                ? accountId
                : null,
            decoration: InputDecoration(labelText: context.l10n.usualAccount),
            items: [
              for (final account in accounts.where(
                (a) => a.currency == currency,
              ))
                DropdownMenuItem(value: account.id, child: Text(account.name)),
            ],
            onChanged: (value) => setState(() => accountId = value),
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
            if (name.text.trim().isEmpty) return;
            Navigator.pop(context, (
              name: name.text.trim(),
              currency: currency,
              accountId: accountId,
            ));
          },
          child: Text(context.l10n.quickEntrySave),
        ),
      ],
    );
  }
}
