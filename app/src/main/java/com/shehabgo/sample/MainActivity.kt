package com.shehabgo.sample

import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.financial.tracker.module.FinancialTrackerClient
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        val textView = TextView(this).apply {
            text = "Waiting for transactions...\nMake sure to grant Notification Access in Settings."
            textSize = 18f
            setPadding(32, 32, 32, 32)
        }
        setContentView(textView)

        // Observe transactions from the library
        lifecycleScope.launch {
            FinancialTrackerClient.transactionFlow.collect { transaction ->
                val currentText = textView.text.toString()
                textView.text = "New Transaction:\n" +
                        "Amount: ${transaction.amount} ${transaction.currency}\n" +
                        "Counterpart: ${transaction.counterpart}\n" +
                        "Type: ${transaction.transactionType}\n" +
                        "-------------------\n" +
                        currentText
            }
        }
        
        // Request battery optimization ignore if needed
        FinancialTrackerClient.requestBatteryOptimization(this)
    }
}
