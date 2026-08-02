package com.shehabgo.sample

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.*
import androidx.core.app.NotificationManagerCompat
import com.financial.tracker.module.FinancialTrackerClient
import com.financial.tracker.module.data.FinancialTransaction
import com.shehabgo.sample.ui.DashboardScreen
import com.shehabgo.sample.ui.PermissionGuideScreen
import com.shehabgo.sample.ui.theme.SmartFinancialTrackerTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            SmartFinancialTrackerTheme {
                var isPermissionGranted by remember { mutableStateOf(checkNotificationPermission()) }
                var transactions by remember { mutableStateOf(listOf<FinancialTransaction>()) }

                // Check permission when returning to app
                DisposableEffect(Unit) {
                    val observer =
                        androidx.lifecycle.LifecycleEventObserver { _, event ->
                            if (event == androidx.lifecycle.Lifecycle.Event.ON_RESUME) {
                                isPermissionGranted = checkNotificationPermission()
                            }
                        }
                    lifecycle.addObserver(observer)
                    onDispose { lifecycle.removeObserver(observer) }
                }

                // Load initial data
                LaunchedEffect(Unit) {
                    transactions = FinancialTrackerClient.getAllTransactions(this@MainActivity)
                }

                // Listen for new transactions
                LaunchedEffect(Unit) {
                    FinancialTrackerClient.transactionFlow.collect { newTx ->
                        transactions = listOf(newTx) + transactions
                    }
                }

                if (isPermissionGranted) {
                    DashboardScreen(
                        transactions = transactions,
                        onOpenSettings = { openNotificationSettings() },
                    )
                } else {
                    PermissionGuideScreen(
                        onGrantClick = { openNotificationSettings() },
                    )
                }
            }
        }

        // Request battery optimization ignore if needed
        FinancialTrackerClient.requestBatteryOptimization(this)
    }

    private fun checkNotificationPermission(): Boolean {
        return NotificationManagerCompat.getEnabledListenerPackages(this).contains(packageName)
    }

    private fun openNotificationSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        startActivity(intent)
    }
}
