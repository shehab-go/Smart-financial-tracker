# Implementation Plan - Update Smart Financial Tracker Parser

This plan details the steps to update the "financial_tracker" module in the current project with the improved "smart" parsing logic from the specified GitHub repository.

## User Review Required

> [!IMPORTANT]
> The current project has several advanced features (coroutine-based `WalletConfigManager`, restart logic in `FinancialNotificationListener`, local notifications, and `markAsClassified` functionality) that are **NOT** present in the source repository.
>
> My plan is to **selectively update** only the core "smart" logic (like the named-group support in the parser) while **preserving** the existing advanced features of the current project to avoid regressions.

## Proposed Changes

### [Android Module: com.financial.tracker.module]

Updating the core parsing logic to match the "Smart-financial-tracker" repository.

#### [MODIFY] [DynamicParser.kt](file:///E:/hemmah/debit_credit_app/android/app/src/main/kotlin/com/financial/tracker/module/parser/DynamicParser.kt)
- Update `extractField` to support named groups (`(?<value>...)`), allowing more robust Regex definitions in the JSON config.

#### [MODIFY] [FinancialTrackerClient.kt](file:///E:/hemmah/debit_credit_app/android/app/src/main/kotlin/com/financial/tracker/module/FinancialTrackerClient.kt)
- Ensure the logic aligns with the repo's implementation while maintaining project-specific methods like `markAsClassified`.

#### [MODIFY] [FinancialNotificationListener.kt](file:///E:/hemmah/debit_credit_app/android/app/src/main/kotlin/com/financial/tracker/module/FinancialNotificationListener.kt)
- Review and apply any relevant "smart" improvements from the repo, while keeping the project's notification alerts and service restart logic.

### [Assets]

#### [MODIFY] [financial_tracker_config.json](file:///E:/hemmah/debit_credit_app/android/app/src/main/assets/financial_tracker_config.json)
- Merge any new bank rules or Regex improvements from the repository's `financial_tracker_config.json` and `wallet_config.json`.

## Verification Plan

### Manual Verification
1. **Verify Compilation:** Ensure the Android project still builds successfully after the updates.
2. **Regex Test:** Use the `testParser` method (invoked via a temporary test or log) to verify that Regex with named groups (`(?<value>...)`) now works as expected.
3. **Flutter Integration:** Ensure the Flutter app can still communicate with the native module via the existing MethodChannels.
