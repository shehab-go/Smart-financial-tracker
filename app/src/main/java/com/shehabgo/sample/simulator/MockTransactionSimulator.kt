package com.shehabgo.sample.simulator

import android.content.Context
import com.financial.tracker.module.FinancialTrackerClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

object MockTransactionSimulator {
    private val simulatorScope = CoroutineScope(Dispatchers.IO)

    fun simulateSTCPay(context: Context) {
        val sms = "Purchase at Supermarket with amount 150.00 SAR. Ref: ${System.currentTimeMillis()}"
        processMock(context, "com.stc.pay", "stc pay", sms)
    }

    fun simulateAlkuraimi(context: Context) {
        val sms = "Received transfer of 50,000 YER from Ahmed. Ref: ${System.currentTimeMillis()}"
        // Note: This matches the roadmap wallets we mentioned
        processMock(context, "com.alkuraimi.mfloos", "mFloos", sms)
    }

    fun simulateUrPay(context: Context) {
        val sms = "Payment to Merchant amount 45.50 SAR successful. Ref: ${System.currentTimeMillis()}"
        processMock(context, "com.urpay.app", "urpay", sms)
    }

    private fun processMock(
        context: Context,
        pkg: String,
        title: String,
        text: String,
    ) {
        simulatorScope.launch {
            // Add a small delay to feel like a real notification arriving
            delay(500)
            val tx = FinancialTrackerClient.testParser(pkg, title, text)
            if (tx != null) {
                // In a real app, the listener would save to DB.
                // Here we manually save and emit to show it in UI.
                FinancialTrackerClient.getAllTransactions(context) // Ensure DB init
                // Internal API call for simulation purposes
                val method = FinancialTrackerClient::class.java.getDeclaredMethod("sendEventToUI", tx::class.java)
                method.isAccessible = true
                method.invoke(FinancialTrackerClient, tx)
            }
        }
    }
}
