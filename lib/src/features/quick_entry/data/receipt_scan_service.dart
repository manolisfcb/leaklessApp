import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/models/money.dart';
import 'receipt_scan_result.dart';

/// Extracts spend data from a photo of a receipt.
///
/// The Quick Entry form owns the camera and the form fields; this service is the
/// single place that knows how to turn image bytes into a [ReceiptScanResult]
/// (quality rule #4/#7). The OCR provider (Gemini today) lives entirely on the
/// server, so it can change without touching the app.
abstract interface class ReceiptScanService {
  /// Reads [imageBytes] and returns whatever spend fields the model could find.
  ///
  /// [currency] is the household currency the amount is interpreted in.
  /// [categoryNames] is the closed list the model is asked to pick a category
  /// from, so its suggestion maps cleanly onto the household's own categories.
  Future<ReceiptScanResult> scan(
    Uint8List imageBytes, {
    required String currency,
    required List<String> categoryNames,
  });
}

/// Thrown when a receipt scan can't be completed (network, quota, bad response).
///
/// Kept standalone (not an `AppException`, which is a sealed data-layer type) so
/// the Quick Entry UI can map [code] straight to a friendly, actionable message.
class ReceiptScanException implements Exception {
  const ReceiptScanException(this.message, {this.code, this.cause, this.stackTrace});

  final String message;
  final String? code;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'ReceiptScanException($code): $message';
}

/// Runs OCR through the `scan-receipt` Supabase Edge Function.
///
/// The Gemini API key is a **server-side secret** held by the Edge Function
/// (`supabase secrets set GEMINI_API_KEY=…`) and never ships in the app — see
/// `docs/RECEIPT_OCR.md`. The client only forwards the image plus context and
/// maps the normalized JSON the function returns.
class SupabaseReceiptScanService implements ReceiptScanService {
  const SupabaseReceiptScanService(this._client, {this.functionName = 'scan-receipt'});

  final SupabaseClient _client;
  final String functionName;

  @override
  Future<ReceiptScanResult> scan(
    Uint8List imageBytes, {
    required String currency,
    required List<String> categoryNames,
  }) async {
    FunctionResponse res;
    try {
      res = await _client.functions.invoke(
        functionName,
        body: {
          'image': base64Encode(imageBytes),
          'mimeType': 'image/jpeg',
          'currency': currency,
          'categories': categoryNames,
        },
      );
    } on FunctionException catch (e, s) {
      throw ReceiptScanException(
        _messageForStatus(e.status),
        code: _codeForStatus(e.status),
        cause: e,
        stackTrace: s,
      );
    } catch (e, s) {
      throw ReceiptScanException(
        'No pudimos conectar con el servicio de lectura.',
        code: 'network',
        cause: e,
        stackTrace: s,
      );
    }

    final data = res.data;
    if (data is! Map) {
      throw const ReceiptScanException(
        'No pudimos leer la respuesta del servicio.',
        code: 'parse',
      );
    }
    return mapExtracted(Map<String, dynamic>.from(data), currency: currency);
  }

  static String _codeForStatus(int status) => switch (status) {
    401 || 403 => 'unauthorized',
    429 => 'rate_limited',
    _ => 'http_$status',
  };

  static String _messageForStatus(int status) => switch (status) {
    401 || 403 => 'Inicia sesión para escanear recibos.',
    429 => 'Servicio de lectura ocupado. Inténtalo en un momento.',
    _ => 'El servicio de lectura devolvió un error.',
  };

  /// Maps the Edge Function's normalized `{amount, description, date, category}`
  /// payload into a [ReceiptScanResult]. Tolerant by design: any missing or
  /// garbled field is dropped rather than failing the whole scan. Exposed for
  /// unit tests.
  static ReceiptScanResult mapExtracted(
    Map<String, dynamic> extracted, {
    required String currency,
  }) {
    final amountRaw = extracted['amount'];
    final amount = switch (amountRaw) {
      final num n when n > 0 => Money.fromMajor(n, currency: currency),
      final String s when double.tryParse(s) != null && double.parse(s) > 0 =>
        Money.fromMajor(double.parse(s), currency: currency),
      _ => null,
    };

    return ReceiptScanResult(
      amount: amount,
      description: _cleanString(extracted['description']),
      occurredAt: _parseDate(extracted['date']),
      categoryName: _cleanString(extracted['category']),
    );
  }

  static String? _cleanString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty || trimmed.toLowerCase() == 'null' ? null : trimmed;
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value.trim());
  }
}
