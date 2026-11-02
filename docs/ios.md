# quant on iPhone
Bundle ID: com.quant.fitness. iOS deployment target: 14.0.
GitHub builds two ad-hoc IPA packages for re-signing:
- quant-ios-sideload.ipa: no HealthKit entitlement, local fallback.
- quant-ios-full-healthkit.ipa: HealthKit entitlement, read-only access.

Neither package has an Apple-issued signing identity. Re-sign sideload using
Sideloadly / AltStore / SideStore. Installation depends on provisioning limits
and device compatibility. Full HealthKit requires a matching provisioning profile.
TrollStore support depends on the device. No signing secrets are committed.

On a Mac: flutter pub get, build_runner, flutter build ios --release --no-codesign.
Full mode: copy Runner.healthkit.entitlements to Runner.entitlements and add
--dart-define=QUANT_HEALTHKIT=true. Restore the empty entitlement file afterward.

The default binary never calls HealthKit. Full mode checks the actual signed
entitlement first; unavailable introspection fails closed. Dart catches plugin
errors but cannot catch Objective-C NSException. iOS does not reveal read denial;
empty reads fall back to local measurements.
Weight/body-fat live in BodyMeasurement and backup v9. Manual daily steps/calories
are local SharedPreferences overrides; empty fields restore automatic readings.
Factory reset clears these overrides. They are not yet in JSON backup.
Fallback does not query the motion sensor; activity is entered manually.
Local iOS notifications are supported; exact-alarm settings are Android-only.
Android widgets are not ported to WidgetKit.
Windows cannot run Xcode/CocoaPods/iOS Simulator. macOS CI checks compilation;
installation, Face ID, Health authorization and delivery need iPhone testing.

Scanner 7.0.1 replaces 6.0.11 because the latter requires iOS 15.5. The Apple Vision backend permits the iOS 14 deployment target.

HealthKit body fat is normalized from a fraction to 0–100 percent (HKUnit.percent).

PNG reports use the native Files export picker and iOS share sheet. No Photos permission is requested.
