# Receipt OCR (escanear recibos con foto)

Quick Entry can prefill an expense from a **photo of a receipt**. The image is
read by Google's Gemini vision model and the amount, merchant, date and a
category suggestion are dropped into the form for the user to review before
saving.

> **Status: off by default.** Until the steps below are done, Quick Entry is
> **manual only** and the "Escanear recibo" button is hidden. Nothing about OCR
> ships in the app until you flip it on.

## Why it's server-side

The Gemini API key is a **secret**. If it shipped inside the app binary anyone
could extract it and spend against the account. So the app never holds the key:
it uploads the photo to our own **Supabase Edge Function** (`scan-receipt`),
which holds the key as a server secret, calls Gemini, and returns only the
extracted fields.

```
App (image) ──▶ Edge Function `scan-receipt` ──▶ Gemini
                     (holds GEMINI_API_KEY)
App ◀── { amount, description, date, category } ◀──
```

The client boundary is the `ReceiptScanService` interface
(`lib/src/features/quick_entry/data/receipt_scan_service.dart`); today it's
backed by `SupabaseReceiptScanService`. The OCR provider can change entirely on
the server without touching the app.

## Turning it on

1. **Get a Gemini key** at <https://aistudio.google.com/app/apikey>.

2. **Store it as a server secret** (never in `.env`, never in the app):

   ```bash
   supabase secrets set GEMINI_API_KEY=<your-google-ai-studio-key>
   ```

3. **Deploy the function:**

   ```bash
   supabase functions deploy scan-receipt
   ```

   Source: `supabase/functions/scan-receipt/index.ts`. It requires an
   authenticated caller (verifies the Supabase JWT) so anonymous users can't
   burn the OCR quota.

4. **Enable the client flag** in `.env`:

   ```env
   RECEIPT_SCAN_ENABLED=true
   ```

   The button appears only when this is `true` **and** Supabase is configured.

## Testing

- Client mapping (Edge Function payload → form fields):
  `test/features/receipt_scan_service_test.dart`.
- Function locally: `supabase functions serve scan-receipt` and POST
  `{ "image": "<base64>", "currency": "USD", "categories": ["Comida"] }` with a
  valid `Authorization: Bearer <user-jwt>` header.

## Cost / privacy notes

- Images are re-encoded and downscaled on-device (`maxWidth/Height: 1600`,
  `imageQuality: 80`) before upload to keep payloads small.
- The function does not persist the image; it forwards it to Gemini and returns
  the extracted fields. Add logging/retention deliberately if you need it.
