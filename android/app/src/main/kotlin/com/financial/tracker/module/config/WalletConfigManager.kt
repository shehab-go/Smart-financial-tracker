package com.financial.tracker.module.config

import android.content.Context
import com.google.gson.Gson
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.InputStreamReader

object WalletConfigManager {
    private val configs = mutableMapOf<String, WalletConfig>()
    private var isInitialized = false

    suspend fun init(context: Context) {
        if (isInitialized) return
        reload(context)
    }

    suspend fun reload(context: Context) = withContext(Dispatchers.IO) {
        val newConfigs = mutableMapOf<String, WalletConfig>()
        try {
            context.assets.open("financial_tracker_config.json").use { inputStream ->
                InputStreamReader(inputStream).use { reader ->
                    val gson = Gson()
                    val configList = gson.fromJson(reader, Array<WalletConfig>::class.java)
                    for (config in configList) {
                        newConfigs[config.packageName] = config
                    }
                }
            }
            synchronized(configs) {
                configs.clear()
                configs.putAll(newConfigs)
                isInitialized = true
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun isTargetWallet(packageName: String): Boolean {
        return synchronized(configs) {
            configs.containsKey(packageName)
        }
    }

    internal fun getConfigForPackage(packageName: String): WalletConfig? {
        return synchronized(configs) {
            configs[packageName]
        }
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
    val referenceId: String,
    val balance: String? = null
)
