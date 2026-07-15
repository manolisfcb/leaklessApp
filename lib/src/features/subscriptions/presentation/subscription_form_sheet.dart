import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/category_names.dart';
import '../../../core/l10n/enum_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../domain/enums/finance_enums.dart';
import '../../../domain/models/money.dart';
import '../../../domain/models/subscription_item.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../domain/models/financial_account.dart';
import '../../../shared/widgets/widgets.dart';
import '../../household/application/household_providers.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../transactions/application/categories_providers.dart';
import '../application/subscriptions_providers.dart';

/// Form for creating or editing one recurring subscription (name, amount,
/// frequency, next-charge date, category and an optional local reminder).
class SubscriptionFormSheet extends ConsumerStatefulWidget {
  const SubscriptionFormSheet({this.subscription, super.key});

  final SubscriptionItem? subscription;

  static Future<void> show(
    BuildContext context, {
    SubscriptionItem? subscription,
  }) => GlassBottomSheet.show<void>(
    context,
    title: subscription == null
        ? context.l10n.subscriptionNew
        : context.l10n.subscriptionEdit,
    builder: (_) => SubscriptionFormSheet(subscription: subscription),
  );

  @override
  ConsumerState<SubscriptionFormSheet> createState() =>
      _SubscriptionFormSheetState();
}

/// Days-before-charge presets offered by the reminder chips.
const _reminderDayOptions = [0, 1, 3, 7];

