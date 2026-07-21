package com.financial.tracker.module

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.os.Bundle
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.ramzi.debit_credit_app.MainActivity
import com.ramzi.debit_credit_app.R
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
        // Initialize config manager on creation in background
        serviceScope.launch {
            WalletConfigManager.init(applicationContext)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        // Helps sometimes to restart the service
        val restartServiceIntent = Intent(applicationContext, this.javaClass)
        restartServiceIntent.setPackage(packageName)
        val restartServicePendingIntent = PendingIntent.getService(
            applicationContext, 1, restartServiceIntent, 
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmService = applicationContext.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        alarmService.set(
            android.app.AlarmManager.ELAPSED_REALTIME,
            android.os.SystemClock.elapsedRealtime() + 1000,
            restartServicePendingIntent
        )
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
                triggerHapticFeedback()
                showLocalNotification(transaction)
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

    private fun triggerHapticFeedback() {
        try {
            val vibrator = applicationContext.getSystemService(android.content.Context.VIBRATOR_SERVICE) as android.os.Vibrator
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                vibrator.vibrate(android.os.VibrationEffect.createOneShot(30, android.os.VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(30)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun showLocalNotification(transaction: com.financial.tracker.module.data.FinancialTransaction) {
        val channelId = "financial_tracker_alerts"
        val notificationManager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "إشعارات الراصد",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "إشعارات العمليات المالية الجديدة التي يلتقطها الراصد"
            }
            notificationManager.createNotificationChannel(channel)
        }

        val intent = Intent(applicationContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        
        val pendingIntent: PendingIntent = PendingIntent.getActivity(
            applicationContext, 
            0, 
            intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val amountStr = transaction.amount.toString()
        val walletName = if (transaction.packageName.contains("stcpay")) "STC Pay" else "جيب"

        val builder = NotificationCompat.Builder(applicationContext, channelId)
            .setSmallIcon(R.mipmap.ic_launcher) // Using default launcher icon
            .setContentTitle("عملية مالية جديدة")
            .setContentText("تم التقاط عملية بمبلغ $amountStr ريال عبر $walletName. اضغط للتصنيف.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)

        try {
            notificationManager.notify(transaction.referenceId.hashCode(), builder.build())
        } catch (e: SecurityException) {
            android.util.Log.e("WalletTracker", "Missing POST_NOTIFICATIONS permission", e)
        }
    }
}
