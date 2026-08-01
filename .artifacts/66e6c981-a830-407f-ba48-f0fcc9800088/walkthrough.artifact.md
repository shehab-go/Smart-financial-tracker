# Walkthrough - Smart Financial Parser Update

The financial tracker module has been updated with "smart" parsing logic and improved configuration capabilities from the [Smart-financial-tracker](https://github.com/shehab-go/Smart-financial-tracker) repository.

## Changes

### Native Parser Improvements
- **Named Group Support**: The `DynamicParser.kt` now supports named capture groups in Regex (e.g., `(?<value>...)`). This allows for more flexible and accurate extraction of transaction details from various bank notification formats.
- **Dynamic Wallet Names**: The configuration now includes a `walletName` field. The `FinancialNotificationListener.kt` uses this to display the correct wallet name (e.g., "STC Pay" or "جيب") in local alerts, rather than relying on hardcoded package name checks.

### Configuration Updates
- **STC Pay Integration**: Added comprehensive rules for STC Pay notifications (Incoming/Outgoing).
- **Improved Metadata**: Added friendly names for existing bank configurations in `financial_tracker_config.json`.

### UI Integration (Flutter & MethodChannel)
- **Retroactive Processing**: The `reprocessUnparsedLogs` functionality is now exposed to Flutter. This allows the app to re-scan notifications that previously failed to parse whenever new rules are applied or the configuration is updated.

## Verification Results

### Automated Analysis
- Ran `analyze_file` on all modified Kotlin files. No syntax errors or semantic issues were found.

### Manual Review
- Verified that `MainActivity.kt` correctly routes the `reloadRules` call to `reprocessUnparsedLogs`.
- Confirmed that the `FinancialTrackerService.dart` includes the updated method definitions for Flutter interaction.

> [!TIP]
> You can now test the new parser by adding a custom rule with named groups in your `custom_tracker_config.json` or by simply arriving at a new STC Pay notification!
