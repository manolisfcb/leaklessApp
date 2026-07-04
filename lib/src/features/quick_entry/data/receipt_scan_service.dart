import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../../../domain/models/money.dart';
import 'receipt_scan_result.dart';

/// Extracts spend data from a photo of a receipt.
///
/// The Quick Entry form owns the camera and the form fields; this service is the
/// single place that knows how to turn image bytes into a [ReceiptScanResult]
/// (quality rule #4/#7), so the OCR backend can be swapped — e.g. moved behind a
/// Supabase Edge Function — without touching the UI.
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

/// Calls Google's Gemini (Generative Language API) vision model over REST.
///
/// This talks to the API directly with a client-side key — the "por ahora"
/// path. The key ships in the app bundle, so before production this should move
/// behind a server proxy (see the note in `.env.example`). Everything above the
/// [ReceiptScanService] interface stays unchanged when that happens.
class GeminiReceiptScanService implements ReceiptScanService {
  GeminiReceiptScanService({required String apiKey, http.Client? client})
    : _apiKey = apiKey,
      _client = client ?? http.Client();

  final String _apiKey;
  final http.Client _client;

  static final _log = Logger('GeminiReceiptScanService');

  /// A fast, cheap multimodal model. `-latest` tracks Google's current flash
  /// release so we don't pin to a version that gets retired.
  static const _model = 'gemini-flash-latest';
  static const _host = 'generativelanguage.googleapis.com';

  @override
  Future<ReceiptScanResult> scan(
    Uint8List imageBytes, {
    required String currency,
    required List<String> categoryNames,
  }) async {
    final uri = Uri.https(_host, '/v1beta/models/$_model:generateContent');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': _prompt(currency: currency, categoryNames: categoryNames)},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Encode(imageBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0,
        'responseMimeType': 'application/json',
      },
    });

    http.Response res;
    try {
      res = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));
    } catch (e, s) {
      throw ReceiptScanException(
        'No pudimos conectar con el servicio de lectura.',
        code: 'network',
        cause: e,
        stackTrace: s,
      );
    }

    if (res.statusCode == 429) {
      throw const ReceiptScanException(
        'Servicio de lectura ocupado. Inténtalo en un momento.',
        code: 'rate_limited',
      );
    }
    if (res.statusCode != 200) {
      _log.warning('Gemini scan failed: ${res.statusCode} ${res.body}');
      throw ReceiptScanException(
        'El servicio de lectura devolvió un error.',
        code: 'http_${res.statusCode}',
      );
    }

    return _parse(res.body, currency: currency);
  }

  /// Pulls the model's JSON answer out of the Gemini envelope and maps it to a
  /// [ReceiptScanResult]. Tolerant by design: any missing/garbled field is
  /// dropped rather than failing the whole scan.
  ReceiptScanResult _parse(String responseBody, {required String currency}) {
    Map<String, dynamic> extracted;
    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List<dynamic>?;
      final parts = ((candidates?.first as Map<String, dynamic>?)?['content']
              as Map<String, dynamic>?)?['parts']
          as List<dynamic>?;
      final text = (parts?.first as Map<String, dynamic>?)?['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        return const ReceiptScanResult();
      }
      extracted = jsonDecode(text) as Map<String, dynamic>;
    } catch (e, s) {
      throw ReceiptScanException(
        'No pudimos leer la respuesta del servicio.',
        code: 'parse',
        cause: e,
        stackTrace: s,
      );
    }

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

  String _prompt({
    required String currency,
    required List<String> categoryNames,
  }) {
    final categories = categoryNames.isEmpty
        ? 'null'
        : categoryNames.map((c) => '"$c"').join(', ');
    return '''
You are a receipt-parsing assistant for a personal finance app. Read the
attached photo of a purchase receipt and return ONLY a JSON object with these
keys:

- "amount": the grand total actually paid, as a number in major units of the
  currency $currency (e.g. 12.50). Use the final total, not subtotals or tax
  lines. Null if you cannot read it.
- "description": a short label, ideally the merchant/store name (max 60 chars).
  Null if unknown.
- "date": the purchase date as "YYYY-MM-DD". Null if not shown.
- "category": the single best fit from this list: [$categories]. Use exactly one
  of those strings, or null if none clearly fits.

Return null for any field you are unsure about. Do not invent values. Respond
with the JSON object only, no prose, no markdown fences.''';
  }

  String? _cleanString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty || trimmed.toLowerCase() == 'null' ? null : trimmed;
  }

  DateTime? _parseDate(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value.trim());
  }
}
