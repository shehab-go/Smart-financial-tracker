package com.financial.tracker.module.data

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

internal class TransactionDao(context: Context) : SQLiteOpenHelper(context, "financial_tracker.db", null, 3) {

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            "CREATE TABLE IF NOT EXISTS transactions (" +
                    "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    "packageName TEXT NOT NULL, " +
                    "transactionType TEXT NOT NULL, " +
                    "amount REAL NOT NULL, " +
                    "currency TEXT NOT NULL, " +
                    "counterpart TEXT NOT NULL, " +
                    "referenceId TEXT UNIQUE NOT NULL, " +
                    "timestamp INTEGER NOT NULL)"
        )
        
        db.execSQL(
            "CREATE TABLE IF NOT EXISTS unparsed_notifications (" +
                    "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    "packageName TEXT NOT NULL, " +
                    "title TEXT NOT NULL, " +
                    "text TEXT NOT NULL, " +
                    "timestamp INTEGER NOT NULL)"
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        if (oldVersion < 3) {
            db.execSQL(
                "CREATE TABLE IF NOT EXISTS unparsed_notifications (" +
                        "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                        "packageName TEXT NOT NULL, " +
                        "title TEXT NOT NULL, " +
                        "text TEXT NOT NULL, " +
                        "timestamp INTEGER NOT NULL)"
            )
            // Existing transactions might not be encrypted in older versions. 
            // In a strict production upgrade, we'd migrate them. For v1.1.0 we just clear to start fresh with security.
            db.execSQL("DROP TABLE IF EXISTS transactions")
            onCreate(db)
        }
    }

    suspend fun insertTransaction(transaction: FinancialTransaction) = withContext(Dispatchers.IO) {
        val db = writableDatabase
        val values = ContentValues().apply {
            put("packageName", transaction.packageName)
            put("transactionType", transaction.transactionType)
            // Encrypt sensitive fields
            put("amount", AESEncryptionHelper.encrypt(transaction.amount.toString()))
            put("currency", AESEncryptionHelper.encrypt(transaction.currency))
            put("counterpart", AESEncryptionHelper.encrypt(transaction.counterpart))
            // Hash reference ID for secure deduplication
            put("referenceId", AESEncryptionHelper.hashReferenceId(transaction.referenceId))
            put("timestamp", transaction.timestamp)
        }
        db.insert("transactions", null, values)
    }

    suspend fun checkDuplicate(refId: String): FinancialTransaction? = withContext(Dispatchers.IO) {
        val db = readableDatabase
        val hashedRefId = AESEncryptionHelper.hashReferenceId(refId)
        val cursor = db.rawQuery("SELECT * FROM transactions WHERE referenceId = ?", arrayOf(hashedRefId))
        var t: FinancialTransaction? = null
        if (cursor.moveToFirst()) {
            val amountStr = AESEncryptionHelper.decrypt(cursor.getString(cursor.getColumnIndexOrThrow("amount")))
            t = FinancialTransaction(
                id = cursor.getInt(cursor.getColumnIndexOrThrow("id")),
                packageName = cursor.getString(cursor.getColumnIndexOrThrow("packageName")),
                transactionType = cursor.getString(cursor.getColumnIndexOrThrow("transactionType")),
                amount = amountStr.toDoubleOrNull() ?: 0.0,
                currency = AESEncryptionHelper.decrypt(cursor.getString(cursor.getColumnIndexOrThrow("currency"))),
                counterpart = AESEncryptionHelper.decrypt(cursor.getString(cursor.getColumnIndexOrThrow("counterpart"))),
                // Return original refId to the caller since we only stored hash
                referenceId = refId,
                timestamp = cursor.getLong(cursor.getColumnIndexOrThrow("timestamp"))
            )
        }
        cursor.close()
        t
    }

    suspend fun getAll(): List<FinancialTransaction> = withContext(Dispatchers.IO) {
        val list = mutableListOf<FinancialTransaction>()
        val db = readableDatabase
        val cursor = db.rawQuery("SELECT * FROM transactions ORDER BY timestamp DESC", null)
        
        if (cursor.moveToFirst()) {
            do {
                val amountStr = AESEncryptionHelper.decrypt(cursor.getString(cursor.getColumnIndexOrThrow("amount")))
                val t = FinancialTransaction(
                    id = cursor.getInt(cursor.getColumnIndexOrThrow("id")),
                    packageName = cursor.getString(cursor.getColumnIndexOrThrow("packageName")),
                    transactionType = cursor.getString(cursor.getColumnIndexOrThrow("transactionType")),
                    amount = amountStr.toDoubleOrNull() ?: 0.0,
                    currency = AESEncryptionHelper.decrypt(cursor.getString(cursor.getColumnIndexOrThrow("currency"))),
                    counterpart = AESEncryptionHelper.decrypt(cursor.getString(cursor.getColumnIndexOrThrow("counterpart"))),
                    // In a normal fetch we can't unhash the refId, so we just return the hash as a placeholder for UI
                    referenceId = cursor.getString(cursor.getColumnIndexOrThrow("referenceId")),
                    timestamp = cursor.getLong(cursor.getColumnIndexOrThrow("timestamp"))
                )
                list.add(t)
            } while (cursor.moveToNext())
        }
        cursor.close()
        list
    }

    suspend fun insertUnparsedNotification(notification: UnparsedNotification) = withContext(Dispatchers.IO) {
        val db = writableDatabase
        val values = ContentValues().apply {
            put("packageName", notification.packageName)
            put("title", notification.title)
            put("text", notification.text)
            put("timestamp", notification.timestamp)
        }
        db.insert("unparsed_notifications", null, values)
    }

    suspend fun getUnparsedNotifications(): List<UnparsedNotification> = withContext(Dispatchers.IO) {
        val list = mutableListOf<UnparsedNotification>()
        val db = readableDatabase
        val cursor = db.rawQuery("SELECT * FROM unparsed_notifications ORDER BY timestamp DESC", null)
        
        if (cursor.moveToFirst()) {
            do {
                val item = UnparsedNotification(
                    id = cursor.getInt(cursor.getColumnIndexOrThrow("id")),
                    packageName = cursor.getString(cursor.getColumnIndexOrThrow("packageName")),
                    title = cursor.getString(cursor.getColumnIndexOrThrow("title")),
                    text = cursor.getString(cursor.getColumnIndexOrThrow("text")),
                    timestamp = cursor.getLong(cursor.getColumnIndexOrThrow("timestamp"))
                )
                list.add(item)
            } while (cursor.moveToNext())
        }
        cursor.close()
        list
    }

    suspend fun clearUnparsedNotifications() = withContext(Dispatchers.IO) {
        val db = writableDatabase
        db.delete("unparsed_notifications", null, null)
    }
}
