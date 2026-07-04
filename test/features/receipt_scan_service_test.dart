import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/features/quick_entry/data/receipt_scan_service.dart';

void main() {
  group('SupabaseReceiptScanService.mapExtracted', () {
    test('maps a full extracted payload into a ReceiptScanResult', () {
      final result = SupabaseReceiptScanService.mapExtracted(
        {
          'amount': 12.50,
          'description': 'Cafetería Central',
          'date': '2026-07-01',
          'category': 'Comida',
        },
        currency: 'USD',
      );

      expect(result.amount?.minorUnits, 1250);
      expect(result.amount?.currency, 'USD');
      expect(result.description, 'Cafetería Central');
      expect(result.occurredAt, DateTime.parse('2026-07-01'));
      expect(result.categoryName, 'Comida');
      expect(result.isEmpty, isFalse);
    });

    test('accepts a numeric amount sent as a string', () {
      final result = SupabaseReceiptScanService.mapExtracted(
        {'amount': '9.99'},
        currency: 'USD',
      );

      expect(result.amount?.minorUnits, 999);
    });

    test('respects currencies with different minor-unit scales', () {
      // JPY has 0 decimal digits, so the major value maps 1:1 to minor units.
      final result = SupabaseReceiptScanService.mapExtracted(
        {'amount': 1500},
        currency: 'JPY',
      );

      expect(result.amount?.minorUnits, 1500);
      expect(result.amount?.currency, 'JPY');
    });

    test('drops unusable fields and reports the result as empty', () {
      final result = SupabaseReceiptScanService.mapExtracted(
        {
          'amount': null,
          'description': 'null',
          'date': 'not-a-date',
          'category': '',
        },
        currency: 'USD',
      );

      expect(result.amount, isNull);
      expect(result.description, isNull);
      expect(result.occurredAt, isNull);
      expect(result.categoryName, isNull);
      expect(result.isEmpty, isTrue);
    });

    test('ignores a zero or negative total', () {
      final zero = SupabaseReceiptScanService.mapExtracted(
        {'amount': 0},
        currency: 'USD',
      );
      final negative = SupabaseReceiptScanService.mapExtracted(
        {'amount': -5},
        currency: 'USD',
      );

      expect(zero.amount, isNull);
      expect(negative.amount, isNull);
    });
  });
}
