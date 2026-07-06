import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/core/l10n/enum_labels.dart';
import 'package:leakless/src/core/l10n/l10n.dart';
import 'package:leakless/src/domain/enums/enums.dart';

void main() {
  group('BudgetStatus.fromRatio', () {
    test('maps thresholds at 75% and 100%', () {
      expect(BudgetStatus.fromRatio(0.0), BudgetStatus.normal);
      expect(BudgetStatus.fromRatio(0.74), BudgetStatus.normal);
      expect(BudgetStatus.fromRatio(0.75), BudgetStatus.warning);
      expect(BudgetStatus.fromRatio(0.99), BudgetStatus.warning);
      expect(BudgetStatus.fromRatio(1.0), BudgetStatus.exceeded);
      expect(BudgetStatus.fromRatio(1.5), BudgetStatus.exceeded);
    });
  });

  group('localized enum labels', () {
    final es = lookupAppLocalizations(const Locale('es'));
    final en = lookupAppLocalizations(const Locale('en'));
    final pt = lookupAppLocalizations(const Locale('pt'));

    test('spanish keeps the product wording', () {
      expect(TransactionPriority.ant.localizedLabel(es), 'Hormiga');
      expect(TransactionPriority.necessity.localizedLabel(es), 'Necesidad');
      expect(ResponsibleType.me.localizedLabel(es), 'Tú');
      expect(ResponsibleType.partner.localizedLabel(es), 'Pareja');
      expect(ResponsibleType.shared.localizedLabel(es), 'Compartido');
      expect(TransactionType.expense.localizedLabel(es), 'Gasto');
      expect(TransactionSource.plaid.localizedLabel(es), 'Banco');
      expect(BudgetStatus.exceeded.localizedLabel(es), 'Límite superado');
      expect(GoalStatus.completed.localizedLabel(es), 'Completada');
      expect(SubscriptionStatus.trial.localizedLabel(es), 'Prueba');
    });

    test('english and portuguese translate the product wording', () {
      expect(TransactionPriority.ant.localizedLabel(en), 'Ant');
      expect(TransactionPriority.ant.localizedLabel(pt), 'Formiga');
      expect(TransactionType.expense.localizedLabel(en), 'Expense');
      expect(TransactionType.expense.localizedLabel(pt), 'Despesa');
      expect(ResponsibleType.me.localizedLabel(en), 'You');
      expect(ResponsibleType.me.localizedLabel(pt), 'Você');
      expect(BudgetStatus.exceeded.localizedLabel(en), 'Over the limit');
      expect(GoalStatus.completed.localizedLabel(pt), 'Concluída');
      expect(SubscriptionStatus.trial.localizedLabel(en), 'Trial');
      expect(TransactionSource.plaid.localizedLabel(es), 'Banco');
    });
  });
}
