import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/core/errors/app_exception.dart';
import 'package:leakless/src/domain/models/budget.dart';
import 'package:leakless/src/domain/models/money.dart';
import 'package:leakless/src/domain/models/transaction_category.dart';
import 'package:leakless/src/features/budgets/presentation/budget_form_sheet.dart';
import 'package:leakless/src/features/budgets/presentation/budgets_screen.dart';

void main() {
  const food = TransactionCategory(
    id: 'food',
    name: 'Comida',
    iconName: 'food',
  );
  const transport = TransactionCategory(
    id: 'transport',
    name: 'Transporte',
    iconName: 'transport',
  );
  final julyFood = Budget(
    id: 'budget-food',
    householdId: 'household',
    categoryId: food.id,
    limit: const Money(minorUnits: 10000),
    periodStart: DateTime(2026, 7),
  );

  test('new budget excludes categories already budgeted in that month', () {
    final available = availableBudgetCategories(
      categories: const [food, transport],
      budgets: [
        julyFood,
        julyFood.copyWith(id: 'old', periodStart: DateTime(2026, 6)),
      ],
      period: DateTime(2026, 7, 20),
    );

    expect(available, [transport]);
  });

  test('editing keeps the current budget category selectable', () {
    final available = availableBudgetCategories(
      categories: const [food, transport],
      budgets: [julyFood],
      period: DateTime(2026, 7),
      editingBudgetId: julyFood.id,
    );

    expect(available, const [food, transport]);
  });

  test('duplicate constraint has a friendly error message', () {
    const error = ServerException(
      'Failed to create budget',
      cause: _BackendError('PostgrestException code: 23505'),
    );

    expect(
      budgetErrorMessage(error),
      'Ya existe un presupuesto para esa categoría este mes.',
    );
  });
}

class _BackendError {
  const _BackendError(this.message);

  final String message;

  @override
  String toString() => message;
}
