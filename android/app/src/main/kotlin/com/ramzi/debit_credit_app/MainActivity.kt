package com.ramzi.debit_credit_app

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.financial.tracker.module.FinancialTrackerClient
import com.google.gson.Gson
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.collectLatest

class MainActivity : FlutterFragmentActivity() {
    private val METHOD_CHANNEL = "com.ramzi.debit_credit_app/financial_tracker"
    private val EVENT_CHANNEL = "com.ramzi.debit_credit_app/financial_tracker_events"
    private val scope = CoroutineScope(Dispatchers.Main + Job())
    private val gson = Gson()

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestNotificationPermission" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "getAllTransactions" -> {
                    scope.launch {
                        val transactions = FinancialTrackerClient.getAllTransactions(applicationContext)
                        result.success(gson.toJson(transactions))
                    }
                }
                "markAsClassified" -> {
                    val refId = call.argument<String>("referenceId")
                    val category = call.argument<String>("category")
                    if (refId != null && category != null) {
                        scope.launch {
                            FinancialTrackerClient.markAsClassified(applicationContext, refId, category)
                            result.success(true)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Missing referenceId or category", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                private var job: Job? = null
                
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    job = scope.launch {
                        FinancialTrackerClient.transactionFlow.collectLatest { transaction ->
                            events?.success(gson.toJson(transaction))
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    job?.cancel()
                }
            }
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }
}
