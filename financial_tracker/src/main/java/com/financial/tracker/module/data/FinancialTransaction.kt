package com.financial.tracker.module.data

/**
 * Represents a parsed financial transaction extracted from notifications.
 * 
 * @property id The unique internal database ID.
 * @property packageName The package name of the app that generated the notification (e.g. bank app).
 * @property transactionType The type of transaction (e.g. Transfer, Payment, Withdrawal, Deposit).
 * @property amount The extracted transaction amount.
 * @property currency The extracted currency code (e.g. SAR, USD).
 * @property counterpart The name of the sender, recipient, or merchant.
 * @property referenceId A unique reference ID extracted from the notification to prevent duplicates.
 * @property timestamp The Unix timestamp of when the transaction was parsed.
 */
data class FinancialTransaction(
    val id: Int = 0,
    val packageName: String,
    val transactionType: String,
    val amount: Double,
    val currency: String,
    val counterpart: String,
    val referenceId: String,
    val timestamp: Long,
    val isDebt: Boolean = false,
    val isSettled: Boolean = false,
    val settlementRefId: String? = null,
    val isClassified: Boolean = false,
    val category: String? = null
)
