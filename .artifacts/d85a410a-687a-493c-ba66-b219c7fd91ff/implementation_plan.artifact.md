# Fix ANR Issues in Production

The goal is to resolve the Application Not Responding (ANR) issues reported in the Play Store, specifically focusing on the UI thread unresponsiveness during startup and background tasks.

## User Review Required

> [!IMPORTANT]
> I have identified three major potential causes for the ANR:
> 1.  **Database Deadlock on Startup**: The app runs a heavy `VACUUM` operation (database optimization) just 2 seconds after startup, while multiple screens are also trying to load data from the same database.
> 2.  **Illegal State Mutation in Build**: The `SmartDashboardScreen` (Radar) performs logic and state updates inside its `build` method, which can cause performance bottlenecks and infinite rebuild loops.
> 3.  **Synchronous JSON Parsing**: Large transaction logs are parsed synchronously on the main thread, which can freeze the UI if there are many entries.

## Proposed Changes

### [Component] Core Navigation & Backup

#### [MODIFY] [main_navigation.dart](file:///E:/hemmah/debit_credit_app/lib/core/widgets/main_navigation.dart)
- Increase the delay for the initial auto-backup check to 10 seconds to ensure the UI is fully loaded and idle before any heavy background work starts.

#### [MODIFY] [auto_backup_manager.dart](file:///E:/hemmah/debit_credit_app/lib/core/services/auto_backup_manager.dart)
- **Move `VACUUM`**: Only perform database `VACUUM` during the `Workmanager` (background) task. Avoid running it during "interactive" or "startup" backups triggered from the UI.

### [Component] Smart Dashboard (Radar)

#### [MODIFY] [smart_dashboard_screen.dart](file:///E:/hemmah/debit_credit_app/lib/features/home/presentation/screens/smart_dashboard_screen.dart)
- **Refactor Stream Listening**: Remove the `StreamBuilder` logic that modifies state during `build`. Use a `StreamSubscription` in `initState` to handle new transactions and update the `AnimatedList` correctly.
- **Isolate Parsing**: Use `compute` for `jsonDecode` when fetching all transactions from the native side.

### [Component] Database Layer

#### [MODIFY] [database_helper.dart](file:///E:/hemmah/debit_credit_app/lib/core/db/database_helper.dart)
- **Add Indices**: Add a composite index on `transactions(accountId, date)` to speed up the `MAX(date)` subqueries used in account lists.
- **Optimize Maintenance**: Ensure `_runPostOpenMaintenance` is as efficient as possible.

## Verification Plan

### Automated Tests
- Build the app in release mode and monitor startup time and CPU usage.

### Manual Verification
1.  **Startup Performance**: Verify the app opens and responds to touch immediately without stutters.
2.  **Radar Live Update**: Ensure new transactions coming through the stream still appear in the list with the correct animation.
3.  **Backup Logic**: Trigger a manual backup and ensure it doesn't freeze the UI.
