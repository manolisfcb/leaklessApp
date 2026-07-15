import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SERIES = "FXUSDCAD";
const VALET_URL =
  `https://www.bankofcanada.ca/valet/observations/${SERIES}/json?recent=10`;

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function secretKey(): string | null {
  const keys = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (keys) {
    try {
      return JSON.parse(keys).default ?? null;
    } catch {
      return null;
    }
  }
  return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? null;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const key = secretKey();
  if (!key) return json({ error: "server_not_configured" }, 500);
  if (req.headers.get("apikey") !== key) {
    return json({ error: "unauthorized" }, 401);
  }

  try {
    const response = await fetch(VALET_URL, {
      headers: { Accept: "application/json" },
      signal: AbortSignal.timeout(10_000),
    });
    if (!response.ok) {
      throw new Error(`bank_of_canada_http_${response.status}`);
    }

    const payload = await response.json();
    const observations = Array.isArray(payload?.observations)
      ? payload.observations
      : [];
    const latest = [...observations].reverse().find((observation) => {
      const value = Number(observation?.[SERIES]?.v);
      return /^\d{4}-\d{2}-\d{2}$/.test(observation?.d ?? "") &&
        Number.isFinite(value) && value > 0;
    });
    if (!latest) throw new Error("bank_of_canada_invalid_payload");

    const rateDate = latest.d as string;
    const rate = Number(latest[SERIES].v);
    const supabase = createClient(Deno.env.get("SUPABASE_URL") ?? "", key, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: newest, error: readError } = await supabase
      .from("exchange_rates")
      .select("raw_observation_date")
      .eq("foreign_currency", "USD")
      .eq("reporting_currency", "CAD")
      .eq("source", "bank_of_canada")
      .order("raw_observation_date", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (readError) throw readError;
    if (newest?.raw_observation_date && newest.raw_observation_date > rateDate) {
      throw new Error("bank_of_canada_observation_regressed");
    }

    const { error: writeError } = await supabase.from("exchange_rates").upsert({
      rate_date: rateDate,
      foreign_currency: "USD",
      reporting_currency: "CAD",
      rate,
      source: "bank_of_canada",
      retrieved_at: new Date().toISOString(),
      raw_observation_date: rateDate,
    }, { onConflict: "rate_date,foreign_currency,reporting_currency,source" });
    if (writeError) throw writeError;

    return json({ updated: true, rate_date: rateDate, rate });
  } catch (error) {
    console.error("exchange_rate_sync_failed", error);
    return json({ error: "exchange_rate_sync_failed" }, 502);
  }
});
