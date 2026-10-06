// Edge function: lyrics proxy + shared cache in front of LRCLIB.
// GET /functions/v1/lyrics?title=...&artist=...&duration=SECONDS
// Response: { "lyrics": "<lrc or plain text>" | null, "cached": boolean }
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

// A confirmed "not found" is remembered for a day, then retried.
const MISS_TTL_MS = 24 * 60 * 60 * 1000;

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const title = (url.searchParams.get("title") ?? "").trim().slice(0, 200);
  const artist = (url.searchParams.get("artist") ?? "").trim().slice(0, 200);
  const duration = Number(url.searchParams.get("duration") ?? "0") || 0;
  if (!title) return json({ error: "title is required" }, 400);

  const key = `${title.toLowerCase()}|${artist.toLowerCase()}`;

  const { data: cached } = await supabase
    .from("lyrics_cache")
    .select("lyrics, found, updated_at")
    .eq("key", key)
    .maybeSingle();

  if (cached) {
    if (cached.found) return json({ lyrics: cached.lyrics, cached: true });
    const age = Date.now() - new Date(cached.updated_at).getTime();
    if (age < MISS_TTL_MS) return json({ lyrics: null, cached: true });
  }

  const params = new URLSearchParams({ track_name: title, artist_name: artist });
  if (duration > 0) params.set("duration", String(duration));

  let lyrics: string | null = null;
  try {
    const res = await fetch(`https://lrclib.net/api/get?${params}`, {
      headers: { "User-Agent": "JumboMusic/2.0 (student project)" },
      signal: AbortSignal.timeout(8000),
    });
    if (res.ok) {
      const data = await res.json();
      lyrics = String(data.syncedLyrics || data.plainLyrics || "").trim() ||
        null;
    } else if (res.status !== 404) {
      // LRCLIB problem (not a real "not found"): do not cache anything.
      return json({ lyrics: null, cached: false });
    }
  } catch (_) {
    return json({ lyrics: null, cached: false });
  }

  await supabase.from("lyrics_cache").upsert({
    key,
    lyrics,
    found: lyrics !== null,
    updated_at: new Date().toISOString(),
  });

  return json({ lyrics, cached: false });
});
