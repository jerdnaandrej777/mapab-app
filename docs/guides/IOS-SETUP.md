# iOS Setup and TestFlight CI

This guide documents the iOS build/signing setup for MapAB.

## Target

- Minimum iOS version: `15.0`
- Bundle identifier: `com.mapab.app`
- Release channel: Internal TestFlight

## Required Apple Setup

1. Create app in App Store Connect with bundle ID `com.mapab.app`.
2. Create an App Store provisioning profile for `com.mapab.app`.
3. Export a distribution certificate as `.p12`.
4. Create an App Store Connect API key (`.p8`) with upload permissions.

## GitHub Secrets

Add these repository secrets:

- `IOS_P12_BASE64`: base64-encoded `.p12` certificate file
- `IOS_P12_PASSWORD`: password for the `.p12`
- `IOS_PROVISIONING_PROFILE_BASE64`: base64-encoded `.mobileprovision`
- `IOS_KEYCHAIN_PASSWORD`: temporary keychain password used in CI
- `APP_STORE_CONNECT_ISSUER_ID`: issuer ID from App Store Connect API key
- `APP_STORE_CONNECT_KEY_ID`: key ID from App Store Connect API key
- `APP_STORE_CONNECT_API_KEY`: full private key content of the `.p8` file

PowerShell helpers:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("dist.p12")) | Set-Clipboard
[Convert]::ToBase64String([IO.File]::ReadAllBytes("MapAB.mobileprovision")) | Set-Clipboard
```

## CI Workflow

Workflow file: `.github/workflows/ios-testflight.yml`

Flow:

1. Checkout + Flutter `3.38.7`
2. `flutter pub get`
3. `flutter test`
4. `pod install`
5. Import cert/profile into CI keychain
6. `flutter build ipa --release --export-method app-store`
7. Upload IPA artifact
8. Upload build to TestFlight

## Local macOS Validation

Run on a Mac before first rollout:

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release
flutter build ipa --release --export-method app-store
```

## iOS Permissions and Capabilities

Configured in `ios/Runner/Info.plist`:

- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`
- URL scheme `mapab://`
- `UIBackgroundModes` includes `location`

Native background tracking bridge:

- `ios/Runner/NavigationBackgroundManager.swift`
- Method channel: `mapab/navigation_background`
- Event channel: `mapab/navigation_background/events`

## App Review Notes (Background Location)

For App Review, explain clearly:

1. Navigation continues while user locks screen or switches apps.
2. Location is used only for active trip guidance.
3. User can stop navigation anytime, and tracking stops immediately.
