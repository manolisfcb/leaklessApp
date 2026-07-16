import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/domain/enums/transaction_enums.dart';
import 'package:leakless/src/domain/models/money.dart';
import 'package:leakless/src/domain/models/transaction.dart';
import 'package:leakless/src/features/transactions/data/transaction_mapper.dart';

void main() {
  group('TransactionMapper source/external_id (Plaid-ready seam)', () {
    Map<String, dynamic> baseRow() => {
      'id': 'tx-1',
      'household_id': 'hh-1',
      'amount': 12.50,
      'currency': 'USD',
      'type': 'expense',
      'priority': 'ant',
      'responsible_type': 'me',
      'occurred_at': '2026-07-04T10:00:00Z',
    };

    test('defaults to manual source when the column is absent', () {
      final tx = TransactionMapper.fromRow(baseRow());
      expect(tx.source, TransactionSource.manual);
      expect(tx.externalId, isNull);
    });

    test('reads an aggregator row (plaid + external_id)', () {
      final tx = TransactionMapper.fromRow({
        ...baseRow(),
        'source': 'plaid',
        'external_id': 'plaid-txn-abc',
      });
      expect(tx.source, TransactionSource.plaid);
      expect(tx.externalId, 'plaid-txn-abc');
      expect(tx.source.isAutomatic, isTrue);
    });

    test('manual insert omits external_id but always writes source', () {
      final insert = TransactionMapper.toInsert(
        Transaction(
          id: '',
          householdId: 'hh-1',
          amount: Money.fromMajor(12.50, currency: 'USD'),
          type: TransactionType.expense,
          priority: TransactionPriority.ant,
          responsible: ResponsibleType.me,
          occurredAt: DateTime.parse('2026-07-04T10:00:00Z'),
        ),
      );
      expect(insert['source'], 'manual');
      expect(insert.containsKey('external_id'), isFalse);
    });

    test('manual insert always serializes occurred_at with a UTC offset', () {
      final occurredAt = DateTime(2026, 7, 15, 21, 28);
      final insert = TransactionMapper.toInsert(
        Transaction(
          id: '',
          householdId: 'hh-1',
          amount: Money.fromMajor(12.50, currency: 'CAD'),
          type: TransactionType.expense,
          priority: TransactionPriority.necessity,
          responsible: ResponsibleType.me,
          occurredAt: occurredAt,
        ),
      );

      expect(insert['occurred_at'], occurredAt.toUtc().toIso8601String());
      expect(insert['occurred_at'], endsWith('Z'));
    });

    test('aggregator insert carries source + external_id for dedup', () {
      final insert = TransactionMapper.toInsert(
        Transaction(
          id: '',
          householdId: 'hh-1',
          amount: Money.fromMajor(12.50, currency: 'USD'),
          type: TransactionType.expense,
          priority: TransactionPriority.necessity,
          responsible: ResponsibleType.shared,
          occurredAt: DateTime.parse('2026-07-04T10:00:00Z'),
          source: TransactionSource.plaid,
          externalId: 'plaid-txn-abc',
        ),
      );
      expect(insert['source'], 'plaid');
      expect(insert['external_id'], 'plaid-txn-abc');
    });
  });
}
