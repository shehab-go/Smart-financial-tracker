# Fix ANR (nativePollOnce) in Production

The ANR `nativePollOnce` with "Input dispatching timed out" indicates that the main thread is blocked for too long (typically > 5 seconds). Analysis of the codebase revealed several potential candidates for blocking the main thread:
1. **JSON Serialization/Deserialization**: `MainActivity` performs `gson.toJson` on the main thread, which can be slow for large lists of transactions.
2. **Keystore Operations**: `AESEncryptionHelper` reloads the `KeyStore` on every encryption/decryption and performs key generation in its `init` block (which can run on the main thread if first accessed there).
3. **Asset Loading**: `WalletConfigManager` loads and parses JSON from assets on the main thread during initialization.

## User Review Required

> [!IMPORTANT]
> The fixes involve moving several initializations and processing steps to background threads. This might slightly delay the availability of some data (like configurations) upon app start, but will prevent the UI from freezing.

## Proposed Changes

### [Component] Data & Encryption

#### [MODIFY] [AESEncryptionHelper.kt](file:///E:/hemmah/debit_credit_app/android/app/src/main/kotlin/com/financial/tracker/module/data/AESEncryptionHelper.kt)
- Cache the `KeyStore` and `SecretKey` instances to avoid repeated `KeyStore.load(null)` calls.
- Remove key generation from the `init` block and ensure it's called on a background thread when first needed.

### [Component] Configuration Management

#### [MODIFY] [WalletConfigManager.kt](file:///E:/hemmah/debit_credit_app/android/app/src/main/kotlin/com/financial/tracker/module/config/WalletConfigManager.kt)
- Update `init` and `reload` to be `suspend` functions or internally use a background dispatcher to avoid blocking the main thread during asset loading and JSON parsing.

### [Component] Main UI Bridge

#### [MODIFY] [MainActivity.kt](file:///E:/hemmah/debit_credit_app/android/app/src/main/kotlin/com/ramzi/debit_credit_app/MainActivity.kt)
- Move `gson.toJson` calls to a background thread (e.g., `withContext(Dispatchers.Default)`) before sending results back to Flutter via `MethodChannel` or `EventChannel`.

#### [MODIFY] [FinancialNotificationListener.kt](file:///E:/hemmah/debit_credit_app/android/app/src/main/kotlin/com/financial/tracker/module/FinancialNotificationListener.kt)
- Ensure `WalletConfigManager.init` is called within a coroutine scope to avoid blocking the main thread during service creation.

## Verification Plan

### Automated Tests
- Since this is a concurrency/performance issue, automated unit tests might not easily reproduce the ANR, but I will ensure that the logic remains correct after refactoring.
- Check that `AESEncryptionHelper` still correctly encrypts and decrypts.

### Manual Verification
- Monitor Logcat for any `KeyStore` errors during initial key generation.
- Verify that transactions are still correctly parsed and displayed in the app.
- Check that the app remains responsive during heavy database fetching (e.g., many transactions).
