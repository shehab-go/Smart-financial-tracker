package com.financial.tracker.module

import androidx.core.net.toUri
import com.financial.tracker.module.data.FinancialTransaction
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

/**
 * The main entry point for the Smart Financial Tracker library.
 *
 * This client provides access to the parsed financial transactions and allows
 * for manual processing and configuration management.
 */
object FinancialTrackerClient {
    /**
     * Set this to true to enable internal library logging in Logcat.
     * Useful for debugging regex rules and parsing logic.
     */
    var loggingEnabled: Boolean = false

    private val _transactionFlow =
        MutableSharedFlow<FinancialTransaction>(
            replay = 0,
            extraBufferCapacity = 10,
            onBufferOverflow = BufferOverflow.DROP_OLDEST,
        )

    /**
     * A [SharedFlow] that emits every new unique [FinancialTransaction] parsed from incoming notifications.
     * Collect this flow in your UI layers to respond to real-time financial events.
     */
    val transactionFlow: SharedFlow<FinancialTransaction> = _transactionFlow.asSharedFlow()

    internal fun sendEventToUI(transaction: FinancialTransaction) {
        _transactionFlow.tryEmit(transaction)
    }

    /**
     * Tests a notification string against the library's parsing logic.
     *
     * @param packageName The package name of the app that supposedly sent the notification.
     * @param title The notification title.
     * @param text The notification body text.
     * @param customConfigJson Optional: provide a custom JSON configuration to test new regex rules.
     * @return A [FinancialTransaction] if parsing was successful, null otherwise.
     */
    fun testParser(
        packageName: String,
        title: String,
        text: String,
        customConfigJson: String? = null,
    ): FinancialTransaction? {
        return com.financial.tracker.module.parser.DynamicParser.parse(packageName, title, text, customConfigJson)
    }

    /**
     * Retrieves all successfully parsed transactions stored in the local encrypted database.
     *
     * @param context Android context for database access.
     * @return A list of [FinancialTransaction] objects.
     */
    suspend fun getAllTransactions(context: android.content.Context): List<FinancialTransaction> {
        return com.financial.tracker.module.data.DatabaseClient.getDatabase(context).getAll()
    }

    suspend fun updateTransaction(
        context: android.content.Context,
        transaction: FinancialTransaction,
    ) {
        com.financial.tracker.module.data.DatabaseClient.getDatabase(context).updateTransaction(transaction)
    }

    suspend fun markAsSettled(
        context: android.content.Context,
        refId: String,
        settlementRef: String? = null,
    ) {
        com.financial.tracker.module.data.DatabaseClient.getDatabase(context).markAsSettled(refId, settlementRef)
    }

    suspend fun markAsClassified(
        context: android.content.Context,
        refId: String,
        category: String,
    ) {
        com.financial.tracker.module.data.DatabaseClient.getDatabase(context).markAsClassified(refId, category)
    }

    /**
     * Get all notifications that failed to parse (Error Analytics).
     */
    suspend fun getUnparsedLogs(context: android.content.Context): List<com.financial.tracker.module.data.UnparsedNotification> {
        return com.financial.tracker.module.data.DatabaseClient.getDatabase(context).getUnparsedNotifications()
    }

    /**
     * Re-processes all unparsed logs using the current configuration.
     * Useful when configuration is updated and old notifications need to be parsed.
     */
    suspend fun reprocessUnparsedLogs(context: android.content.Context) {
        // Force reload the config so any new rules are applied without killing the app
        com.financial.tracker.module.config.WalletConfigManager.reload(context)

        val dao = com.financial.tracker.module.data.DatabaseClient.getDatabase(context)
        val unparsed = dao.getUnparsedNotifications()
        unparsed.forEach { log ->
            val tx = testParser(log.packageName, log.title, log.text, null)
            if (tx != null) {
                if (dao.checkDuplicate(tx.referenceId) == null) {
                    dao.insertTransaction(tx)
                    sendEventToUI(tx)
                }
            }
        }
        // Clear them after processing so they aren't processed again
        clearUnparsedLogs(context)
    }

    /**
     * Clear the unparsed notifications log.
     */
    suspend fun clearUnparsedLogs(context: android.content.Context) {
        com.financial.tracker.module.data.DatabaseClient.getDatabase(context).clearUnparsedNotifications()
    }

    /**
     * Requests the user to ignore battery optimizations for this app,
     * ensuring the NotificationListener doesn't get killed by Doze mode.
     */
    fun requestBatteryOptimization(context: android.content.Context) {
        val intent =
            android.content.Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = "package:${context.packageName}".toUri()
                flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
            }
        try {
            context.startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
