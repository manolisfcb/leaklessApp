import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../domain/models/goal.dart';
import '../../../domain/models/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/goals_providers.dart';

class GoalWithdrawalSheet extends ConsumerStatefulWidget {
  const GoalWithdrawalSheet({required this.goal, super.key});

  final Goal goal;

  static Future<void> show(BuildContext context, {required Goal goal}) =>
      GlassBottomSheet.show<void>(
        context,
        title: 'Retirar de ${goal.name}',
        builder: (_) => GoalWithdrawalSheet(goal: goal),
      );

  @override
  ConsumerState<GoalWithdrawalSheet> createState() =>
      _GoalWithdrawalSheetState();
}

class _GoalWithdrawalSheetState extends ConsumerState<GoalWithdrawalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _withdraw() async {
    if (!_formKey.currentState!.validate()) return;
    final value = num.parse(_amountController.text.trim().replaceAll(',', '.'));
    final amount = Money.fromMajor(value, currency: widget.goal.saved.currency);
    final ok = await ref
        .read(goalsControllerProvider.notifier)
        .withdraw(goalId: widget.goal.id, amountMinorUnits: amount.minorUnits);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(goalsControllerProvider).isLoading;
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Disponible: ${widget.goal.saved.format()}',
              style: AppTypography.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            AppSpacing.gapLg,
            TextFormField(
              key: const Key('goal-withdrawal-amount-field'),
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: 'Monto a retirar',
                suffixText: widget.goal.saved.currency,
              ),
              validator: (raw) {
                final value = num.tryParse(
                  (raw ?? '').trim().replaceAll(',', '.'),
                );
                if (value == null || value <= 0) {
                  return 'Ingresa un monto mayor a cero';
                }
                final amount = Money.fromMajor(
                  value,
                  currency: widget.goal.saved.currency,
                );
                if (amount.minorUnits > widget.goal.saved.minorUnits) {
                  return 'No puedes retirar más de lo ahorrado';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                if (!loading) _withdraw();
              },
            ),
            AppSpacing.gapXl,
            GlassButton(
              key: const Key('goal-withdrawal-submit-button'),
              label: 'Retirar dinero',
              icon: Icons.remove_circle_outline,
              accent: context.colors.expense,
              loading: loading,
              onPressed: loading ? null : _withdraw,
            ),
          ],
        ),
      ),
    );
  }
}
