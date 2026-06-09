package com.shehabgo.smartfinancialtracker.ui

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.shehabgo.smartfinancialtracker.ui.screens.admin.UnparsedLogsScreen
import com.shehabgo.smartfinancialtracker.ui.screens.dashboard.UnifiedDashboardScreen
import com.shehabgo.smartfinancialtracker.ui.screens.ledger.SocialLedgerScreen
import com.shehabgo.smartfinancialtracker.ui.screens.onboarding.OnboardingPagerScreen
import com.shehabgo.smartfinancialtracker.ui.screens.splash.SplashScreen

@Composable
fun AppNavigation(
    navController: NavHostController = rememberNavController(),
    startDestination: String = "splash"
) {
    val context = LocalContext.current
    val prefs = context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
    val isOnboardingDone = prefs.getBoolean("onboarding_done", false)

    NavHost(
        navController = navController,
        startDestination = startDestination
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
                },
                onNavigateToAdmin = {
                    navController.navigate("unparsed_logs")
                }
            )
        }

        composable("social_ledger") {
            SocialLedgerScreen(
                onNavigateToDashboard = {
                    navController.navigate("dashboard") {
                        popUpTo("dashboard") { inclusive = true }
                    }
                },
                onNavigateToAdmin = {
                    navController.navigate("unparsed_logs")
                }
            )
        }

        composable("unparsed_logs") {
            UnparsedLogsScreen(
                onNavigateToDashboard = {
                    navController.navigate("dashboard") {
                        popUpTo("dashboard") { inclusive = true }
                    }
                },
                onNavigateToLedger = {
                    navController.navigate("social_ledger")
                }
            )
        }
    }
}
