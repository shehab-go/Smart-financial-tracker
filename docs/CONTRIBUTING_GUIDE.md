# Technical Contribution Guide

This guide is for developers who want to contribute code to the Smart Financial Tracker.

## Project Structure
- `:financial_tracker`: The core library module.
    - `module.parser`: Contains the `DynamicParser` and regex logic.
    - `module.data`: Room/SQLite database and AES encryption.
    - `module.config`: Logic for managing bank configurations.
- `:app`: The sample showcase application.

## Development Setup
1. Clone the repo: `git clone https://github.com/shehab-go/smart-financial-tracker.git`
2. Open in **Android Studio (Ladybug or newer)**.
3. Enable **Notification Access** for the sample app on your test device.

## How to add a new Bank Parser
The library uses a dynamic regex system. You don't need to change code to add a new bank, just update the configuration:

1. Identify the SMS or Notification pattern for the bank.
2. Add a new JSON entry in `WalletConfigManager`.
3. Test it using `FinancialTrackerClient.testParser()`.

Example Rule:
```json
{
  "identifierRegex": "Purchase at .* amount",
  "transactionType": "Purchase",
  "parsers": {
    "amount": "amount\\s+(?<value>[0-9.]+)",
    "currency": "amount\\s+[0-9.]+\\s+(?<value>[A-Z]{3})",
    "counterpart": "Purchase at\\s+(?<value>.*?)\\s+with"
  }
}
```

## Coding Standards
- We use **Ktlint** to enforce style. Run `./gradlew ktlintCheck` before pushing.
- All new features must have a unit test in `DynamicParserTest.kt`.
