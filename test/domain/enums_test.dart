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

  group('domain labels', () {
    test('priority labels are the product wording', () {
      expect(TransactionPriority.ant.label, 'Hormiga');
      expect(TransactionPriority.necessity.label, 'Necesidad');
    });

    test('responsible labels', () {
      expect(ResponsibleType.me.label, 'Tú');
      expect(ResponsibleType.partner.label, 'Pareja');
      expect(ResponsibleType.shared.label, 'Compartido');
    });
  });

  group('localized enum labels', () {
    final es = lookupAppLocalizations(const Locale('es'));
    final en = lookupAppLocalizations(const Locale('en'));
    final pt = lookupAppLocalizations(const Locale('pt'));

    test('spanish matches the legacy .label wording', () {
      for (final type in TransactionType.values) {
        expect(type.localizedLabel(es), type.label);
      }
      for (final priority in TransactionPriority.values) {
        expect(priority.localizedLabel(es), priority.label);
      }
      for (final source in TransactionSource.values) {
        expect(source.localizedLabel(es), source.label);
      }
      for (final responsible in ResponsibleType.values) {
        expect(responsible.localizedLabel(es), responsible.label);
      }
      for (final status in BudgetStatus.values) {
        expect(status.localizedLabel(es), status.label);
      }
      for (final status in GoalStatus.values) {
        expect(status.localizedLabel(es), status.label);
      }
      for (final status in SubscriptionStatus.values) {
        expect(status.localizedLabel(es), status.label);
      }
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
