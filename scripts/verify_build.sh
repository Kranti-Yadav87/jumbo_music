#!/usr/bin/env bash
# ==============================================================================
# Pre-Push & Local Verification Script for Jumbo Music
# Verifies that Dart code has zero compilation errors before pushing to GitHub
# ==============================================================================

set -e

# Find Flutter binary
FLUTTER_BIN=""
if command -v flutter >/dev/null 2>&1; then
  FLUTTER_BIN="flutter"
elif [ -f "$HOME/development/flutter/bin/flutter" ]; then
  FLUTTER_BIN="$HOME/development/flutter/bin/flutter"
elif [ -f "$PWD/flutter/bin/flutter" ]; then
  FLUTTER_BIN="$PWD/flutter/bin/flutter"
fi

if [ -z "$FLUTTER_BIN" ]; then
  echo "⚠️ Flutter binary not found locally. Skipping local static analysis."
  exit 0
fi

echo "🔍 Running Flutter static analysis to protect deployment..."
if "$FLUTTER_BIN" analyze --no-fatal-infos --no-fatal-warnings; then
  echo "✅ All checks passed! Safe to deploy."
  exit 0
else
  echo ""
  echo "❌ DEPLOYMENT GUARD PREVENTED PUSH: Compilation or syntax errors detected!"
  echo "Please fix the errors above so Vercel deployment does not fail."
  exit 1
fi
