package com.financial.tracker.module.parser

import android.os.Build
import com.financial.tracker.module.data.FinancialTransaction
import com.financial.tracker.module.config.WalletConfigManager
import java.util.regex.Pattern

import com.financial.tracker.module.config.WalletConfig
import com.google.gson.Gson

internal object DynamicParser {

    fun parse(packageName: String, title: String, text: String, customConfigJson: String? = null): FinancialTransaction? {
        val fullContent = "$title $text"
        val config = if (customConfigJson != null) {
            try {
                Gson().fromJson(customConfigJson, WalletConfig::class.java)
            } catch (e: Exception) {
                e.printStackTrace()
                return null
            }
        } else {
            WalletConfigManager.getConfigForPackage(packageName)
        } ?: return null

        for (rule in config.rules) {
            val identifierMatcher = Pattern.compile(rule.identifierRegex).matcher(fullContent)
            if (identifierMatcher.find()) {
                val amount = extractField(fullContent, rule.parsers.amount)?.toDoubleOrNull() ?: 0.0
                val currency = extractField(fullContent, rule.parsers.currency) ?: "SAR"
                val counterpart = extractField(fullContent, rule.parsers.counterpart) ?: "Unknown"
                var referenceId = extractField(fullContent, rule.parsers.referenceId) ?: ""
                val balanceRaw = extractField(fullContent, rule.parsers.balance)
                val balance = if (balanceRaw != null) {
                    balanceRaw.replace(Regex("[^0-9.]"), "").toDoubleOrNull()
                } else null

                if (referenceId.isEmpty() || referenceId == "N/A") {
                    referenceId = "hash_" + Math.abs(fullContent.hashCode()).toString()
                }

                val parsedTx = com.financial.tracker.module.data.FinancialTransaction(
                    packageName = packageName,
                    transactionType = rule.transactionType,
                    amount = amount,
                    currency = currency,
                    counterpart = counterpart,
                    referenceId = referenceId,
                    timestamp = System.currentTimeMillis(),
                    balance = balance
                )
                
                android.util.Log.i("WalletTracker", "✅ Parsed Successfully: \nAmount: $amount $currency\nType: ${rule.transactionType}\nCounterpart: $counterpart\nRef: $referenceId")
                
                return parsedTx
            }
        }
        
        android.util.Log.w("WalletTracker", "❌ Failed to parse notification from $packageName. No matching rule found.")
        return null
    }

    private fun extractField(text: String, regexPattern: String?): String? {
        if (regexPattern == null) return null
        try {
            val matcher = Pattern.compile(regexPattern).matcher(text)
            if (matcher.find()) {
                return try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        matcher.group("value")
                    } else {
                        TODO("VERSION.SDK_INT < O")
                    }
                } catch (e: IllegalArgumentException) {
                    matcher.group(1)
                } catch (e: UnsupportedOperationException) {
                    matcher.group(1)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }
}
