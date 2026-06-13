package com.financial.tracker.module.config

import android.content.Context
import com.google.gson.Gson
import java.io.InputStreamReader

object WalletConfigManager {
    private val configs = mutableMapOf<String, WalletConfig>()

    fun init(context: Context) {
        if (configs.isNotEmpty()) return
        reload(context)
    }

    fun reload(context: Context) {
        configs.clear()
        try {
            val inputStream = context.assets.open("financial_tracker_config.json")
            val reader = InputStreamReader(inputStream)
            val gson = Gson()
            val configList = gson.fromJson(reader, Array<WalletConfig>::class.java)
            for (config in configList) {
                configs[config.packageName] = config
            }
            reader.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun isTargetWallet(packageName: String): Boolean {
        return configs.containsKey(packageName)
    }

    internal fun getConfigForPackage(packageName: String): WalletConfig? {
        return configs[packageName]
    }
}

internal data class WalletConfig(
    val packageName: String,
    val rules: List<TransactionRule>
)

internal data class TransactionRule(
    val transactionType: String,
    val identifierRegex: String,
    val parsers: TransactionParsers
)

internal data class TransactionParsers(
    val amount: String,
    val currency: String,
    val counterpart: String,
    val referenceId: String
)
