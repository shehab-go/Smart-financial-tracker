# Debit Credit App – Documentation

## Overview
Offline-first personal finance ledger (Arabic UI) built with Flutter. Create accounts by category, record debit/credit transactions, view totals, generate Arabic RTL PDF reports, and back up/restore the local SQLite database.

## Tech Stack
- Flutter (Material 3)
- SQLite: `sqflite`
- PDFs: `pdf`, `printing`
- Share: `share_plus`
- Storage/permissions: `permission_handler`
- Contact picker: `fluttercontactpicker`
- Formatting: `intl`

## Structure
- `lib/main.dart`: App entry → `HomeScreen`
- `lib/db/database_helper.dart`: schema, migrations, CRUD, aggregates
- `lib/models/`: `AccountModel`, `CategoryModel`, `CurrencyModel`, `TransactionModel`
- `lib/services/`: `BackupService` (DB backups), `ReportService` (PDF)
- `lib/screens/`: `HomeScreen`, `AccountTransactionsScreen`, `CategoriesScreen`, `CurrenciesScreen`, `BackupScreen`, `AboutScreen`, `PrivacyScreen`
- `lib/widgets/`: `AddTransactionDialog`, `TransactionTile`, `AppDrawer`, `ReportBottomSheet`

## Features
- Accounts grouped by categories (seeded defaults)
- Debit (عليه) / Credit (له) transactions with date and details
- Per-account and per-category totals (credit/debit/net)
- Arabic RTL UI and PDFs
- Multi-select (delete/print/share) for accounts and transactions
- Local DB backups and restore
- Manage categories and currencies; single default currency

## Database (SQLite)
Tables:
- `categories(id, name UNIQUE, name, icon)`
- `currencies(id, name, name, symbol, code UNIQUE, isDefault INTEGER)`
- `accounts(id, name, category, createdDate INTEGER, currencyCode TEXT DEFAULT 'LOC', phone TEXT)`
- `transactions(id, accountId, amount REAL, type TEXT, category TEXT, date INTEGER, description TEXT, FK accountId → accounts.id ON DELETE CASCADE)`

Notes:
- `transactions.category` is denormalized (stored as text).
- Aggregates via SQL queries (totals per account/category).

## Flows
- Home loads categories → accounts with stats per category → totals per category
- Add transaction: optionally creates account, then inserts transaction
- Account screen loads transactions and computes totals
- Reports: Arabic PDF tables saved to `Downloads/FinanceApp/report`
- Backups: DB copies to `Downloads/FinanceApp/Backups`; restore overwrites DB

## Build & Run
1. `flutter pub get`
2. `flutter run`

Platform notes:
- Android may require storage permission for writing to public Downloads.
- Desktop uses Downloads/documents and opens files with system viewer.

## Known Issues / Improvements
- Home account list: swap displayed debit/credit values to match header labels/colors.
- Deleting a category currently doesn’t delete its accounts/transactions; add delete-by-category (transactions cascade from accounts).
- Ensure `transactions.date` is `INTEGER` and migrate older DBs if needed.
- Consider replacing `MANAGE_EXTERNAL_STORAGE` with app-specific storage or SAF/MediaStore.
- Remove unused deps (`provider`, `file_picker`) or start using them.

## Privacy
All data stays local on the device. No network usage. Backups are local files in Downloads.
