# Security Deep Dive

Security is the #1 priority for Smart Financial Tracker. Financial data is extremely sensitive, and we take multiple steps to ensure it never leaks.

## 1. Local-Only Processing
**No data ever leaves the device.**
- All parsing happens on the device.
- All storage is in the app's internal database.
- There is no cloud sync or external API reporting by default.

## 2. AES-256 GCM Encryption
We use the Android KeyStore system to generate and protect encryption keys.
- **Algorithm**: AES in Galois/Counter Mode (GCM).
- **IV (Initialization Vector)**: Every piece of data is encrypted with a unique IV stored alongside the ciphertext.
- **Key Protection**: Keys are stored in the Hardware-backed KeyStore where possible, making it impossible to extract them even on rooted devices.

## 3. Reference ID Hashing (Anonymization)
To prevent duplicate transactions, we need to compare "Reference IDs" sent by banks.
- Instead of storing "Ref: 123456" in plain text, we store a hash: `fba...321`.
- When a new notification arrives, we hash its Ref ID and compare it to the stored hashes.
- This provides deduplication without storing the actual ID.

## 4. Permission Scoping
- We only request the minimum permissions needed.
- `BIND_NOTIFICATION_LISTENER_SERVICE` is a high-privilege permission that the user must manually grant in Android Settings, ensuring they are fully aware of the library's capabilities.