class _SubscriptionFormSheetState extends ConsumerState<SubscriptionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late SubscriptionFrequency _frequency;
  late DateTime? _nextChargeAt;
  late String? _categoryId;
  late String? _currency;
  late String? _accountId;
  late bool _reminderEnabled;
  late int _reminderDaysBefore;

  @override
  void initState() {
    super.initState();
    final subscription = widget.subscription;
    _name = TextEditingController(text: subscription?.name ?? '');
    _amount = TextEditingController(text: _initialAmount(subscription?.amount));
    _frequency = subscription?.frequency ?? SubscriptionFrequency.monthly;
    _nextChargeAt = subscription?.nextChargeAt;
    _categoryId = subscription?.categoryId;
    _currency = subscription?.amount.currency;
    _accountId = subscription?.accountId;
    _reminderEnabled = subscription?.reminderEnabled ?? false;
    _reminderDaysBefore = subscription?.reminderDaysBefore ?? 1;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _setReminderEnabled(bool value) {
    setState(() => _reminderEnabled = value);
    // Contextual permission ask: the first reminder the user turns on is the
    // moment notifications become relevant. Fire-and-forget.
    if (value) {
      unawaited(
        ref.read(notificationPermissionHandlerProvider).ensurePermission(),
      );
    }
  }

  Future<void> _pickNextCharge() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _nextChargeAt ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 30),
    );
    if (selected != null && mounted) setState(() => _nextChargeAt = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final currency =
        _currency ??
        ref.read(currentHouseholdProvider).asData?.value?.currency ??
        'USD';
    final amount = _parseAmount(_amount.text, currency);
    final saved = await ref
        .read(subscriptionsControllerProvider.notifier)
        .save(
          subscriptionId: widget.subscription?.id,
          name: _name.text,
          amountMinorUnits: amount!.minorUnits,
          currency: currency,
          accountId: _accountId,
          frequency: _frequency,
          nextChargeAt: _nextChargeAt,
          categoryId: _categoryId,
          status: widget.subscription?.status ?? SubscriptionStatus.active,
          reminderEnabled: _reminderEnabled,
          reminderDaysBefore: _reminderDaysBefore,
        );
    if (saved && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final saving = ref.watch(subscriptionsControllerProvider).isLoading;
    final categories =
        ref.watch(categoriesProvider).asData?.value ??
        const <TransactionCategory>[];
    final currency =
        _currency ??
        ref.watch(currentHouseholdProvider).asData?.value?.currency ??
        'USD';
    final accounts =
        ref.watch(activeAccountsProvider).asData?.value ??
        const <FinancialAccount>[];
    final nextChargeLabel = _nextChargeAt == null
        ? l10n.subscriptionNextChargeNone
        : DateFormat.yMMMMd().format(_nextChargeAt!);

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('subscription-name-field'),
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.subscriptionNameLabel,
                hintText: l10n.subscriptionNameHint,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.subscriptionNameRequired
                  : null,
            ),
            AppSpacing.gapLg,
            DropdownButtonFormField<String>(
              key: const Key('subscription-currency-field'),
              initialValue: currency,
              decoration: InputDecoration(labelText: l10n.billedCurrency),
              items: const ['CAD', 'USD']
                  .map(
                    (code) => DropdownMenuItem(value: code, child: Text(code)),
                  )
                  .toList(),
              onChanged: saving
                  ? null
                  : (value) => setState(() {
                      _currency = value;
                      _accountId = null;
                    }),
            ),
            AppSpacing.gapLg,
            TextFormField(
              key: const Key('subscription-amount-field'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.subscriptionAmountLabel,
                prefixIcon: const Icon(CupertinoIcons.money_dollar),
                suffixText: currency,
                hintText: '0.00',
              ),
              validator: (value) {
                final amount = _parseAmount(value ?? '', currency);
                if (amount == null || amount.minorUnits <= 0) {
                  return l10n.subscriptionAmountRequired;
                }
                return null;
              },
            ),
            AppSpacing.gapLg,
            DropdownButtonFormField<String>(
              key: const Key('subscription-account-field'),
              initialValue: accounts.any((account) => account.id == _accountId)
                  ? _accountId
                  : null,
              decoration: InputDecoration(labelText: l10n.usualAccount),
              items: [
                for (final account in accounts.where(
                  (account) => account.currency == currency,
                ))
                  DropdownMenuItem(
                    value: account.id,
                    child: Text('${account.name} · ${account.currency}'),
                  ),
              ],
              onChanged: saving
                  ? null
                  : (value) => setState(() => _accountId = value),
            ),
            AppSpacing.gapXl,
            Text(
              l10n.subscriptionFrequencyLabel,
              style: AppTypography.labelLarge,
            ),
            AppSpacing.gapSm,
            CupertinoSlidingSegmentedControl<SubscriptionFrequency>(
              groupValue: _frequency,
              children: {
                for (final frequency in SubscriptionFrequency.values)
                  frequency: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      frequency.localizedLabel(l10n),
                      style: AppTypography.labelSmall,
                    ),
                  ),
              },
              onValueChanged: saving
                  ? (_) {}
                  : (value) {
                      if (value != null) setState(() => _frequency = value);
                    },
            ),
            AppSpacing.gapXl,
            Text(
              l10n.subscriptionNextChargeLabel,
              style: AppTypography.labelLarge,
            ),
            AppSpacing.gapSm,
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _pickNextCharge,
                    icon: const Icon(CupertinoIcons.calendar),
                    label: Text(nextChargeLabel),
                  ),
                ),
                if (_nextChargeAt != null)
                  IconButton(
                    tooltip: l10n.subscriptionNextChargeClear,
                    onPressed: () => setState(() => _nextChargeAt = null),
                    icon: const Icon(CupertinoIcons.clear),
                  ),
              ],
            ),
            AppSpacing.gapXl,
            Text(
              l10n.subscriptionCategoryLabel,
              style: AppTypography.labelLarge,
            ),
            AppSpacing.gapSm,
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => AppSpacing.gapSm,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected = _categoryId == category.id;
                  return CategoryChip(
                    label: categoryDisplayName(category, l10n),
                    icon: CategoryIcons.forKey(category.iconName),
                    selected: selected,
                    // Tapping the selected chip clears the (optional) category.
                    onTap: () => setState(
                      () => _categoryId = selected ? null : category.id,
                    ),
                  );
                },
              ),
            ),
            AppSpacing.gapXl,
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.bell, color: colors.textTertiary),
                      AppSpacing.gapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.subscriptionReminderTitle,
                              style: AppTypography.labelLarge,
                            ),
                            Text(
                              l10n.subscriptionReminderSubtitle,
                              style: AppTypography.bodySmall.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        key: const Key('subscription-reminder-toggle'),
                        value: _reminderEnabled,
                        onChanged: saving ? null : _setReminderEnabled,
                      ),
                    ],
                  ),
                  if (_reminderEnabled) ...[
                    AppSpacing.gapMd,
                    Text(
                      l10n.subscriptionReminderDaysLabel,
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    AppSpacing.gapSm,
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final days in {
                          ..._reminderDayOptions,
                          _reminderDaysBefore,
                        }.toList()..sort())
                          _ReminderChip(
                            key: Key('subscription-reminder-days-$days'),
                            label: l10n.subscriptionReminderDays(days),
                            selected: _reminderDaysBefore == days,
                            onTap: saving
                                ? null
                                : () => setState(
                                    () => _reminderDaysBefore = days,
                                  ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.gapXl,
            GlassButton(
              key: const Key('subscription-save-button'),
              label: widget.subscription == null
                  ? l10n.subscriptionCreate
                  : l10n.subscriptionSaveChanges,
              icon: CupertinoIcons.checkmark_alt,
              loading: saving,
              onPressed: saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill chip for one reminder-days-before preset.
class _ReminderChip extends StatelessWidget {
  const _ReminderChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.goalSoft : colors.glassFill,
          borderRadius: AppRadii.pillRadius,
          border: Border.all(
            color: selected ? colors.primary : colors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected ? colors.primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

String _initialAmount(Money? money) {
  if (money == null) return '';
  final digits = MoneyFormatter.decimalDigitsFor(money.currency);
  return money.major.toStringAsFixed(digits);
}

Money? _parseAmount(String input, String currency) {
  final normalized = input.trim().replaceAll(',', '.');
  final major = num.tryParse(normalized);
  return major == null ? null : Money.fromMajor(major, currency: currency);
}
