#!/usr/bin/env bash
# ==============================================================================
# Jumbo Music - Vercel build script
# Fails LOUDLY: if the Flutter build breaks, the deployment fails (no fake page).
# Optional env vars (set in Vercel project settings):
#   FLUTTER_VERSION   e.g. 3.35.0 (default: latest stable)
#   SPOTIFY_ENDPOINT / SPOTIFY_ANON_KEY   override the API defaults at build time
# ==============================================================================
set -euo pipefail

export FLUTTER_SUPPRESS_ANALYTICS="true"
export PUB_CACHE="${PWD}/.pub-cache"
export PATH="${PWD}/flutter/bin:${PATH}"

# Ensure git safe directory on CI/Vercel containers
git config --global --add safe.directory "*" 2>/dev/null || true

echo "=== [1/4] Flutter SDK ==="
if [ -x "flutter/bin/flutter" ] && flutter --version >/dev/null 2>&1; then
  echo "Using cached Flutter SDK."
else
  rm -rf flutter
  BRANCH_ARGS=(-b stable)
  if [ -n "${FLUTTER_VERSION:-}" ]; then
    BRANCH_ARGS=(-b "${FLUTTER_VERSION}")
  fi
  for attempt in 1 2 3; do
    echo "Cloning Flutter SDK (attempt ${attempt}/3)..."
    if git clone --depth 1 "${BRANCH_ARGS[@]}" https://github.com/flutter/flutter.git flutter; then
      break
    fi
    rm -rf flutter
    if [ "$attempt" -eq 3 ]; then
      echo "ERROR: could not download the Flutter SDK." >&2
      exit 1
    fi
    sleep 5
  done
fi

echo "=== [2/4] Dependencies & Web Engine ==="
flutter config --no-analytics >/dev/null 2>&1 || true
flutter config --enable-web >/dev/null 2>&1 || true
flutter precache --web
flutter pub get

echo "=== [3/4] Build web (release) ==="
DEFINES=()
if [ -n "${SPOTIFY_ENDPOINT:-}" ]; then DEFINES+=("--dart-define=SPOTIFY_ENDPOINT=${SPOTIFY_ENDPOINT}"); fi
if [ -n "${SPOTIFY_ANON_KEY:-}" ]; then DEFINES+=("--dart-define=SPOTIFY_ANON_KEY=${SPOTIFY_ANON_KEY}"); fi
if [ -n "${JAMENDO_CLIENT_ID:-}" ]; then DEFINES+=("--dart-define=JAMENDO_CLIENT_ID=${JAMENDO_CLIENT_ID}"); fi
flutter build web --release --base-href / "${DEFINES[@]}"

echo "=== [4/4] Verify output ==="
if [ ! -s "build/web/index.html" ]; then
  echo "ERROR: build/web is incomplete (index.html missing)." >&2
  exit 1
fi
echo "Build OK."
