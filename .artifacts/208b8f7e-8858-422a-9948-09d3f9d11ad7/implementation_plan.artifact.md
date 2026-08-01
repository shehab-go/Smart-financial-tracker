# Implementation Plan - Fix ANR in Financial Tracker Module

The application is experiencing ANRs (Application Not Responding) related to `nativePollOnce` and input dispatching timeouts. This is primarily caused by heavy data serialization and deserialization on the Main thread (UI thread) when fetching a large list of financial transactions.

## User Review Required

> [!IMPORTANT]
> The fix involves moving serialization/deserialization to background threads/isolates. While this resolves ANRs, if the dataset grows extremely large (e.g., >10,000 transactions), even background processing might consume significant memory. Long-term, implementing pagination for transactions is recommended.

## Proposed Changes

### Android Native Component

#### [MODIFY] [MainActivity.kt](file:///E:/hemmah/debit_credit_app/android/app/src/main/kotlin/com/ramzi/debit_credit_app/MainActivity.kt)
- Wrap `gson.toJson(transactions)` in `withContext(Dispatchers.Default)` to ensure the CPU-intensive serialization happens off the Main thread.
- Ensure `result.success()` is still called on the Main thread (which it will be, as the coroutine resumes there after `withContext`).

### Flutter Component

#### [MODIFY] [financial_tracker_service.dart](file:///E:/hemmah/debit_credit_app/lib/services/financial_tracker_service.dart)
- Use Flutter's `compute()` function to run `jsonDecode` in a separate isolate for the `getAllTransactions` method. This prevents the UI from freezing while parsing large JSON strings.

## Verification Plan

### Automated Tests
- Since this is a threading/performance issue, I will verify the code changes compile and follow best practices for coroutines and isolates.
- I will check for any other potential `MethodChannel` calls that might be blocking.

### Manual Verification
- The user can verify that navigating to the "Smart Dashboard" (which triggers `getAllTransactions`) is smoother and no longer causes ANRs in production or under high-load testing (simulating many transactions).
