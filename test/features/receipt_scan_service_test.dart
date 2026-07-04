import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leakless/src/features/quick_entry/data/receipt_scan_service.dart';

/// Wraps [text] in the Gemini `generateContent` envelope the service unwraps.
String _geminiEnvelope(String text) => jsonEncode({
  'candidates': [
    {
      'content': {
        'parts': [
          {'text': text},
        ],
      },
    },
  ],
});

void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);

  GeminiReceiptScanService serviceReturning(
    String body, {
    int status = 200,
  }) => GeminiReceiptScanService(
    apiKey: 'test-key',
    client: MockClient((_) async => http.Response(body, status)),
  );

  group('GeminiReceiptScanService.scan', () {
    test('maps a full receipt into a ReceiptScanResult', () async {
      final service = serviceReturning(
        _geminiEnvelope(
          jsonEncode({
            'amount': 12.50,
            'description': 'Cafetería Central',
            'date': '2026-07-01',
            'category': 'Comida',
          }),
        ),
      );

      final result = await service.scan(
        bytes,
        currency: 'USD',
        categoryNames: const ['Comida', 'Transporte'],
      );

      expect(result.amount?.minorUnits, 1250);
      expect(result.amount?.currency, 'USD');
      expect(result.description, 'Cafetería Central');
      expect(result.occurredAt, DateTime.parse('2026-07-01'));
      expect(result.categoryName, 'Comida');
      expect(result.isEmpty, isFalse);
    });

    test('accepts a numeric amount sent as a string', () async {
      final service = serviceReturning(
        _geminiEnvelope(jsonEncode({'amount': '9.99'})),
      );

      final result = await service.scan(
        bytes,
        currency: 'USD',
        categoryNames: const [],
      );

      expect(result.amount?.minorUnits, 999);
    });

    test('drops unusable fields and reports the result as empty', () async {
      final service = serviceReturning(
        _geminiEnvelope(
          jsonEncode({
            'amount': null,
            'description': 'null',
            'date': 'not-a-date',
            'category': '',
          }),
        ),
      );

      final result = await service.scan(
        bytes,
        currency: 'USD',
        categoryNames: const [],
      );

      expect(result.amount, isNull);
      expect(result.description, isNull);
      expect(result.occurredAt, isNull);
      expect(result.categoryName, isNull);
      expect(result.isEmpty, isTrue);
    });

    test('surfaces a rate-limit as a coded ReceiptScanException', () async {
      final service = serviceReturning('{}', status: 429);

      expect(
        () => service.scan(bytes, currency: 'USD', categoryNames: const []),
        throwsA(
          isA<ReceiptScanException>().having(
            (e) => e.code,
            'code',
            'rate_limited',
          ),
        ),
      );
    });

    test('surfaces other HTTP errors with the status in the code', () async {
      final service = serviceReturning('boom', status: 500);

      expect(
        () => service.scan(bytes, currency: 'USD', categoryNames: const []),
        throwsA(
          isA<ReceiptScanException>().having(
            (e) => e.code,
            'code',
            'http_500',
          ),
        ),
      );
    });
  });
}
