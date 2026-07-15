import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/category_names.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../domain/models/budget.dart';
import '../../../domain/models/money.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../shared/widgets/widgets.dart';
import '../../household/application/household_providers.dart';
import '../../transactions/application/categories_providers.dart';
import '../../transactions/presentation/category_form_sheet.dart';
import '../application/budgets_providers.dart';

/// Form for creating or editing one monthly category budget.
class BudgetFormSheet extends ConsumerStatefulWidget {
  const BudgetFormSheet({this.budget, super.key});

  final Budget? budget;

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

/// Spent-percentage thresholds offered in the form (shown as remaining %).
const _alertThresholdOptions = [50, 75, 80, 90];

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late String? _categoryId;
  late bool _alertEnabled;
  late int _alertThresholdPct;

  DateTime get _period => widget.budget?.periodStart ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _categoryId = widget.budget?.categoryId;
    _amount = TextEditingController(text: _initialAmount(widget.budget?.limit));
    _alertEnabled = widget.budget?.alertEnabled ?? true;
    _alertThresholdPct = widget.budget?.alertThresholdPct ?? 80;
  }

  void _setAlertEnabled(bool value) {
    setState(() => _alertEnabled = value);
    // Contextual permission ask: the first alert the user turns on is the
    // moment notifications become relevant. Fire-and-forget — a denied
    // permission still leaves the in-app banner path working.
    if (value) {
      unawaited(
        ref.read(notificationPermissionHandlerProvider).ensurePermission(),
      );
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) {
      setState(() {});
      return;
    }
    final currency =
        ref.read(currentHouseholdProvider).asData?.value?.currency ??
        widget.budget?.limit.currency ??
        'USD';
    final amount = _parseAmount(_amount.text, currency);
    final saved = await ref
        .read(budgetsControllerProvider.notifier)
        .save(
          budgetId: widget.budget?.id,
          categoryId: _categoryId!,
          amountMinorUnits: amount!.minorUnits,
          periodStart: _period,
          alertEnabled: _alertEnabled,
          alertThresholdPct: _alertThresholdPct,
        );
    if (saved && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final allCategories =
        ref.watch(categoriesProvider).asData?.value ??
        const <TransactionCategory>[];
    final budgets =
        ref.watch(budgetsProvider).asData?.value ?? const <Budget>[];
    final categories = availableBudgetCategories(
      categories: allCategories,
      budgets: budgets,
      period: _period,
      editingBudgetId: widget.budget?.id,
    );
    final saving = ref.watch(budgetsControllerProvider).isLoading;
    final currency =
        ref.watch(currentHouseholdProvider).asData?.value?.currency ??
        widget.budget?.limit.currency ??
        'USD';

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Categoría', style: AppTypography.labelLarge),
            AppSpacing.gapSm,
            if (categories.isEmpty) ...[
              Text(
                'Todas las categorías ya tienen presupuesto este mes.',
                style: AppTypography.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              AppSpacing.gapSm,
            ],
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1,
                separatorBuilder: (_, _) => AppSpacing.gapSm,
                itemBuilder: (context, index) {
                  if (index == categories.length) {
                    return CategoryChip(
                      label: context.l10n.categoryNew,
                      icon: CupertinoIcons.add,
                      selected: false,
                      onTap: () => CategoryFormSheet.show(context),
                    );
                  }
                  final category = categories[index];
                  return CategoryChip(
                    label: categoryDisplayName(category, context.l10n),
                    icon: CategoryIcons.forKey(category.iconName),
                    selected: _categoryId == category.id,
                    onTap: () => setState(() => _categoryId = category.id),
                  );
                },
              ),
            ),
            if (_categoryId == null) ...[
              AppSpacing.gapXs,
              Text(
                'Selecciona una categoría.',
                style: AppTypography.bodySmall.copyWith(
                  color: context.colors.expense,
                ),
              ),
            ],
            AppSpacing.gapXl,
            Text('Límite mensual', style: AppTypography.labelLarge),
            AppSpacing.gapSm,
            TextFormField(
              key: const Key('budget-amount-field'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                prefixIcon: const Icon(CupertinoIcons.money_dollar),
                suffixText: currency,
                hintText: '0.00',
              ),
              validator: (value) {
                final amount = _parseAmount(value ?? '', currency);
                if (amount == null || amount.minorUnits <= 0) {
                  return 'Ingresa un monto mayor que cero.';
                }
                return null;
              },
              onFieldSubmitted: saving ? null : (_) => _save(),
            ),
            AppSpacing.gapXl,
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.bell,
                        color: context.colors.textTertiary,
                      ),
                      AppSpacing.gapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.budgetAlertsTitle,
                              style: AppTypography.labelLarge,
                            ),
                            Text(
                              context.l10n.budgetAlertsSubtitle,
                              style: AppTypography.bodySmall.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        key: const Key('budget-alert-toggle'),
                        value: _alertEnabled,
                        onChanged: saving ? null : _setAlertEnabled,
                      ),
                    ],
                  ),
                  if (_alertEnabled) ...[
                    AppSpacing.gapMd,
                    Text(
                      context.l10n.budgetAlertThresholdLabel,
                      style: AppTypography.labelSmall.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    AppSpacing.gapSm,
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        // A legacy/custom threshold stays selectable when
                        // editing, even if it is not one of the presets.
                        for (final threshold in {
                          ..._alertThresholdOptions,
                          _alertThresholdPct,
                        }.toList()..sort())
                          _ThresholdChip(
                            key: Key('budget-alert-threshold-$threshold'),
                            label: '${100 - threshold}%',
                            selected: _alertThresholdPct == threshold,
                            onTap: saving
                                ? null
                                : () => setState(
                                    () => _alertThresholdPct = threshold,
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
              key: const Key('budget-save-button'),
              label: widget.budget == null
                  ? 'Crear presupuesto'
                  : 'Guardar cambios',
              icon: CupertinoIcons.checkmark_alt,
              loading: saving,
              onPressed: saving || categories.isEmpty ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// Categories that do not yet have a budget in [period]. The currently edited
/// budget is ignored so its category remains selectable.
List<TransactionCategory> availableBudgetCategories({
  required List<TransactionCategory> categories,
  required List<Budget> budgets,
  required DateTime period,
  String? editingBudgetId,
}) {
  final usedCategoryIds = budgets
      .where(
        (budget) =>
            budget.id != editingBudgetId &&
            budget.periodStart.year == period.year &&
            budget.periodStart.month == period.month,
      )
      .map((budget) => budget.categoryId)
      .toSet();
  return categories
      .where((category) => !usedCategoryIds.contains(category.id))
      .toList(growable: false);
}

/// Pill chip for one alert threshold, labeled with the *remaining* percentage
/// (threshold 80 → "20%"), matching how the plan presents alerts to users.
class _ThresholdChip extends StatelessWidget {
  const _ThresholdChip({
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
