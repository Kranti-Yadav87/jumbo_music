#!/usr/bin/env bash
set -e

echo "=== Setting up Flutter for Vercel Deployment ==="

# 1. Clone Flutter SDK if not already present
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK (stable channel)..."
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git flutter
else
  echo "Flutter directory already exists."
fi

# 2. Add Flutter to PATH
export PATH="$PATH:$PWD/flutter/bin"

echo "=== Flutter Version ==="
flutter --version

echo "=== Enabling Flutter Web ==="
flutter config --enable-web

echo "=== Installing Flutter Dependencies ==="
flutter pub get

echo "=== Building Flutter Web for Release ==="
flutter build web --release --base-href /

echo "=== Vercel Build Successfully Finished! ==="
