package com.shehabgo.smartfinancialtracker.ui

import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.text.font.FontWeight
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.shehabgo.smartfinancialtracker.ui.screens.admin.UnparsedLogsScreen
import com.shehabgo.smartfinancialtracker.ui.screens.dashboard.UnifiedDashboardScreen
import com.shehabgo.smartfinancialtracker.ui.screens.ledger.SocialLedgerScreen
import com.shehabgo.smartfinancialtracker.ui.screens.onboarding.OnboardingPagerScreen
import com.shehabgo.smartfinancialtracker.ui.screens.splash.SplashScreen
import com.shehabgo.smartfinancialtracker.ui.theme.AppColors
import com.shehabgo.smartfinancialtracker.ui.theme.AppSpacing
import com.shehabgo.smartfinancialtracker.ui.theme.AppShapes
import com.shehabgo.smartfinancialtracker.ui.theme.AppElevation

@Composable
fun AppNavigation(
    navController: NavHostController = rememberNavController(),
    startDestination: String = "splash"
) {
    val context = LocalContext.current
    val prefs = context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
    val isOnboardingDone = prefs.getBoolean("onboarding_done", false)

    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    // Check if bottom bar should be visible (only inside logged-in dashboard/ledger screens)
    val showBottomBar = currentRoute in listOf("dashboard", "wallets", "social_ledger")

    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFFF9FBFC))
        ) {
            // الشاشة محتواها يملأ الشاشة بالكامل للسماح بالتمرير خلف البار العائم
            NavHost(
                navController = navController,
                startDestination = startDestination,
                modifier = Modifier.fillMaxSize()
            ) {
                composable("splash") {
                    SplashScreen(
                        isOnboardingDone = isOnboardingDone,
                        onNavigate = { destination ->
                            navController.navigate(destination) {
                                popUpTo("splash") { inclusive = true }
                            }
                        }
                    )
                }

                composable("onboarding_pager") {
                    OnboardingPagerScreen(
                        onFinishOnboarding = {
                            navController.navigate("dashboard") {
                                popUpTo("onboarding_pager") { inclusive = true }
                            }
                        }
                    )
                }

                composable("dashboard") {
                    UnifiedDashboardScreen(
                        onNavigateToLedger = {
                            navController.navigate("social_ledger")
                        }
                    )
                }

                composable("social_ledger") {
                    SocialLedgerScreen(
                        onNavigateToDashboard = {
                            navController.navigate("dashboard")
                        }
                    )
                }

                composable("wallets") {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text("شاشة المحافظ قريباً", color = AppColors.TextPrimary, fontSize = 20.sp)
                    }
                }
            }

            // البار السفلي يطفو كطبقة فوق الواجهة (Overlay) مع خلفية شفافة حوله
            if (showBottomBar) {
                Box(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .fillMaxWidth()
                ) {
                    PersistentBottomNavigationBar(
                        currentRoute = currentRoute ?: "dashboard",
                        onNavigate = { route ->
                            if (currentRoute != route) {
                                navController.navigate(route) {
                                    popUpTo("dashboard") {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }
                        }
                    )
                }
            }
        }
    }
}

@Composable
fun PersistentBottomNavigationBar(
    currentRoute: String,
    onNavigate: (String) -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .navigationBarsPadding()
            .padding(horizontal = 24.dp, vertical = 16.dp) // الهوامش حول البار العائم لتكون شفافة بالكامل
            .shadow(AppElevation.lg, RoundedCornerShape(24.dp), spotColor = Color.Black.copy(alpha = 0.05f))
            .background(AppColors.Surface.copy(alpha = 0.95f), RoundedCornerShape(24.dp))
            .border(1.dp, AppColors.Border, RoundedCornerShape(24.dp))
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 6.dp)
                .height(60.dp),
            horizontalArrangement = Arrangement.SpaceAround,
            verticalAlignment = Alignment.CenterVertically
        ) {
            PersistentBottomNavItem(
                icon = Icons.Rounded.GridView,
                label = "الرئيسية",
                isSelected = currentRoute == "dashboard",
                onClick = { onNavigate("dashboard") }
            )
            PersistentBottomNavItem(
                icon = Icons.Rounded.AccountBalanceWallet,
                label = "المحافظ",
                isSelected = currentRoute == "wallets",
                onClick = { onNavigate("wallets") }
            )
            PersistentBottomNavItem(
                icon = Icons.Rounded.AccountBalance,
                label = "السجل",
                isSelected = currentRoute == "social_ledger",
                onClick = { onNavigate("social_ledger") }
            )
        }
    }
}

@Composable
fun PersistentBottomNavItem(
    icon: ImageVector,
    label: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val contentColor = if (isSelected) AppColors.Primary else AppColors.TextSecondary
    val bgColor = if (isSelected) AppColors.PrimaryAlpha08 else Color.Transparent

    Column(
        modifier = Modifier
            .clip(RoundedCornerShape(20.dp))
            .background(bgColor)
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 6.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            tint = contentColor,
            modifier = Modifier.size(22.dp)
        )
        Spacer(modifier = Modifier.height(2.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
            color = contentColor,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
        )
    }
}
