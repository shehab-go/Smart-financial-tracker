package com.financial.tracker.module

import android.content.Context
import android.content.Intent
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import com.google.gson.Gson
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.collectLatest

/**
 * Native Kotlin Flutter Plugin for the Financial Tracker Android Library module.
 * Exposes MethodChannel and EventChannel for seamless Flutter integration.
 */
class FinancialTrackerPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private companion object {
        const val METHOD_CHANNEL_NAME = "com.ramzi.debit_credit_app/financial_tracker"
        const val EVENT_CHANNEL_NAME = "com.ramzi.debit_credit_app/financial_tracker_events"
    }

    private var context: Context? = null
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var streamJob: Job? = null
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private val gson = Gson()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL_NAME)
        methodChannel?.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel?.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        context = null
        scope.cancel()
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val currentContext = context
        if (currentContext == null) {
            result.error("NO_CONTEXT", "Application context is null", null)
            return
        }

        when (call.method) {
            "requestNotificationPermission" -> {
                val intent =
                    Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                currentContext.startActivity(intent)
                result.success(true)
            }
            "isNotificationPermissionGranted" -> {
                val enabledListeners = NotificationManagerCompat.getEnabledListenerPackages(currentContext)
                val isGranted = enabledListeners.contains(currentContext.packageName)
                result.success(isGranted)
            }
            "getAllTransactions" -> {
                scope.launch {
                    val transactions = FinancialTrackerClient.getAllTransactions(currentContext)
                    val json =
                        withContext(Dispatchers.Default) {
                            gson.toJson(transactions)
                        }
                    result.success(json)
                }
            }
            "markAsClassified" -> {
                val refId = call.argument<String>("referenceId")
                val category = call.argument<String>("category")
                if (refId != null && category != null) {
                    scope.launch {
                        FinancialTrackerClient.markAsClassified(currentContext, refId, category)
                        result.success(true)
                    }
                } else {
                    result.error("INVALID_ARGS", "Missing referenceId or category", null)
                }
            }
            "reloadRules" -> {
                scope.launch {
                    FinancialTrackerClient.reprocessUnparsedLogs(currentContext)
                    result.success(true)
                }
            }
            "testParser" -> {
                val packageName = call.argument<String>("packageName") ?: ""
                val title = call.argument<String>("title") ?: ""
                val text = call.argument<String>("text") ?: ""
                val customConfig = call.argument<String>("customConfigJson")

                val parsedTx = FinancialTrackerClient.testParser(packageName, title, text, customConfig)
                if (parsedTx != null) {
                    result.success(gson.toJson(parsedTx))
                } else {
                    result.success(null)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?,
    ) {
        streamJob?.cancel()
        streamJob =
            scope.launch {
                FinancialTrackerClient.transactionFlow.collectLatest { transaction ->
                    val json =
                        withContext(Dispatchers.Default) {
                            gson.toJson(transaction)
                        }
                    events?.success(json)
                }
            }
    }

    override fun onCancel(arguments: Any?) {
        streamJob?.cancel()
        streamJob = null
    }
}
