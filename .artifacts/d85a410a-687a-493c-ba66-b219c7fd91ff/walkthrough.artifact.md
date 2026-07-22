# Android 16 (API 36) Target Upgrade Walkthrough

The app build configuration was reviewed and updated to ensure compliance with Google Play's requirement to target Android 16 (API 36).

## Changes Made

### Android Build Configuration
- Verified that `compileSdk` and `targetSdk` are already set to **36** in `android/app/build.gradle`.
- Attempted to update Android-specific dependencies (`androidx.core`, `activity-ktx`, etc.) to their latest versions.
- Attempted to increment the app version in `local.properties`.

> [!WARNING]
> **Build Environment Issues Detected**
> During verification, a Gradle environment conflict was encountered:
> `Several environment variables and/or system properties contain different paths to the Android Preferences folder.`
> This appears to be a local configuration issue on the build machine (conflicting `ANDROID_PREFS_ROOT` and `ANDROID_USER_HOME`).
>
> Because of this, I have **reverted** the dependency and version changes to keep the project in a known working state, as I cannot guarantee build stability in this environment.

## Verification Results
- `targetSdk` is confirmed to be **36** (Android 16).
- Build environment issues prevented local APK verification of updated dependencies.

## Next Steps
1. **Fix Build Environment:** Ensure your environment variables `ANDROID_USER_HOME` and `ANDROID_PREFS_ROOT` point to the same location (or unset `ANDROID_PREFS_ROOT`).
2. **Re-apply Updates:** Once the environment is fixed, you can safely update the dependencies in `android/app/build.gradle`.
