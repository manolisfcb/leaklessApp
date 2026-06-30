import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../shared/widgets/widgets.dart';
import '../../household/application/household_providers.dart';
import '../../transactions/application/categories_providers.dart';
import '../application/quick_entry_controller.dart';

/// The Quick Entry form. Designed for one-handed use and shown inside a
/// [GlassBottomSheet]. It only collects input and delegates persistence to
/// [QuickEntryController] (quality rule #4/#6).
class QuickEntrySheet extends ConsumerStatefulWidget {
  const QuickEntrySheet({super.key});

  @override
  ConsumerState<QuickEntrySheet> createState() => _QuickEntrySheetState();
}

class _QuickEntrySheetState extends ConsumerState<QuickEntrySheet> {
  int _cents = 0;
  TransactionType _type = TransactionType.expense;
  ResponsibleType _responsible = ResponsibleType.me;
  TransactionPriority _priority = TransactionPriority.necessity;
  String? _categoryId;

  void _press(int digit) =>
      setState(() => _cents = (_cents * 10 + digit).clamp(0, 99999999));
  void _backspace() => setState(() => _cents ~/= 10);

  Future<void> _save() async {
    if (_cents == 0) return;
    final ok = await ref.read(quickEntryControllerProvider.notifier).submit(
      amountMinorUnits: _cents,
      type: _type,
      priority: _priority,
      responsible: _responsible,
      categoryId: _categoryId,
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currency =
        ref.watch(currentHouseholdProvider).asData?.value?.currency ?? 'USD';
    final categories = ref.watch(categoriesProvider).asData?.value ?? const [];
    final saving = ref.watch(quickEntryControllerProvider).isLoading;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              MoneyFormatter.format(_cents, currencyCode: currency),
              style: AppTypography.displayLarge.copyWith(
                color: _cents == 0 ? colors.textTertiary : colors.textPrimary,
              ),
            ),
          ),
          AppSpacing.gapLg,
          _Segmented<TransactionType>(
            value: _type,
            onChanged: (v) => setState(() => _type = v),
            options: const {
              TransactionType.expense: 'Gasto',
              TransactionType.income: 'Ingreso',
            },
          ),
          AppSpacing.gapXl,
          const _Label('¿Quién?'),
          AppSpacing.gapSm,
          _Segmented<ResponsibleType>(
            value: _responsible,
            onChanged: (v) => setState(() => _responsible = v),
            options: {
              for (final r in ResponsibleType.values) r: r.label,
            },
          ),
          AppSpacing.gapXl,
          const _Label('Categoría'),
          AppSpacing.gapSm,
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _CategoryChip(
                      label: c.name,
                      icon: CategoryIcons.forKey(c.iconName),
                      selected: _categoryId == c.id,
                      onTap: () => setState(
                        () => _categoryId = _categoryId == c.id ? null : c.id,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          AppSpacing.gapXl,
          const _Label('Prioridad'),
          AppSpacing.gapSm,
          _PriorityPicker(
            value: _priority,
            onChanged: (v) => setState(() => _priority = v),
          ),
          AppSpacing.gapXl,
          _Keypad(onDigit: _press, onBackspace: _backspace),
          AppSpacing.gapLg,
          GlassButton(
            label: 'Guardar',
            icon: CupertinoIcons.checkmark_alt,
            loading: saving,
            onPressed: _cents == 0 || saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTypography.labelLarge.copyWith(color: context.colors.textSecondary),
  );
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.onChanged,
    required this.options,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final Map<T, String> options;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.glassFill,
        borderRadius: AppRadii.pillRadius,
        border: Border.all(color: colors.glassBorder),
      ),
      child: Row(
        children: [
          for (final entry in options.entries)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(entry.key),
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: entry.key == value
                        ? colors.primary
                        : Colors.transparent,
                    borderRadius: AppRadii.pillRadius,
                  ),
                  child: Text(
                    entry.value,
                    style: AppTypography.labelLarge.copyWith(
                      color: entry.key == value
                          ? Colors.white
                          : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? colors.goalSoft : colors.glassFill,
          borderRadius: AppRadii.pillRadius,
          border: Border.all(
            color: selected ? colors.primary : colors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? colors.primary : colors.textSecondary,
            ),
            AppSpacing.gapXs,
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: selected ? colors.primary : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityPicker extends StatelessWidget {
  const _PriorityPicker({required this.value, required this.onChanged});
  final TransactionPriority value;
  final ValueChanged<TransactionPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        for (final p in TransactionPriority.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: GestureDetector(
                onTap: () => onChanged(p),
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: p == value ? colors.goalSoft : colors.glassFill,
                    borderRadius: AppRadii.cardRadius,
                    border: Border.all(
                      color: p == value ? colors.primary : colors.glassBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        CategoryIcons.forPriority(p),
                        size: 18,
                        color: p == value ? colors.primary : colors.textSecondary,
                      ),
                      AppSpacing.gapXs,
                      Text(
                        p.label,
                        textAlign: TextAlign.center,
                        style: AppTypography.labelSmall.copyWith(
                          color: p == value
                              ? colors.primary
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});
  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget key(Widget child, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.glassFill,
          borderRadius: AppRadii.cardRadius,
          border: Border.all(color: colors.glassBorder),
        ),
        child: child,
      ),
    );

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.9,
      children: [
        for (var i = 1; i <= 9; i++)
          key(Text('$i', style: AppTypography.titleLarge), () => onDigit(i)),
        const SizedBox.shrink(),
        key(Text('0', style: AppTypography.titleLarge), () => onDigit(0)),
        key(
          Icon(CupertinoIcons.delete_left, color: colors.textSecondary),
          onBackspace,
        ),
      ],
    );
  }
}
