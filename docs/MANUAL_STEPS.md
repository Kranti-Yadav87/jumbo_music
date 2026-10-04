# Jumbo Music — Manual steps (Hinglish, step-by-step)

> Mujhe (Claude) yahan Flutter SDK aur internet nahi mila, isliye code **compile/test nahi kiya gaya**.
> Isliye STEP 0 sabse pehle karo.

## STEP 0 — Zip ko apne project mein lao aur check karo
1. Git branch banao: `git checkout -b upgrade-v2`
2. Zip ke andar ka content apne `jumbo_music` folder mein copy-paste karke overwrite karo.
3. Terminal mein, project folder ke andar:
   ```bash
   flutter pub get
   dart format lib test
   flutter analyze --no-fatal-infos
   flutter test
   ```
4. Agar koi error aaye → poora error text copy karke mujhe (ya Antigravity ko) bhej do. Pass hone par hi merge karo.

## STEP 1 — Firestore rules deploy karo (crash reports ke liye zaroori)
Option A (CLI): `firebase login` → `firebase use jumbo-music-ff58c` → `firebase deploy --only firestore:rules`
Option B (console): Firebase Console → Build → Firestore Database → **Rules** tab → `firestore.rules` ka poora content paste → **Publish**.
Bina iske crash reports silently reject honge (app crash nahi hoga).

## STEP 2 — Crash reporting test karo
1. Kisi screen ke `initState` mein temporarily ye line daalo:
   `CrashReportingService.recordError(Exception('manual test'), StackTrace.current, reason: 'manual test');`
2. Chalao: `flutter run -d chrome --dart-define=REPORT_ERRORS=true`
3. Firebase Console → Firestore Database → collection **client_errors** → naya document dikhna chahiye.
4. Test line hata do.

## STEP 3 — Firestore abuse/bill se bachao
`client_errors` bina login ke write ho sakta hai (guest users ke liye). Isliye:
1. Google Cloud Console → Billing → **Budgets & alerts** → budget (jaise ₹500) + email alert banao.
2. (Recommended) Firebase Console → Build → **App Check** → web app ke liye reCAPTCHA v3, Android ke liye Play Integrity register karo. Pehle "Monitor" mode mein rakho, enforce baad mein.

## STEP 4 — Jamendo (legal, poore gaane) chalu karo
1. https://devportal.jamendo.com par account banao → New application → **client_id** copy karo.
2. Local test: `flutter run -d chrome --dart-define=JAMENDO_CLIENT_ID=<id>`
3. GitHub repo → Settings → Secrets and variables → Actions → **New repository secret** → name `JAMENDO_CLIENT_ID`.
4. Vercel → Project → Settings → Environment Variables → `JAMENDO_CLIENT_ID` add → Redeploy.
5. Dhyan do: Jamendo free API **sirf non-commercial** ke liye hai, aur catalog indie/CC music hai (Bollywood nahi).

## STEP 5 — Android release signing (Play Store ke liye)
1. `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. `base64 -w0 upload-keystore.jks` (Mac: `base64 -i upload-keystore.jks`) ka output copy karo.
3. GitHub secrets banao: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
4. **.jks file kabhi git mein commit mat karo, aur backup safe rakho** — kho gayi to Play Store update band.

## STEP 6 — Jo main blind (bina compiler ke) nahi kar paya
Ye Antigravity (jisme compiler/emulator chalta hai) se karwao. Ready prompts: `docs/PRODUCT_ROADMAP.md`.
