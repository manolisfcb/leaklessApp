import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/receipt_scan_result.dart';
import '../data/receipt_scan_service.dart';

/// The receipt OCR service, or `null` when Supabase isn't configured.
///
/// Scanning runs through the `scan-receipt` Supabase Edge Function (which holds
/// the Gemini key server-side). It is available to every authenticated user;
/// there is deliberately no entitlement or premium gate.
final receiptScanServiceProvider = Provider<ReceiptScanService?>((ref) {
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
    required String mimeType,
  }) async {
    final service = ref.read(receiptScanServiceProvider);
    if (service == null) return null;

    state = const AsyncLoading();
    try {
      final result = await service.scan(
        imageBytes,
        currency: currency,
        categoryNames: categoryNames,
        mimeType: mimeType,
      );
      state = AsyncData(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// Clears any lingering error/result once the sheet has consumed it.
  void reset() => state = const AsyncData(null);
}

final receiptScanControllerProvider =
    NotifierProvider<ReceiptScanController, AsyncValue<ReceiptScanResult?>>(
      ReceiptScanController.new,
    );
