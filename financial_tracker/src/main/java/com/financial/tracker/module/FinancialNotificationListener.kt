package com.financial.tracker.module

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.os.Bundle
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import com.financial.tracker.module.parser.DynamicParser
import com.financial.tracker.module.data.DatabaseClient
import com.financial.tracker.module.config.WalletConfigManager

class FinancialNotificationListener : NotificationListenerService() {

    private val serviceScope = CoroutineScope(Dispatchers.IO)

    override fun onCreate() {
        super.onCreate()
        // Initialize config manager on creation
        WalletConfigManager.init(applicationContext)
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName
        val extras: Bundle = sbn.notification.extras
        val title = extras.getCharSequence("android.title")?.toString() ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""

        // Print EVERYTHING to logcat so we can analyze any new bank/wallet apps
        android.util.Log.d("WalletTrackerRaw", "Package: $packageName | Title: $title | Text: $text")

        if (!WalletConfigManager.isTargetWallet(packageName)) {
            return
        }

        serviceScope.launch {
            processNotificationSilently(packageName, title, text)
        }
    }

    private suspend fun processNotificationSilently(packageName: String, title: String, text: String) {
        val transaction = DynamicParser.parse(packageName, title, text)
        val dao = DatabaseClient.getDatabase(applicationContext)

        if (transaction != null) {
            // Deduplication Check
            val existing = dao.checkDuplicate(transaction.referenceId)
            if (existing == null) {
                dao.insertTransaction(transaction)
                FinancialTrackerClient.sendEventToUI(transaction)
            }
        } else {
            // Error Analytics: Log the unparsed notification
            val unparsed = com.financial.tracker.module.data.UnparsedNotification(
                packageName = packageName,
                title = title,
                text = text,
                timestamp = System.currentTimeMillis()
            )
            dao.insertUnparsedNotification(unparsed)
        }
    }
}
