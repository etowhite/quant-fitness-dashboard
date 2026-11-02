# quant 1.4.7 — onboarding, live search, hydration

## Changes

- Onboarding step 2 uses three local ValueNotifiers. Only the edited row rebuilds.
  Next/forward swipe/completion commits one draft; changing numbers or presets
  does not write global goals or SharedPreferences. Imported goals take precedence.
- Local and online results share one local-first list. Online search starts from
  two characters after 300 ms. Disposing the query cancels its timer and closes
  the request-specific HttpClient; barcode lookups use a separate client.
  Relevant results stay visible during refresh; loading does not block local taps.
  The progress ticker is removed when idle.
- Russian Open Food Facts search is attempted first, with world fallback. Cache,
  a rolling 10-request/minute budget shared across both hosts, and HTTP 429 cooldown
  respect the [upstream search limit](https://openfoodfacts.github.io/openfoodfacts-server/api/).
  No six-second delay is imposed between allowed requests. Queries/barcodes remain
  the only information sent to Open Food Facts.
- FoodProduct and FoodLogEntry have waterPercentage (finite, 0–100). The seed
  catalogue contains explicit percentages. OFF category tags, names and serving
  units inform estimates; dry/solid lookalikes are excluded. Percentages are editable.
- Hydration is derived from immutable diary snapshots plus manual WaterLogEntry
  rows, without duplicate water records. Removing/restoring food subtracts/restores
  its contribution. Undo in the water card still affects only manual portions.
  Reports and Android widget snapshots use the same calculation. Water remains
  only in Nutrition inside the application.
- Isar migrates previously absent double columns (NaN) without deleting data:
  products gain estimates, historical diary entries retain zero contribution.
  Explicit existing percentages remain unchanged. Backup v8 roundtrips snapshots;
  v1–v7 imports without the field retain zero.

## Verification

- Flutter 3.35.7 / Dart 3.9.2, Java 17, Android SDK 35.
- flutter pub get: passed.
- dart run build_runner build --delete-conflicting-outputs: passed; full FoodProduct
  and FoodLogEntry generated schemas include waterPercentage.
- flutter analyze: No issues found.
- flutter test --reporter=expanded: 103 tests passed. Includes native Isar
  persistence/reopen, missing-column-value migration, watcher updates, diary delete/
  restore, shared widget snapshot, hydration controls and reports, backup v8/legacy,
  300 ms debounce, production-client cancellation, RU/world fallback, and cached
  search budgets. Layout checks cover light/dark, narrow/normal screens, enlarged
  text, and forms with keyboard insets.
- Live HTTPS availability check: ru.openfoodfacts.org returned 503; the same search
  against world.openfoodfacts.org returned 200 with products. App fallback behavior
  and parsing are separately covered by automated tests.
- adb devices: no connected devices. No physical Android runtime check was performed.

- flutter build apk --release: passed.
- tool/check_apk.mjs: passed (quant label, minSdk 26 / targetSdk 35, backup and cleartext disabled).
- tool/check_signing.mjs: passed; persistent quant certificate unchanged.
- Root quant-release.apk is byte-identical to build/app/outputs/flutter-apk/app-release.apk.
- APK bytes: 79053436
- APK SHA-256: af7f1e053bfc8c7cbfba32f64983f247f80388b96d0d791d09f8da7908b7cb9d
- Version: 1.4.7+12.
- git diff --check: passed (only Windows line-ending notices).
