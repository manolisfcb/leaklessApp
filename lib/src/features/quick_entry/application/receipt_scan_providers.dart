import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/config_providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../data/receipt_scan_result.dart';
import '../data/receipt_scan_service.dart';

/// The receipt OCR service, or `null` when scanning isn't available yet.
///
/// Scanning runs through the `scan-receipt` Supabase Edge Function (which holds
/// the Gemini key server-side), so it needs both Supabase configured and the
/// `RECEIPT_SCAN_ENABLED` flag on. Until the function is deployed and the flag
/// flipped, this stays `null` and Quick Entry is manual-only — the UI keys the
/// "Escanear recibo" button off this being non-null.
final receiptScanServiceProvider = Provider<ReceiptScanService?>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.receiptScanEnabled) return null;
  if (!ref.watch(supabaseEnabledProvider)) return null;
  return SupabaseReceiptScanService(ref.watch(supabaseClientProvider));
});

/// Whether receipt scanning is available in this build.
final receiptScanEnabledProvider = Provider<bool>(
  (ref) => ref.watch(receiptScanServiceProvider) != null,
);

/// Drives a single receipt scan: holds the loading/error state the sheet shows
/// and returns the extracted fields for the form to prefill.
///
/// Orchestration lives here (quality rule #4/#6); the sheet only supplies the
/// captured bytes and consumes the result.
class ReceiptScanController extends Notifier<AsyncValue<ReceiptScanResult?>> {
  @override
  AsyncValue<ReceiptScanResult?> build() => const AsyncData(null);

  /// Scans [imageBytes]. Returns the result on success (possibly empty) or
  /// `null` if it failed — the error is also surfaced through [state].
  Future<ReceiptScanResult?> scan(
    Uint8List imageBytes, {
    required String currency,
    required List<String> categoryNames,
  }) async {
    final service = ref.read(receiptScanServiceProvider);
    if (service == null) return null;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => service.scan(
        imageBytes,
        currency: currency,
        categoryNames: categoryNames,
      ),
    );
    state = result;
    return result.asData?.value;
  }

  /// Clears any lingering error/result once the sheet has consumed it.
  void reset() => state = const AsyncData(null);
}

final receiptScanControllerProvider =
    NotifierProvider<ReceiptScanController, AsyncValue<ReceiptScanResult?>>(
      ReceiptScanController.new,
    );
