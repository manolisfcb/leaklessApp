// Supabase Edge Function: scan-receipt
//
// Turns a photo of a receipt into structured spend data using Google's Gemini
// vision model. The Gemini API key lives ONLY here, as a server-side secret
// (`supabase secrets set GEMINI_API_KEY=…`) — it never ships in the app.
//
// Request  (JSON): { image: base64, mimeType?: string, currency: string,
//                    categories: string[] }
// Response (JSON): { amount: number|null, description: string|null,
//                    date: "YYYY-MM-DD"|null, category: string|null }
//
// Deploy:  supabase functions deploy scan-receipt
// Secret:  supabase secrets set GEMINI_API_KEY=<google-ai-studio-key>

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GEMINI_MODEL = "gemini-flash-latest";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function prompt(currency: string, categories: string[]): string {
  const list = categories.length
    ? categories.map((c) => `"${c}"`).join(", ")
    : "null";
  return `You are a receipt-parsing assistant for a personal finance app. Read
the attached photo of a purchase receipt and return ONLY a JSON object with
these keys:

- "amount": the grand total actually paid, as a number in major units of the
  currency ${currency} (e.g. 12.50). Use the final total, not subtotals or tax
  lines. Null if you cannot read it.
- "description": a short label, ideally the merchant/store name (max 60 chars).
  Null if unknown.
- "date": the purchase date as "YYYY-MM-DD". Null if not shown.
- "category": the single best fit from this list: [${list}]. Use exactly one of
  those strings, or null if none clearly fits.

Return null for any field you are unsure about. Do not invent values.`;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  // Require an authenticated caller — no anonymous OCR quota burning.
  const authHeader = req.headers.get("Authorization") ?? "";
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData?.user) {
    return json({ error: "unauthorized" }, 401);
  }

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    return json({ error: "server_not_configured" }, 500);
  }

  let payload: {
    image?: string;
    mimeType?: string;
    currency?: string;
    categories?: string[];
  };
  try {
    payload = await req.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  const image = payload.image;
  if (!image || typeof image !== "string") {
    return json({ error: "missing_image" }, 400);
  }
  const currency = payload.currency ?? "USD";
  const categories = Array.isArray(payload.categories) ? payload.categories : [];
  const mimeType = payload.mimeType ?? "image/jpeg";

  const geminiUrl =
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

  let geminiRes: Response;
  try {
    geminiRes = await fetch(geminiUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": apiKey,
      },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              { text: prompt(currency, categories) },
              { inline_data: { mime_type: mimeType, data: image } },
            ],
          },
        ],
        generationConfig: {
          temperature: 0,
          responseMimeType: "application/json",
        },
      }),
    });
  } catch (_e) {
    return json({ error: "upstream_unreachable" }, 502);
  }

  if (geminiRes.status === 429) {
    return json({ error: "rate_limited" }, 429);
  }
  if (!geminiRes.ok) {
    return json({ error: "upstream_error" }, 502);
  }

  // Unwrap the Gemini envelope and re-parse the model's JSON answer, so the
  // client always receives the same flat, normalized shape.
  try {
    const body = await geminiRes.json();
    const text: string | undefined =
      body?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) return json({ amount: null });
    const extracted = JSON.parse(text);
    return json({
      amount: extracted.amount ?? null,
      description: extracted.description ?? null,
      date: extracted.date ?? null,
      category: extracted.category ?? null,
    });
  } catch (_e) {
    return json({ error: "parse_error" }, 502);
  }
});
