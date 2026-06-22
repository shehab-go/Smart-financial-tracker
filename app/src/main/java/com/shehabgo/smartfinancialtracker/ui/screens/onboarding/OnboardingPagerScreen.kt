package com.shehabgo.smartfinancialtracker.ui.screens.onboarding

import android.content.Context
import android.os.PowerManager
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.core.app.NotificationManagerCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LifecycleEventEffect
import kotlinx.coroutines.launch

@Composable
fun OnboardingPagerScreen(
    onFinishOnboarding: () -> Unit
) {
    val pagerState = rememberPagerState(pageCount = { 3 })
    val coroutineScope = rememberCoroutineScope()
    val context = LocalContext.current

    var hasNotificationPermission by remember { mutableStateOf(false) }
    var hasBatteryOptimizationExemption by remember { mutableStateOf(false) }

    fun checkPermissions() {
        hasNotificationPermission = NotificationManagerCompat.getEnabledListenerPackages(context).contains(context.packageName)
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        hasBatteryOptimizationExemption = powerManager.isIgnoringBatteryOptimizations(context.packageName)
    }

    LaunchedEffect(Unit) {
        checkPermissions()
    }

    LifecycleEventEffect(Lifecycle.Event.ON_RESUME) {
        checkPermissions()
    }

    // Auto-scroll when permission is granted
    LaunchedEffect(hasNotificationPermission) {
        if (hasNotificationPermission && pagerState.currentPage == 1) {
            coroutineScope.launch { pagerState.animateScrollToPage(2) }
        }
    }

    val navigateNext: () -> Unit = {
        if (pagerState.currentPage < 2) {
            coroutineScope.launch { pagerState.animateScrollToPage(pagerState.currentPage + 1) }
        } else {
            // End of Onboarding
            context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
                .edit()
                .putBoolean("onboarding_done", true)
                .apply()
            onFinishOnboarding()
        }
    }

    Box(modifier = Modifier.fillMaxSize().background(Color(0xFFF9FBFC))) {
        HorizontalPager(
            state = pagerState,
            modifier = Modifier.fillMaxSize(),
            userScrollEnabled = false // Ensure user reads and clicks the buttons
        ) { page ->
            when (page) {
                0 -> WelcomeAndPrivacyScreen(onNext = navigateNext)
                1 -> PermissionFlowScreen(
                    hasPermission = hasNotificationPermission,
                    onOpenSettings = {
                        val intent = android.content.Intent(android.provider.Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        context.startActivity(intent)
                    }
                )
                2 -> BatteryOptimizationScreen(
                    hasPermission = hasBatteryOptimizationExemption,
                    onNext = navigateNext
                )
            }
        }
    }
}
