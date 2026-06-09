package com.financial.tracker.module.data

import android.content.Context

internal object DatabaseClient {
    @Volatile
    private var instance: TransactionDao? = null

    fun getDatabase(context: Context): TransactionDao {
        return instance ?: synchronized(this) {
            instance ?: TransactionDao(context.applicationContext).also { instance = it }
        }
    }
}
