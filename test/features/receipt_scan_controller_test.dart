import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leakless/src/features/quick_entry/application/receipt_scan_providers.dart';
import 'package:leakless/src/features/quick_entry/data/receipt_scan_result.dart';
import 'package:leakless/src/features/quick_entry/data/receipt_scan_service.dart';

class _FakeReceiptScanService implements ReceiptScanService {
  _FakeReceiptScanService({this.result, this.error});

  final ReceiptScanResult? result;
  final Object? error;

  @override
  Future<ReceiptScanResult> scan(
    Uint8List imageBytes, {
    required String currency,
    required List<String> categoryNames,
    required String mimeType,
  }) async {
    if (error != null) throw error!;
    return result ?? const ReceiptScanResult();
  }
}

void main() {
  test('returns a successful scan and exposes it as data', () async {
    const expected = ReceiptScanResult(description: 'Mercado');
    final container = ProviderContainer(
      overrides: [
        receiptScanServiceProvider.overrideWithValue(
          _FakeReceiptScanService(result: expected),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(receiptScanControllerProvider.notifier)
        .scan(
          Uint8List.fromList([1, 2, 3]),
          currency: 'USD',
          categoryNames: const ['Food'],
          mimeType: 'image/jpeg',
        );

    expect(result, same(expected));
    expect(
      container.read(receiptScanControllerProvider).asData?.value,
      same(expected),
    );
  });

  test(
    'stores and rethrows scan failures so the UI can show feedback',
    () async {
      const failure = ReceiptScanException('offline', code: 'network');
      final container = ProviderContainer(
        overrides: [
          receiptScanServiceProvider.overrideWithValue(
            _FakeReceiptScanService(error: failure),
          ),
        ],
      );
      addTearDown(container.dispose);

      final future = container
          .read(receiptScanControllerProvider.notifier)
          .scan(
            Uint8List.fromList([1]),
            currency: 'USD',
            categoryNames: const [],
            mimeType: 'image/png',
          );

      await expectLater(future, throwsA(same(failure)));
      expect(container.read(receiptScanControllerProvider).hasError, isTrue);
    },
  );
}
