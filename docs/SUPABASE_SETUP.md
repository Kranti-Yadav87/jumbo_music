# Supabase Edge Function Proxy Setup Guide

This document explains the configuration and deployment of the Supabase Edge Function proxy used by Jumbo Music for catalog search and streaming queries without requiring Firebase Cloud Functions.

---

## Architecture Overview

Jumbo Music runs on the free Firebase Spark plan (which disallows Cloud Functions). To securely proxy external search requests and handle CORS on the Web platform, Jumbo Music utilizes a free-tier Supabase Edge Function (`/functions/v1/spotify`).

- **Base Endpoint**: `https://<project-ref>.supabase.co/functions/v1/spotify`
- **Authentication**: Public Anonymous JWT (`apikey` and `Authorization: Bearer <anon-key>`)
- **AppConfig Integration**: Configurable via compile-time `--dart-define` parameters.

---

## 1. Environment Configuration

The app uses default credentials compiled in `AppConfig`, but these can be overridden for custom deployments:

```bash
flutter run \
  --dart-define=SPOTIFY_ENDPOINT=https://<your-project>.supabase.co/functions/v1/spotify \
  --dart-define=SPOTIFY_ANON_KEY=<your-supabase-anon-key>
```

---

## 2. Deploying the Edge Function (Supabase CLI)

If deploying your own proxy function:

1. Install Supabase CLI:
   ```bash
   npm install -g supabase
   ```

2. Login and link your project:
   ```bash
   supabase login
   supabase link --project-ref <your-project-ref>
   ```

3. Deploy edge function:
   ```bash
   supabase functions deploy spotify --no-verify-jwt
   ```

---

## 3. Request & Response Payload Contract

### Query Search
- **Method**: `GET /functions/v1/spotify?q=<search_query>&type=track`
- **Headers**:
  - `apikey: <supabase-anon-key>`
  - `Authorization: Bearer <supabase-anon-key>`
  - `Content-Type: application/json`
- **Response**: Standardized JSON array containing song metadata (title, artist, album, duration, audio URL, artwork URL).

---

## 4. Troubleshooting

1. **HTTP 401 / 403**: Ensure the Supabase Anon Key is valid and passed in both `apikey` and `Authorization` headers.
2. **CORS Errors on Web**: Ensure your Edge Function returns the standard CORS headers (`Access-Control-Allow-Origin: *`, `Access-Control-Allow-Headers: *`).
3. **Offline / Fallback**: When the proxy is unreachable or `USE_UNOFFICIAL_CATALOG=false` is set, the app gracefully falls back to local cached library and Jamendo.
