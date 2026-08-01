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
        val gson = Gson()
        try {
            val customFile = java.io.File(context.filesDir, "custom_tracker_config.json")
            val inputStream = if (customFile.exists() && customFile.length() > 0) {
                java.io.FileInputStream(customFile)
            } else {
                context.assets.open("financial_tracker_config.json")
            }

            inputStream.use { stream ->
                InputStreamReader(stream).use { reader ->
                    val configList = gson.fromJson(reader, Array<WalletConfig>::class.java)
                    if (configList != null) {
                        for (config in configList) {
                            newConfigs[config.packageName] = config
                        }
                    }
                }
            }
            synchronized(configs) {
                configs.clear()
                configs.putAll(newConfigs)
                isInitialized = true
            }
            android.util.Log.i("WalletTracker", "✅ WalletConfigManager reloaded ${newConfigs.size} package configs successfully.")
        } catch (e: Exception) {
            android.util.Log.e("WalletTracker", "❌ Failed to load wallet configs", e)
            e.printStackTrace()
        }
    }

    fun isTargetWallet(packageName: String): Boolean {
        return synchronized(configs) {
            configs.containsKey(packageName)
        }
    }

    fun getConfigForPackage(packageName: String): WalletConfig? {
        return synchronized(configs) {
            configs[packageName]
        }
    }
}

internal data class WalletConfig(
    val packageName: String,
    val walletName: String? = null,
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
