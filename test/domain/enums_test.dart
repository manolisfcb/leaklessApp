import 'package:flutter_test/flutter_test.dart';
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
}
