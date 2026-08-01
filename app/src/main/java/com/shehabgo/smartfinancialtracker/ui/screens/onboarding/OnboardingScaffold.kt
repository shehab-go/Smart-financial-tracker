package com.shehabgo.smartfinancialtracker.ui.screens.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowForward
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.shehabgo.smartfinancialtracker.ui.theme.AppColors
import com.shehabgo.smartfinancialtracker.ui.theme.AppShapes
import com.shehabgo.smartfinancialtracker.ui.theme.AppSpacing
import com.shehabgo.smartfinancialtracker.ui.theme.AppElevation

@Composable
fun OnboardingScaffold(
    step: Int,
    totalSteps: Int = 6,
    buttonText: String,
    isButtonEnabled: Boolean = true,
    onButtonClick: () -> Unit,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.Background)
            .padding(vertical = AppSpacing.xxl),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Top Bar
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = AppSpacing.ScreenH),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text  = "المتتبع المالي الذكي",
                style = MaterialTheme.typography.headlineMedium.copy(
                    fontSize   = 20.sp,
                    fontWeight = FontWeight.Bold
                ),
                color = AppColors.Primary
            )
            Row(
                verticalAlignment     = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(AppSpacing.sm)
            ) {
                for (i in 1..totalSteps) {
                    val isActive = i == step
                    Box(
                        modifier = Modifier
                            .height(6.dp)
                            .width(if (isActive) 24.dp else 12.dp)
                            .background(
                                if (isActive) AppColors.Primary else AppColors.BorderStrong,
                                AppShapes.ButtonPill
                            )
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Custom Content
        Column(
            modifier = Modifier.weight(1f).fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            content()
        }

        Spacer(modifier = Modifier.height(24.dp))



        // Primary Action
        Button(
            onClick  = onButtonClick,
            enabled  = isButtonEnabled,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = AppSpacing.ScreenH)
                .height(AppSpacing.ButtonHeightLg)
                .shadow(
                    elevation  = if (isButtonEnabled) AppElevation.lg else AppElevation.none,
                    shape      = AppShapes.Button,
                    spotColor  = AppColors.Primary.copy(alpha = 0.3f)
                ),
            shape  = AppShapes.Button,
            colors = ButtonDefaults.buttonColors(
                containerColor         = AppColors.Primary,
                contentColor           = AppColors.OnPrimary,
                disabledContainerColor = AppColors.Border,
                disabledContentColor   = AppColors.TextHint
            )
        ) {
            Row(
                verticalAlignment     = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center
            ) {
                Text(
                    text  = buttonText,
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontWeight = FontWeight.Bold,
                        fontSize   = 18.sp
                    )
                )
                Spacer(modifier = Modifier.width(AppSpacing.base))
                Icon(
                    imageVector = Icons.AutoMirrored.Rounded.ArrowForward,
                    contentDescription = null,
                    modifier = Modifier.size(AppSpacing.Icon)
                )
            }
        }

        Spacer(modifier = Modifier.height(AppSpacing.base))
    }
}
