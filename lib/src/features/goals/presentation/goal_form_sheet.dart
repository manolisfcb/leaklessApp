import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../domain/models/goal.dart';
import '../../../domain/models/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../household/application/household_providers.dart';
import '../application/goals_providers.dart';

class GoalFormSheet extends ConsumerStatefulWidget {
  const GoalFormSheet({this.goal, super.key});

  final Goal? goal;

  static Future<void> show(BuildContext context, {Goal? goal}) =>
      GlassBottomSheet.show<void>(
        context,
        title: goal == null ? 'Nueva meta' : 'Editar meta',
        builder: (_) => GoalFormSheet(goal: goal),
      );

  @override
  ConsumerState<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal?.name ?? '');
    _amountController = TextEditingController(
      text: widget.goal?.target.major.toString() ?? '',
    );
    _deadline = widget.goal?.deadline;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 30),
    );
    if (selected != null && mounted) setState(() => _deadline = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final major = double.parse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    final household = widget.goal == null
        ? await ref.read(currentHouseholdProvider.future)
        : null;
    final currency =
        widget.goal?.target.currency ?? household?.currency ?? 'USD';
    final saved = await ref
        .read(goalsControllerProvider.notifier)
        .save(
          goal: widget.goal,
          name: _nameController.text,
          targetAmountMinorUnits: Money.fromMajor(
            major,
            currency: currency,
          ).minorUnits,
          deadline: _deadline,
        );
    if (saved && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(goalsControllerProvider).isLoading;
    final deadlineLabel = _deadline == null
        ? 'Sin fecha límite'
        : '${_deadline!.day.toString().padLeft(2, '0')}/'
              '${_deadline!.month.toString().padLeft(2, '0')}/'
              '${_deadline!.year}';

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('goal-name-field'),
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Escribe un nombre'
                  : null,
            ),
            AppSpacing.gapLg,
            TextFormField(
              key: const Key('goal-amount-field'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Monto objetivo'),
              validator: (value) {
                final amount = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );
                return amount == null || amount <= 0
                    ? 'Ingresa un monto mayor a cero'
                    : null;
              },
            ),
            AppSpacing.gapLg,
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _pickDeadline,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(deadlineLabel),
                  ),
                ),
                if (_deadline != null)
                  IconButton(
                    tooltip: 'Quitar fecha límite',
                    onPressed: () => setState(() => _deadline = null),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            AppSpacing.gapXl,
            GlassButton(
              key: const Key('goal-save-button'),
              label: widget.goal == null ? 'Crear meta' : 'Guardar cambios',
              loading: loading,
              onPressed: loading ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
