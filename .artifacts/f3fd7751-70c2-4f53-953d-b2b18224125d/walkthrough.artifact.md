# Project Setup and Verification Walkthrough

I have successfully added a sample application module to test your financial tracking library and verified the core logic.

## Changes Made

### 1. Sample App Module (`:app`)
- Created a new Android application module that depends on the `:financial_tracker` library.
- **MainActivity**: Implemented a simple UI that collects and displays financial transactions in real-time using `FinancialTrackerClient.transactionFlow`.
- **Permissions**: The app is ready for "Notification Access" testing.

### 2. Library Fixes (`:financial_tracker`)
- **Compatibility**: Fixed `DynamicParser.kt` to handle cases where named regex groups are not supported (pre-Android Oreo or Desktop JVM).
- **Unit Testing**: Added `testOptions` to the library's build configuration to allow mocking of Android classes (like `Log`) in unit tests.
- **SDK Update**: Switched to SDK 35 for better compatibility with local development environments.

### 3. Verification
- **Build**: Successfully built the sample app using `:app:assembleDebug`.
- **Unit Test**: Created and passed a unit test for `DynamicParser` that verifies parsing of STC Pay notifications.

## How to Test
1. **Deploy the App**: Install the `:app` module on your device.
2. **Grant Access**: Go to **Settings > Apps > Special app access > Notification access** and enable "Financial Transaction Analyzer" (the name of the listener service).
3. **Simulate Notification**: Send a test notification that matches the patterns in your bank rules. The transactions should appear instantly on the screen.

```kotlin
// Example transaction flow in MainActivity.kt
lifecycleScope.launch {
    FinancialTrackerClient.transactionFlow.collect { transaction ->
        // Updates UI with new transaction data
    }
}
```
