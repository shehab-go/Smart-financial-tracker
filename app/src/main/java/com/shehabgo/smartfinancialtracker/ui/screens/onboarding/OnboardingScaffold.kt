package com.shehabgo.smartfinancialtracker.ui.screens.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowForward
import androidx.compose.material.icons.rounded.Security
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

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
            .background(Color(0xFFF6FAFF))
            .padding(vertical = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Top Bar
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "المتتبع المالي الذكي",
                    style = MaterialTheme.typography.headlineMedium.copy(fontSize = 20.sp, fontWeight = FontWeight.Bold),
                    color = Color(0xFFBD001B) // primary
                )

            }
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                for (i in 1..totalSteps) {
                    val isActive = i == step
                    val width = if (isActive) 24.dp else 12.dp
                    val color = if (isActive) Color(0xFFBD001B) else Color(0xFFD2DBE4)
                    Box(
                        modifier = Modifier
                            .height(6.dp)
                            .width(width)
                            .background(color, RoundedCornerShape(3.dp))
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
            onClick = onButtonClick,
            enabled = isButtonEnabled,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .height(56.dp)
                .shadow(if (isButtonEnabled) 12.dp else 0.dp, RoundedCornerShape(12.dp), spotColor = Color(0xFFBD001B).copy(alpha = 0.3f)),
            shape = RoundedCornerShape(12.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = Color(0xFFBD001B),
                contentColor = Color.White,
                disabledContainerColor = Color(0xFFE0E9F2),
                disabledContentColor = Color(0xFFA0AAB5)
            )
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center
            ) {
                Text(
                    text = buttonText,
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold, fontSize = 18.sp)
                )
                Spacer(modifier = Modifier.width(16.dp))
                Icon(
                    imageVector = Icons.AutoMirrored.Rounded.ArrowForward,
                    contentDescription = null,
                    modifier = Modifier.size(24.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))
    }
}
