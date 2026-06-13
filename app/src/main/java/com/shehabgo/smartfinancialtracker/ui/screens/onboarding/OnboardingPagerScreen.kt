package com.shehabgo.smartfinancialtracker.ui.screens.onboarding

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.layout.padding
import androidx.compose.ui.graphics.graphicsLayer
import kotlin.math.absoluteValue
import com.shehabgo.smartfinancialtracker.ui.screens.categories.CategoriesCustomizationScreen
import com.shehabgo.smartfinancialtracker.ui.screens.wallets.WalletsSetupScreen
import kotlinx.coroutines.launch

import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.provider.Settings
import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalContext
import androidx.core.app.NotificationManagerCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LifecycleEventEffect

@Composable
fun OnboardingPagerScreen(
    onFinishOnboarding: () -> Unit
) {
    val pagerState = rememberPagerState(pageCount = { 6 })
    val coroutineScope = rememberCoroutineScope()
    val context = LocalContext.current

    var hasNotificationPermission by remember { mutableStateOf(false) }
    var hasBatteryOptimizationExemption by remember { mutableStateOf(false) }
    var isJeebSelected by remember { mutableStateOf(false) }

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

    LaunchedEffect(hasNotificationPermission) {
        if (hasNotificationPermission && pagerState.currentPage == 2) {
            coroutineScope.launch { pagerState.animateScrollToPage(3) }
        }
    }

    LaunchedEffect(hasBatteryOptimizationExemption) {
        if (hasBatteryOptimizationExemption && pagerState.currentPage == 3) {
            coroutineScope.launch { pagerState.animateScrollToPage(4) }
        }
    }

    val buttonText = when (pagerState.currentPage) {
        0 -> "ابدأ الرحلة المالية الآمنة"
        1 -> "موافق، استمر"
        2 -> "التالي"
        3 -> "التالي"
        4 -> "تأكيد واستمرار"
        else -> "حفظ التغييرات ومتابعة"
    }

    val onButtonClick: () -> Unit = {
        when (pagerState.currentPage) {
            0 -> coroutineScope.launch { pagerState.animateScrollToPage(1) }
            1 -> coroutineScope.launch { pagerState.animateScrollToPage(2) }
            2 -> {
                if (hasNotificationPermission) {
                    coroutineScope.launch { pagerState.animateScrollToPage(3) }
                } else {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    context.startActivity(intent)
                }
            }
            3 -> {
                if (hasBatteryOptimizationExemption) {
                    coroutineScope.launch { pagerState.animateScrollToPage(4) }
                } else {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = android.net.Uri.parse("package:${context.packageName}")
                    }
                    context.startActivity(intent)
                }
            }
            4 -> coroutineScope.launch { pagerState.animateScrollToPage(5) }
            else -> {
                // حفظ إتمام الـ Onboarding
                context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
                    .edit()
                    .putBoolean("onboarding_done", true)
                    .apply()
                onFinishOnboarding()
            }
        }
    }

    val isScrollEnabled = when (pagerState.currentPage) {
        2 -> hasNotificationPermission
        3 -> hasBatteryOptimizationExemption
        4 -> isJeebSelected
        else -> true
    }

    OnboardingScaffold(
        step = pagerState.currentPage + 1,
        buttonText = buttonText,
        isButtonEnabled = isScrollEnabled,
        onButtonClick = onButtonClick
    ) {
        HorizontalPager(
            state = pagerState,
            modifier = Modifier.fillMaxSize(),
            pageSpacing = 24.dp,
            userScrollEnabled = isScrollEnabled
        ) { page ->
            val pageOffset = (
                (pagerState.currentPage - page) + pagerState.currentPageOffsetFraction
            ).absoluteValue
            
            val scale = 1f - (pageOffset * 0.15f).coerceIn(0f, 0.15f)
            val alpha = 1f - (pageOffset * 0.5f).coerceIn(0f, 0.5f)

            androidx.compose.foundation.layout.Box(
                modifier = Modifier
                    .fillMaxSize()
                    .graphicsLayer {
                        scaleX = scale
                        scaleY = scale
                        this.alpha = alpha
                    }
                    .padding(horizontal = 24.dp)
            ) {
                when (page) {
                    0 -> WelcomeScreen()
                    1 -> PrivacyPromiseScreen()
                    2 -> PermissionFlowScreen(
                        hasPermission = hasNotificationPermission,
                        onOpenSettings = {
                            val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                            context.startActivity(intent)
                        }
                    )
                    3 -> BatteryOptimizationScreen(
                        hasPermission = hasBatteryOptimizationExemption,
                        onOpenSettings = {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = android.net.Uri.parse("package:${context.packageName}")
                            }
                            context.startActivity(intent)
                        }
                    )
                    4 -> WalletsSetupScreen(
                        onJeebSelected = { selected -> isJeebSelected = selected }
                    )
                    5 -> CategoriesCustomizationScreen()
                }
            }
        }
    }
}
