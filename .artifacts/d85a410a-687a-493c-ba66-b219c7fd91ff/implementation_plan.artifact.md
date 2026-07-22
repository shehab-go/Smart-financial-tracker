# Upgrade Target API to Android 16 (API 36)

The goal is to ensure the app complies with Google Play's requirement to target Android 16 (API level 36) or higher by August 31, 2026.

## Current Status
- `compileSdk` is already set to **36** in `android/app/build.gradle`.
- `targetSdk` is already set to **36** in `android/app/build.gradle`.
- Android core dependencies are outdated (e.g., `androidx.core:core-ktx:1.12.0`).

## Proposed Changes

### [Component Name] Android Build Configuration

#### [MODIFY] [app/build.gradle](file:///E:/hemmah/debit_credit_app/android/app/build.gradle)
- Update dependencies to more recent versions compatible with Android 16.
- (Optional) Increment `versionCode` and `versionName` if requested, though these are typically managed via `local.properties` or Flutter commands.

#### [MODIFY] [local.properties](file:///E:/hemmah/debit_credit_app/android/local.properties)
- Increment `flutter.versionCode` and `flutter.versionName` to prepare for a new release.

### [Component Name] Android Manifest

#### [MODIFY] [AndroidManifest.xml](file:///E:/hemmah/debit_credit_app/android/app/src/main/AndroidManifest.xml)
- Ensure `android:enableOnBackInvokedCallback="true"` is set (or explicitly handled) if there are any native custom back behaviors, although Flutter usually handles this.

## Verification Plan

### Automated Tests
- Run `flutter build apk` to ensure the project still compiles correctly with the new SDK and dependency versions.

### Manual Verification
- Verify that the app still runs on an Android 16 emulator (if available) or at least on a recent Android version.
- Check that basic functionality (database, UI, notifications) remains intact.
