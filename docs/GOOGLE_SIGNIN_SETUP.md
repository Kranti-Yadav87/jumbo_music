# Google Sign-In Setup & Diagnosis Guide for Jumbo Music

This document explains the configuration requirements for Google Sign-In on Android, Web, and iOS in Jumbo Music (`com.jumbomusic.app`).

---

## 1. Firebase Authentication & Google Provider
1. Go to **Firebase Console** -> **Authentication** -> **Sign-in method**.
2. Make sure the **Google** provider is enabled.
3. Configure the support email.

---

## 2. SHA-1 and SHA-256 Fingerprints (Android)
For native Android Google Sign-In to exchange OAuth tokens with Firebase Auth, the Android package name and the signing certificate fingerprints must match the Firebase Android App registration:

- **Package Name**: `com.jumbomusic.app`
- **Debug SHA-1**: Must be registered under Firebase Project Settings -> Your Android App.
- **Release SHA-1**: Must be registered if publishing release builds signed with custom keystores or Google Play App Signing.

To obtain the debug signing SHA-1 fingerprint on your local machine:
```bash
cd android && ./gradlew signingReport
```
Or with `keytool`:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

---

## 3. Web Client ID / Server Client ID
When calling `GoogleSignIn.instance.initialize(serverClientId: AppConfig.googleServerClientId)`, `AppConfig.googleServerClientId` must be set to the **OAuth 2.0 Web Client ID** (client_type `3` in `google-services.json`).

- In `android/app/google-services.json`:
  - `client_type: 1`: Represents the Android OAuth client (with package name and certificate hash `9c1b06531b9e5cc08d67da94a54c1aa7f0cd0957`).
  - `client_type: 3`: Represents the Web Server OAuth client ID (`375294688779-on4vsckpke482km54jl3vsraj0s9ulkt.apps.googleusercontent.com`).

---

## 4. Authorized Domains (Web & Mobile OAuth Redirects)
In **Firebase Console** -> **Authentication** -> **Settings** -> **Authorized domains**, add:
- `localhost`
- `jumbo-music-ff58c.web.app`
- `jumbo-music-ff58c.firebaseapp.com`
- Any custom domains hosting the web application.

---

## 5. Common Diagnostic Scenarios
1. **Error: ApiException 10 / DEVELOPER_ERROR**:
   - The SHA-1 certificate hash of the currently running APK (debug or release) is missing from the Firebase Console Android app configuration, or the package name does not match `com.jumbomusic.app`.
2. **Error: ApiException 12500 / SIGN_IN_REQUIRED / null-id-token**:
   - The `serverClientId` is either missing, incorrect, or Google Sign-In is not enabled in Firebase Authentication.
3. **Error: unauthorized-domain**:
   - The domain where the web/PWA app is hosted is not listed under Firebase Authentication Authorized Domains.
