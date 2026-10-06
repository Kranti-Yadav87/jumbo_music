# Jumbo Music — Manual Deployment & Operations Guide

This guide covers operational setup, security rules deployment, and configuration steps for developers and maintainers.

---

## 1. Quality Gate & Local Verification

Before committing or pushing changes:
```bash
flutter pub get
dart format lib test --set-exit-if-changed
flutter analyze --no-fatal-infos
flutter test
```

---

## 2. Deploy Firestore Security Rules

Cloud Firestore security rules protect user privacy (`users/{uid}`), manage real-time presence (`presence/{uid}`), collaborative playlists (`shared_playlists`), and write-only rate-limited error reports (`client_errors`).

### Via Firebase CLI
```bash
firebase login
firebase use jumbo-music-ff58c
firebase deploy --only firestore:rules
```

### Via Firebase Console
1. Navigate to **Firebase Console** -> **Firestore Database** -> **Rules**.
2. Paste the contents of `firestore.rules`.
3. Click **Publish**.

---

## 3. Remote Crash Reporting & Observability

Jumbo Music includes a lightweight error logging service for production:
- In release builds, compact, rate-limited error payloads are stored in the write-only `client_errors` collection.
- Test error logging locally:
  ```bash
  flutter run -d chrome --dart-define=REPORT_ERRORS=true
  ```
- To monitor budgets on Google Cloud:
  1. Open **Google Cloud Console** -> **Billing** -> **Budgets & alerts**.
  2. Set a monthly budget alert (e.g., \$5 / ₹500).

---

## 4. Jamendo Legal Catalog Integration (Optional)

To enable legal, full-length Creative Commons music streaming:
1. Register at [Jamendo Developer Portal](https://devportal.jamendo.com) and create an application to obtain a `client_id`.
2. Run with Jamendo enabled:
   ```bash
   flutter run -d chrome --dart-define=JAMENDO_CLIENT_ID=<your-jamendo-client-id>
   ```
3. For CI/CD builds, configure GitHub Repository Secret: `JAMENDO_CLIENT_ID`.

---

## 5. Android Release Keystore & App Signing

For Google Play Store or self-hosted release APK signing:
1. Generate an upload keystore:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Base64-encode the keystore for GitHub Actions:
   - macOS: `base64 -i upload-keystore.jks`
   - Linux: `base64 -w0 upload-keystore.jks`
3. Configure repository secrets in GitHub (`Settings` -> `Secrets and variables` -> `Actions`):
   - `ANDROID_KEYSTORE_BASE64`
   - `ANDROID_KEYSTORE_PASSWORD`
   - `ANDROID_KEY_ALIAS`
   - `ANDROID_KEY_PASSWORD`
