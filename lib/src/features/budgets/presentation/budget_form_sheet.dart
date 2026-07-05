import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/category_names.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../domain/models/budget.dart';
import '../../../domain/models/money.dart';
import '../../../domain/models/transaction_category.dart';
import '../../../shared/widgets/widgets.dart';
import '../../household/application/household_providers.dart';
import '../../transactions/application/categories_providers.dart';
import '../application/budgets_providers.dart';

/// Form for creating or editing one monthly category budget.
class BudgetFormSheet extends ConsumerStatefulWidget {
  const BudgetFormSheet({this.budget, super.key});

  final Budget? budget;

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late String? _categoryId;

  DateTime get _period => widget.budget?.periodStart ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _categoryId = widget.budget?.categoryId;
    _amount = TextEditingController(text: _initialAmount(widget.budget?.limit));
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
            if (categories.isEmpty)
              Text(
                'Todas las categorías ya tienen presupuesto este mes.',
                style: AppTypography.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                ),
              )
            else
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => AppSpacing.gapSm,
                  itemBuilder: (context, index) {
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
              child: Row(
                children: [
                  Icon(CupertinoIcons.bell, color: context.colors.textTertiary),
                  AppSpacing.gapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alertas de presupuesto',
                          style: AppTypography.labelLarge,
                        ),
                        Text(
                          'Disponible próximamente',
                          style: AppTypography.bodySmall.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Switch(value: false, onChanged: null),
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
